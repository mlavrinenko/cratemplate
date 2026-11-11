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
cargo crap --lcov target/coverage/lcov.info --workspace \
    --exclude '**/main.rs' --exclude 'tests/**' --exclude '**/*_tests.rs' \
    --format json --sort file --output .config/crap-baseline.json
