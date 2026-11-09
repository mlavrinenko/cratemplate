#!/usr/bin/env bash
# .just/scripts/eject.sh PCT ROOT: eject inline tests from Rust files nearing
# the linecop limit, so they stay under it without losing the inline-test
# workflow. Runs as part of `just fix-check`.
#
# linecop's --baseline exit is informational: it exits 1 merely to FLAG files
# at or over the threshold, not because it failed to run, so the script must
# not die on the very finding it exists to fix. Since linecop 0.5, exit 2 means
# a broken run (bad config, missing path), which must still fail. The scan is
# narrowed to Rust: ejectest moves inline RUST test modules, and a near-limit
# Markdown file has nothing to move.
set -eo pipefail

pct=${1:?usage: eject.sh PCT ROOT}
root=${2:?usage: eject.sh PCT ROOT}

rc=0
paths=$(linecop --baseline "$pct" --format paths) || rc=$?
[ "$rc" -le 1 ] || exit "$rc"

rust_paths=$(printf '%s\n' "$paths" | grep '\.rs$' || true)
if [ -n "$rust_paths" ]; then
    printf '%s\n' "$rust_paths" | ejectest apply "$root" --files-from - --lenient
fi
