#!/usr/bin/env bash
# .just/scripts/wt-tasks.sh <range>: the worktrunk `pre-merge` hook's task check
# (.config/wt.toml). `mt check --commits` refuses a branch that names a task
# still `wip` at its tip, so it cannot land without its `mt done` flip.
#
# MindTape is optional here: a crate without `.mindtape/` has no tasks to
# check, so this is a no-op. A crate that does track tasks must have `mt` on
# PATH; a missing tool is a broken dev shell, not a reason to skip the check.
set -euo pipefail

range=${1:?usage: wt-tasks.sh <range>}

[ -d .mindtape ] || exit 0
command -v mt >/dev/null || {
    echo "wt-tasks: .mindtape/ exists but mt is not on PATH" >&2
    exit 1
}
mt check --commits "$range"
