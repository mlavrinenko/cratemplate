#!/usr/bin/env bash
# .just/scripts/check-tasks.sh: the `just tools::check-tasks` gate.
#
# Task tracking is optional: a project generated with `task_tracker = none`
# has no `.mindtape/` and ships no `mt`, so this is a no-op there. A project
# that does track tasks must have `mt` on PATH; a missing tool is a broken dev
# shell, not a reason to skip the gate.
set -eo pipefail

[ -d .mindtape ] || exit 0
command -v mt >/dev/null || {
    echo "check-tasks: .mindtape/ exists but mt is not on PATH" >&2
    exit 1
}

mt check -q
mt fix --check
