#!/usr/bin/env bash
# .just/scripts/lcov-stale-reason.sh [ROOT...]: is target/coverage/lcov.info
# usable against the tree in front of it? Empty stdout means yes; any other
# line names why not. It ALWAYS exits 0: the exit status is not the channel, so
# a caller that treats a reason as ordinary does not also get just's own
# `error: Recipe ... failed` line.
#
# The roots are what `cover` measures plus what exercises it: src is rendered,
# tests is the instrument, so a changed test moves the coverage of files it
# never edited. A workspace under crates/ holds every member's src and tests.
# A lib starts with no tests/ and a clone drops empty directories, so a root is
# searched only where it exists. `just crap` and wt-carry-lcov.sh share this
# one test rather than each carrying a copy that could disagree.
set -eo pipefail

lcov=target/coverage/lcov.info
if [ ! -f "$lcov" ]; then
    echo "$lcov is missing"
    exit 0
fi
dirs=()
for d in "$@"; do [ ! -d "$d" ] || dirs+=("$d"); done
newer=$(find "${dirs[@]}" -name '*.rs' -newer "$lcov" -print -quit)
if [ -n "$newer" ]; then
    echo "$lcov predates $newer"
fi
