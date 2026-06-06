# Contributing to {{project-name}}

## Code Style

All clippy lints are set to `deny` level — the project will not compile with violations.

Key restrictions:
- No `unwrap()` — use `?` operator or `anyhow`/`thiserror` error handling
- No `todo!()`, `unimplemented!()`, `unreachable!()` — handle all cases
- No `unsafe` code
- No wildcard imports (`use foo::*`)
- No single-character variable names (minimum 2 characters)
- Functions: max 70 lines, max 5 arguments, max cognitive complexity 20

## Error Handling

- Use `anyhow::Result` for application-level code (binaries, CLI)
- Use `thiserror::Error` for library error types that callers will match on
- Propagate errors with `?` — never `unwrap()` or `expect()`

## Project Structure

Keep `main.rs` as a thin entry point — argument parsing, logger init, and a call into
library code. All logic belongs in `lib.rs` (and its modules). `main.rs` is excluded from
coverage, so anything there is untested by default.

## Code Coverage

Minimum 70% coverage enforced via `cargo-tarpaulin`. Run `just cover` to check.
`main.rs` is excluded — keep it thin and move testable logic to `lib.rs`.

## CRAP Gate

`just crap` scores each function by the Change Risk Anti-Patterns metric
(cyclomatic complexity weighted by test coverage) and fails above 30. A global
coverage threshold can stay green while one branchy, untested function rots;
CRAP catches that. It reads `target/coverage/lcov.info`, so run `just cover`
first (CI and `just validate` chain them). Fix a flagged function by adding
tests or reducing its branching. Tune the threshold per repo via `--threshold`
or a `.cargo-crap.toml`.

## File Size Limits

- Rust files: 500 lines max
- Markdown files: 200 lines max

When a file exceeds the limit, split it into modules or separate documents.

## Dependency Drift

[outdatty.yaml](outdatty.yaml) declares groups that couple `source` files to the
`dependents` that must stay in sync with them — for example, CLI code to the docs
that describe it. `just check` runs `outdatty check`, which fails when a source
changed but its dependents were not re-confirmed.

After editing a source, review the listed dependents, update them as needed, then
run `just outdatty-update` to record the new state into `outdatty.lock` and commit
it. Add or adjust groups whenever you introduce files that must move together.

## Submitting Changes

1. Run `just check` before submitting — it runs clippy, tests, file size, and drift checks
2. Run `just fmt` to format code
3. Ensure `just cover` meets the 70% threshold
