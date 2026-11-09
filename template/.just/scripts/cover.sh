#!/usr/bin/env bash
# .just/scripts/cover.sh IGNORE_REGEX: the `just cover` gate.
#
# Instrument the SAME runner as `just test` (`cargo llvm-cov nextest`):
# process-per-test and shared-process are different execution models, so a gate
# that tests one while coverage exercises the other can pass a test that fails
# under the other with nothing saying so. llvm-cov, unlike tarpaulin, merges
# the profraw of child processes, so subprocess-based CLI e2e tests actually
# attribute to the code they exercise. Instrument once (--no-report), then
# render both reports from that profdata; the output level is no flag here or
# in `test`, since .config/nextest.toml sets it once for both runners.
#
# `clean --workspace` first is not tidiness. The --no-report + separate report
# split does NOT discard earlier profraw, so a long-lived checkout merges
# coverage maps from binaries that no longer exist. Measured on a real project:
# a 106-line file scored as 357 instrumented lines at 21.65% -- the pre-split
# version, still counted weeks after it stopped existing -- and a workspace
# headline of 87.58% where the tree was actually 93.45%. It fails toward
# pessimism, so a gate with a floor never complains; what it does instead is
# make every fresh worktree disagree with the main checkout.
#
# Two floors, because one number hides the other. 70% on the workspace total
# keeps the headline honest; 60% on each production file stops a well-covered
# file from carrying an under-covered one. 60 is deliberately lenient, and a
# file is only judged once it has at least 5 uncovered lines: in a three-line
# file one missed line is wiring, not an untested unit. Test files are skipped
# for the same reason `just crap` skips them -- llvm-cov instruments the suite,
# not the code under test.
#
# The per-file floor reads the lcov records rather than
# `cargo llvm-cov report --fail-under-file-lines`: that flag applies to every
# file, including the tiny ones the uncovered-lines guard exists to spare.
set -eo pipefail

ignore=${1:?usage: cover.sh IGNORE_REGEX}
# tests/ and every ejected `*_tests.rs` are the instrument, not the subject.
test_re='(^|/)tests/|(^|/)[^/]*_tests\.rs$'
mkdir -p target/coverage
cargo llvm-cov clean --workspace
cargo llvm-cov nextest --workspace --no-report --cargo-quiet
cargo llvm-cov report --ignore-filename-regex "$ignore" \
    --lcov --output-path target/coverage/lcov.info
# Only the header and TOTAL: the per-file table is one row per file that a
# green gate run never reads, and `just crap` reads the lcov above. pipefail
# keeps --fail-under-lines' exit status.
cargo llvm-cov report --ignore-filename-regex "$ignore" --fail-under-lines 70 |
    sed -n '1p;$p'

# The per-file floor: a production file fails below 60% line coverage when it
# also has 5 or more uncovered lines. Read from each lcov record's line totals,
# not from `cargo llvm-cov report --json`, whose summary counts a line once per
# compiled copy of the crate, so a file the suite covers whole reads as 75%.
# The patterns go in through the environment: awk -v would eat their
# backslashes.
floor=60
min_uncovered=5
below="$(ignore="$ignore" test_re="$test_re" awk -v floor="$floor" \
    -v min="$min_uncovered" '
    BEGIN {
        ignore = ENVIRON["ignore"]
        test_re = ENVIRON["test_re"]
        root = ENVIRON["PWD"] "/"
    }
    /^SF:/ { f = substr($0, 4) }
    /^LF:/ { lf = substr($0, 4) + 0 }
    /^LH:/ { lh = substr($0, 4) + 0 }
    /^end_of_record/ {
        if (index(f, root) == 1)
            f = substr(f, length(root) + 1)
        if (f !~ ignore && f !~ test_re && lf > 0 && lf - lh >= min \
            && lh * 100 / lf < floor)
            printf "  %s  %.1f%%  %d of %d lines unreached\n", \
                f, lh * 100 / lf, lf - lh, lf
        f = ""; lf = 0; lh = 0
    }
' target/coverage/lcov.info | sort)"
if [ -n "$below" ]; then
    echo "cover: $(printf '%s\n' "$below" | wc -l | tr -d ' ') file(s) below the per-file floor of ${floor}% (${min_uncovered}+ uncovered lines):"
    printf '%s\n' "$below"
    echo "fix: add a test, or add the file to cover_ignore in the Justfile with the reason beside it"
    exit 1
fi
