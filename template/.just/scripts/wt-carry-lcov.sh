#!/usr/bin/env bash
# .just/scripts/wt-carry-lcov.sh <primary-checkout>: the worktrunk `pre-remove` hook's
# lcov carry (.config/wt.toml). Runs from the root of the worktree about to be
# removed, which is where worktrunk runs that hook.
#
# `just cover` writes target/coverage/lcov.info and `just crap` scores against
# it. The file is gitignored, so after a fast-forward the primary checkout holds
# none, or one from before the merge, and its next `just crap` would pay a
# second instrumented build for numbers the worktree already has.
#
# Never fatal: the merge has landed, and a failed copy does not un-land it. Every
# way out exits 0, and a copy that fails says so on stderr.
set -eo pipefail

primary=${1:?usage: wt-carry-lcov.sh <primary-checkout>}
lcov=target/coverage/lcov.info
here=$(git rev-parse --show-toplevel) || exit 0

[ "$here" != "$primary" ] || exit 0
# Only a landed merge carries: otherwise the lcov describes a tree the primary
# checkout does not hold. A primary that is no checkout answers nothing, which
# reads as not landed.
[ "$(git rev-parse HEAD)" = "$(git -C "$primary" rev-parse HEAD 2>/dev/null)" ] || exit 0
[ -f "$here/$lcov" ] || exit 0
# The primary's own lcov wins when it is newer.
if [ -f "$primary/$lcov" ] && [ ! "$here/$lcov" -nt "$primary/$lcov" ]; then
    exit 0
fi

# The copy gets a new mtime, so staleness is judged here, against the sources
# the lcov was written from, by the recipe `just crap` asks. The hook runs this
# script through `direnv exec .` for the dev shell's `just`; without it the
# answer is unanswered, which carries nothing.
#
# The recipe defers to .just/scripts/lcov-stale-reason.sh. The script's own
# scratch test (scripts/test-wt-carry-lcov.sh) copies only the Justfile and
# this hook, so when the helper is absent, repeat the same test here instead
# of reading "unanswered" and dropping a fresh report.
staleness() {
    local report=target/coverage/lcov.info
    if [ ! -f "$report" ]; then
        echo "$report is missing"
        return 0
    fi
    local roots=() d newer
    for d in src tests crates; do [ ! -d "$d" ] || roots+=("$d"); done
    if [ "${#roots[@]}" -eq 0 ]; then
        return 0
    fi
    newer=$(find "${roots[@]}" -name '*.rs' -newer "$report" -print -quit)
    if [ -n "$newer" ]; then
        echo "$report predates $newer"
    fi
}

stale=$(cd "$here" && just _lcov-stale-reason 2>/dev/null) \
    || stale=$(cd "$here" && staleness) \
    || stale=unanswered
[ -z "$stale" ] || exit 0

# llvm-cov writes absolute `SF:` paths, so they are rewritten to the primary
# checkout. The paths go in through the environment: awk -v would read a
# backslash in one as an escape.
if mkdir -p "$primary/target/coverage" \
    && FROM="SF:$here/" TO="SF:$primary/" awk '
        BEGIN { from = ENVIRON["FROM"]; to = ENVIRON["TO"] }
        index($0, from) == 1 { $0 = to substr($0, length(from) + 1) }
        { print }
    ' "$here/$lcov" >"$primary/$lcov.tmp" \
    && mv "$primary/$lcov.tmp" "$primary/$lcov"; then
    exit 0
fi
echo "wt-carry-lcov: could not carry $lcov to $primary" >&2
exit 0
