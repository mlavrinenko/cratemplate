#!/usr/bin/env bash
# .just/scripts/check.sh [STAGE]: the `just check` gate.
#
# Two batches, each run in parallel. The fast batch answers in seconds and
# catches the cheap failures; the build batch follows only when it is green.
# Every arm still runs as `mmz just <arm>`, so an arm whose inputs are unchanged
# is a silent cache hit. A green run prints one verdict; a red run prints only
# the failed arms' captured logs, so the failure is readable without the noise
# of the arms that passed. `just check cover` adds the slow coverage pair.
#
# The pre-commit hook, the worktrunk gate and CI all call `just check` with no
# argument; the stage exists for the opt-in coverage pair, not for a different
# default.
set -eo pipefail

stage=${1:-}
case "$stage" in
"" | cover) ;;
*)
    echo "usage: check.sh [cover]" >&2
    exit 2
    ;;
esac

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

run_batch() { # run_batch <name> <arm>...
    local name=$1
    shift
    local -a pids=()
    local -a logs=()
    local -a names=()
    local arm log failed=0 i
    for arm in "$@"; do
        log="$work/$name-${arm//[:\/]/_}.log"
        mmz just "$arm" >"$log" 2>&1 &
        pids+=("$!")
        logs+=("$log")
        names+=("$arm")
    done
    for i in "${!pids[@]}"; do
        if ! wait "${pids[$i]}"; then
            failed=1
            echo "just check: $name batch, ${names[$i]} failed" >&2
            cat "${logs[$i]}" >&2
        fi
    done
    # The outdatty bootstrap is a one-time green-run notice, not stream noise;
    # the captured log hides it, so surface just that line.
    if [ "$failed" -eq 0 ] && [ "$name" = build ]; then
        local notice
        notice=$(grep -h 'created outdatty.lock' "$work"/build-*.log || true)
        [ -z "$notice" ] || printf '%s\n' "$notice" >&2
    fi
    return "$failed"
}

run_one() { # run_one <label> <recipe>
    local label=$1
    local recipe=$2
    local log="$work/$label.log"
    if ! mmz just "$recipe" >"$log" 2>&1; then
        echo "just check: $label failed" >&2
        cat "$log" >&2
        return 1
    fi
}

fast_arms=(
    fmt-check
    machete
    check-file-size
    check-dry
    tools::nix-fmt-check
    tools::check-tasks
    docs-md-check
    lint::workflows
    lint::shellcheck
    lint::doc
)
build_arms=(clippy test outdatty-check)

run_batch fast "${fast_arms[@]}" || exit 1
run_batch build "${build_arms[@]}" || exit 1

if [ "$stage" = cover ]; then
    run_one cover cover || exit 1
    run_one crap crap || exit 1
fi

if [ "$stage" = cover ]; then
    echo "just check: all gates green (with cover and crap)"
else
    echo "just check: all gates green"
fi
