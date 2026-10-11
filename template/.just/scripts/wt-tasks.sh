#!/usr/bin/env bash
# .just/scripts/wt-tasks.sh <range>: the worktrunk `pre-merge` hook's task check
# (.config/wt.toml). `mt check --commits` refuses a branch that names a task
# still `wip` at its tip, so it cannot land without its `mt done` flip.
#
# MindTape is optional here: a crate without `.mindtape/` has no tasks to check,
# and the dev shell does not ship `mt`, so a crate that tracks tasks installs it
# itself. Either absence is a no-op; the second says so.
set -euo pipefail

range=${1:?usage: wt-tasks.sh <range>}

[ -d .mindtape ] || exit 0
if ! command -v mt >/dev/null; then
    echo "wt-tasks: .mindtape/ exists but mt is not on PATH, so the task check was skipped" >&2
    exit 0
fi
mt check --commits "$range"
