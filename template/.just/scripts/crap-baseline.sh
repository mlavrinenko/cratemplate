#!/usr/bin/env bash
# .just/scripts/crap-baseline.sh: rewrite the committed CRAP ratchet baseline.
#
# This is the only writer of .config/crap-baseline.json. `just crap` reads the
# file and fails when it is missing, so a baseline update is a deliberate
# commit, never a side effect of running the gate. Refuse a stale lcov for the
# same reason `just crap` does: scoring a tree the lcov never saw would write
# pessimistic 0%-coverage scores into the baseline and make the ratchet looser
# than the code it records. `just _lcov-stale-reason` is the shared test; its
# stdout is the reason and it always exits 0.
#
# The three excludes must match `just crap`: a function the gate never scores
# has no business in the baseline. `--sort file` keeps the entry order stable
# across score changes, so a later update touches only the entries that moved.
set -eo pipefail

reason=$(just _lcov-stale-reason)
if [ -n "$reason" ]; then
    echo "just tools::crap-baseline: $reason — run \`just cover\` first" >&2
    echo "  (the baseline must record the tree the lcov measured)" >&2
    exit 1
fi
out=.config/crap-baseline.json
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cargo crap --lcov target/coverage/lcov.info --workspace \
    --exclude '**/main.rs' --exclude 'tests/**' --exclude '**/*_tests.rs' \
    --format json --sort file --output "$tmp"
# cargo-crap writes absolute paths. The baseline is committed and shared by
# every checkout, so record repo-relative paths instead: a machine root would
# make suffix matching pair a function with any same-named file whose path
# happens to share the tail (every workspace member's src/lib.rs does).
root=$(pwd -P)/
jq --arg root "$root" '.entries |= map(.file |= ltrimstr($root))' \
    "$tmp" >"$out"
