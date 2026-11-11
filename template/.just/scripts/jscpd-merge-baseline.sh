#!/usr/bin/env bash
# .just/scripts/jscpd-merge-baseline.sh BASE OURS THEIRS: the `jscpd` merge
# driver (see .gitattributes). A lane that accepts a clone and a lane that
# accepts another both add a key to the same `fingerprints` object, so git
# alone conflicts on the second land. jscpd's built-in `--merge-baseline`
# unions the three inputs and writes the result to OURS.
#
# Prefer the jscpd already on PATH: `just land` and the project's dev shell
# both provide it. Fall back to the project's dev shell through direnv for a
# merge started outside it; if neither works, exit non-zero and let git report
# the failed driver rather than leave a half-merged baseline.
set -eo pipefail

if command -v jscpd >/dev/null 2>&1; then
    exec jscpd --merge-baseline "$@"
fi
exec direnv exec . jscpd --merge-baseline "$@"
