#!/usr/bin/env bash
# .just/scripts/outdatty-check.sh: the `just outdatty-check` gate.
#
# A generated project ships no outdatty.lock — the hashes cover rendered files,
# so a static one cannot be shipped. Bootstrap the first lock here and name it
# for review; an existing lock is never refreshed, so real drift still fails.
set -eo pipefail

if [ ! -f outdatty.lock ]; then
    outdatty update --format quiet
    echo "outdatty-check: created outdatty.lock; review and commit it" >&2
fi

outdatty check
