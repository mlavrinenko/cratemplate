#!/usr/bin/env bash
# .just/scripts/test.sh [ARGS...]: the `just test` gate.
#
# cargo-nextest runs one process per test, so a panicking or hanging test is
# isolated. The output level lives in .config/nextest.toml, once for this gate
# and `cover`; `--cargo-quiet` drops the hundreds of `Compiling` lines a first
# build prints. nextest does not run doctests, so a second pass covers them: its
# per-member noise prints only when it fails, and a member that ran a doctest
# keeps its summary. ARGS reach both passes, so one substring filter works for
# both.
set -eo pipefail

cargo nextest run --workspace --cargo-quiet "$@"
out=$(cargo test --workspace --doc -q "$@" 2>&1) || { printf '%s\n' "$out"; exit 1; }
grep -E '^test result: ok\. [1-9]' <<<"$out" || true
