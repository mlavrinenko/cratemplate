#!/usr/bin/env bash
# scripts/test-wt-carry-lcov.sh <generated-crate>: `just validate` runs this in
# the dev shell of a generated crate. The crate's .just/scripts/wt-carry-lcov.sh
# is the worktrunk `pre-remove` hook that copies a worktree's coverage lcov to
# the primary checkout, so `just crap` there scores a landed merge without a
# second instrumented build. Each case builds a primary checkout and a worktree
# of it, holding the script and the crate's Justfile (its `_lcov-stale-reason`
# recipe judges staleness), runs the script from the worktree root as the hook
# does, and reads what reached the primary.
set -euo pipefail

crate=$(cd "${1:?usage: test-wt-carry-lcov.sh <generated-crate>}" && pwd)
script=.just/scripts/wt-carry-lcov.sh
lcov=target/coverage/lcov.info
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail() { echo "wt-carry-lcov: $1" >&2; exit 1; }

# A primary checkout on main and a worktree on feature at the same commit.
pair() {
    rm -rf "$tmp/case"
    primary="$tmp/case/repo"
    wt="$tmp/case/repo-feature"
    mkdir -p "$primary/.just/scripts" "$primary/src" "$primary/tests"
    cp "$crate/Justfile" "$primary/Justfile"
    cp "$crate/$script" "$primary/$script"
    echo 'pub fn a() {}' > "$primary/src/lib.rs"
    printf '#[test]\nfn a() {}\n' > "$primary/tests/a.rs"
    git -C "$primary" init -q -b main
    git -C "$primary" add -A
    git -C "$primary" -c user.name=t -c user.email=t@example.invalid -c commit.gpgsign=false commit -qm base
    git -C "$primary" worktree add -q -b feature "$wt"
}

# The worktree's lcov as `cargo llvm-cov` writes it, with absolute `SF:` paths
# into the worktree, after the sources.
instrument() {
    mkdir -p "$wt/target/coverage"
    printf 'TN:\nSF:%s/src/lib.rs\nDA:1,1\nend_of_record\n' "$wt" > "$wt/$lcov"
    touch -d '1 hour ago' "$wt/src/lib.rs" "$wt/tests/a.rs"
}

# Run as the `pre-remove` hook does: from the worktree root, the primary checkout
# as the argument. It must exit 0 whatever happens; stderr comes back.
carry() {
    # shellcheck disable=SC2069 # stderr is the output; stdout is dropped
    (cd "$wt" && env -u BASH_ENV bash "$script" "$1" 2>&1 >/dev/null) \
        || fail "$case_name: the script failed"
}

case_name="a landed merge carries the lcov with its paths rewritten"
pair; instrument; carry "$primary" >/dev/null
[ -f "$primary/$lcov" ] || fail "$case_name: the lcov did not reach the primary"
grep -qxF "SF:$primary/src/lib.rs" "$primary/$lcov" || fail "$case_name: SF path not rewritten"
! grep -qF "$wt" "$primary/$lcov" || fail "$case_name: a worktree path is left"

case_name="a branch that did not land carries nothing"
pair; instrument
echo 'pub fn b() {}' > "$wt/src/other.rs"
git -C "$wt" add -A
git -C "$wt" -c user.name=t -c user.email=t@example.invalid -c commit.gpgsign=false commit -qm work
carry "$primary" >/dev/null
[ ! -e "$primary/$lcov" ] || fail "$case_name: the lcov of an unlanded tree moved"

case_name="an lcov older than a source is not carried"
pair; instrument
touch -d '2 hours ago' "$wt/$lcov"
carry "$primary" >/dev/null
[ ! -e "$primary/$lcov" ] || fail "$case_name: a stale lcov was carried"

case_name="a newer lcov in the primary is kept"
pair; instrument
touch -d '10 minutes ago' "$wt/$lcov"
mkdir -p "$primary/target/coverage"
echo "primary's own" > "$primary/$lcov"
carry "$primary" >/dev/null
[ "$(cat "$primary/$lcov")" = "primary's own" ] || fail "$case_name: the primary's lcov was replaced"

case_name="a worktree without an lcov is a no-op"
pair
carry "$primary" >/dev/null
[ ! -e "$primary/$lcov" ] || fail "$case_name: an lcov appeared"

case_name="a failed carry says so and never fails the hook"
pair; instrument
# `target` is a file in the primary, so `target/coverage` cannot be made.
: > "$primary/target"
err=$(carry "$primary")
grep -q 'could not carry' <<<"$err" || fail "$case_name: no complaint on stderr: $err"

case_name="a primary that is no checkout is a no-op"
pair; instrument
carry "$tmp/no-such-checkout" >/dev/null
[ ! -e "$tmp/no-such-checkout" ] || fail "$case_name: the missing primary was created"

echo "wt-carry-lcov: 7 cases passed"
