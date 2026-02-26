# {{project-name}}

## Agent Rules

- Use `just` recipes instead of raw cargo commands (see `Justfile`)
- Use `-q` for cargo commands — only show errors/warnings
- After any code changes, run `just check` and fix all warnings
- If clippy suggests `--fix`, use `cargo clippy --fix --workspace --all-targets`

## Clippy Lints

All clippy lints are set to `deny` level — the project will not compile with violations.

Key restrictions to be aware of:
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

Minimum 70% coverage is enforced via `cargo-tarpaulin`. Run `just cover` to check.
`main.rs` is excluded — keep it thin and move testable logic to `lib.rs`.

## File Size Limits

- Rust files: 500 lines max
- Markdown files: 200 lines max

When a file exceeds the limit, split it into modules or separate documents.
