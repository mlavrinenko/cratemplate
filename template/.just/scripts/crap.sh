#!/usr/bin/env bash
# .just/scripts/crap.sh: the `just crap` gate.
#
# REFUSES a stale lcov rather than scoring it: cargo-crap's --missing
# pessimistic grades a function with no coverage record as 0%, so every file
# added since the last `just cover` reads as completely untested and arrives as
# a plausible finding. `just _lcov-stale-reason` is the test; its stdout is the
# reason and it always exits 0. Deliberately not a `cover` dependency: that
# recipe is minutes of instrumented CPU and this gate is seconds, so re-reading
# an existing report has to stay possible.
#
# The three excludes are one rule in three disguises: llvm-cov instruments the
# code under test, not the suite, so `tests/**` and every ejected `*_tests.rs`
# have no record to score. `**/main.rs` covers every workspace member's thin
# entry point (harmless for libs, where the file does not exist).
#
# `--format github` is what makes a green run quiet and a red one legible: it
# emits one `::warning` per function above `--threshold` (naming file, line,
# function and score) and prints nothing when nothing is wrong.
#
# The committed baseline is the ratchet. `--fail-above` still catches a new
# function over 30, while `--fail-regression` stops an already-scored one from
# getting worse even while it stays under the absolute floor. The baseline is
# REQUIRED: a missing file is a hard failure, never a silent fallback to the
# absolute threshold, because that fallback would forgive every regression.
# Only `just tools::crap-baseline` writes it, deliberately; this gate never does.
set -eo pipefail

reason=$(just _lcov-stale-reason)
if [ -n "$reason" ]; then
    echo "just crap: $reason — run \`just cover\` first" >&2
    echo "  (a source the lcov never saw scores as 0% covered, not as unknown)" >&2
    exit 1
fi
baseline=.config/crap-baseline.json
if [ ! -f "$baseline" ]; then
    echo "just crap: $baseline is missing — run \`just tools::crap-baseline\` after \`just cover\`" >&2
    exit 1
fi
cargo crap --lcov target/coverage/lcov.info --workspace \
    --exclude '**/main.rs' --exclude 'tests/**' --exclude '**/*_tests.rs' \
    --format github --threshold 30 --fail-above \
    --baseline "$baseline" --fail-regression --sort file
