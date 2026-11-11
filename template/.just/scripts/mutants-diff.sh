#!/usr/bin/env bash
# .just/scripts/mutants-diff.sh [ARGS...]: pre-PR mutation check, the daily
# driver. Sweeps only mutants touched by this branch's diff against main, so it
# needs no state file and covers new files for free (every line of a new file
# is "touched"). A surviving MISSED mutant is a real assertion gap: a line
# covered but not pinned.
#
# CARGO_MUTANTS_JOBS defaults to 3 and is overridden from the environment
# (`CARGO_MUTANTS_JOBS=8 just mutants-diff`). The default lives here, attached
# to the one command that reads it instead of the recipe's whole shell.
set -eo pipefail

diff_file=$(mktemp)
trap 'rm -f "$diff_file"' EXIT
git diff "$(git merge-base main HEAD)" > "$diff_file"
CARGO_MUTANTS_JOBS="${CARGO_MUTANTS_JOBS:-3}" \
    cargo mutants --in-diff "$diff_file" "$@"
