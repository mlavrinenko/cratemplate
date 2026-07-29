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

{% if crate_kind == "bin" -%}
- Use `anyhow::Result` for application-level code (binaries, CLI)
{% endif -%}
- Use `thiserror::Error` for library error types that callers will match on
- Propagate errors with `?` — never `unwrap()` or `expect()`

## Project Structure
{%- if crate_kind == "bin" %}

Keep `main.rs` as a thin entry point — argument parsing, logger init, and a call into
library code. All logic belongs in `lib.rs` (and its modules). `main.rs` is excluded from
coverage, so anything there is untested by default.
{%- endif %}
{%- if crate_kind == "lib" %}

All logic belongs in `lib.rs` (and its modules). Keep the public API surface small and
documented; anything callers depend on should have a doc comment with a `# Errors` section
where relevant.
{%- endif %}

## Testing

- Unit tests live inline in a `#[cfg(test)] mod tests` block next to the code they exercise.
{% if crate_kind == "bin" -%}
- CLI and integration tests live in `tests/` and drive the built binary with
  [`assert_cmd`](https://docs.rs/assert_cmd) + [`predicates`](https://docs.rs/predicates)
  (see `tests/cli.rs`).
{% endif -%}
{% if crate_kind == "lib" -%}
- Integration tests that exercise the public API across modules live in `tests/`.
{% endif -%}
- Run the full suite with `just test`.
- As a file approaches the linecop limit, `just fix-check` ejects its inline
  `#[cfg(test)]` module into a sibling `_tests.rs` file via
  [ejectest](https://github.com/mlavrinenko/ejectest), driven by `linecop --baseline`.
  This keeps source files under the limit without losing the inline-test workflow.

## Code Coverage

Minimum 70% line coverage enforced via `cargo-llvm-cov`. Run `just cover` to check.
llvm-cov merges the profraw of child processes, so subprocess-based e2e tests
attribute correctly — unlike tarpaulin, which misses them.
{%- if crate_kind == "bin" %}
`main.rs` is excluded from coverage — keep it thin and move testable logic to `lib.rs`.
{%- endif %}

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

## Memoized Gates

Every arm of `just check` runs as `just mmz <subgate>`, which is
`mmz just <subgate>`. [mmz](https://github.com/mlavrinenko/mmz) hashes the rule's
declared inputs and skips the command when they are byte-for-byte identical to
the last run that *succeeded*, so a no-op `just check` re-run costs nothing and a
one-file change re-runs only the arms that declare that file.

Rules and their input scopes live in [.mmz/config.yaml](.mmz/config.yaml). Things
worth knowing:

- Adding an arm to `just check` means adding its rule to that manifest. mmz's
  default `strict` setting rejects an invocation matching no rule (and one whose
  rule resolves to zero files), so a missing rule is an error, not a silent pass.
- Rule names match by prefix on whole argv tokens. `just test` is `match: exact`
  so a filtered `just test <filter>` can never record the full-suite identity.
- Rules tagged `gate` are the gate set: `mmz --is-fresh --tag gate` asserts every
  one already passed against this worktree and runs nothing, which is the check
  to wire into a pre-push hook or a task tracker's close gate. `just cover` and
  `just crap` are untagged — memoized, but never blocking.
- There is no `--force`. To re-run a fresh rule, touch one of its inputs or
  delete its record under `.mmz/cache/` (gitignored via `.mmz/.gitignore`).
- `mmz --status` prints every rule's freshness as a table.

## Copy-Paste Gate

`just check-dry` runs [jscpd](https://github.com/kucherenko/jscpd) over `src/`
and `tests/` and fails on any duplicated Rust block of >=70 tokens. Fix a
finding by extracting a shared helper — never by shuffling tokens until the
detector loses the scent.

## Dependency Audits

`cargo-deny` checks advisories, licenses, and dependency bans. Run it
separately (it's not part of `just check` — CI runs it in its own job):

```bash
cargo deny check advisories
cargo deny check licenses
```

## MSRV

The `rust-version` field in `Cargo.toml` declares the minimum supported Rust
version. CI verifies it compiles on that version in a separate job.

## Mutation Testing

`cargo-mutants` helps find assertion gaps by injecting bugs and checking that
tests catch them. Two recipes:

- `just mutants-diff` — sweeps only mutants touched by this branch's diff
  against `main` (the daily driver).
- `just mutants` — full-file sweep (a dev aid, never a gate).

A surviving `MISSED` mutant is a real assertion gap: a line covered but not
pinned by any assertion.

## Git Hooks

`just install-hooks` copies `scripts/pre-commit` to `.git/hooks/pre-commit`.
The hook runs `mmz --is-fresh --tag gate` — a freshness assertion that checks
every gate-tagged rule in `.mmz/config.yaml` already passed against this
worktree, running nothing of its own. It is cheap enough for every commit.
Hooks are not tracked by git, so run the recipe once per clone; bypass a
single commit with `git commit --no-verify`.

## Submitting Changes

1. Run `just check` before submitting — it runs clippy, tests, file size, and drift checks
2. Run `just fmt` to format code
3. Ensure `just cover` meets the 70% threshold
