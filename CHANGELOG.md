# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Copy-paste gate via [jscpd](https://github.com/kucherenko/jscpd):
  `just check-dry` fails on duplicated Rust blocks of >=70 tokens.
- `cargo-deny` config (`deny.toml`) for advisory, license, and dependency-ban checks.
- `.github/dependabot.yml` for automated GitHub Actions version bumps.
- MSRV verification via `cargo-msrv` (`cargo msrv verify`).
- `cargo-mutants` recipes (`just mutants-diff` and `just mutants`) as dev aids.
- `.mindtape/config.toml` for task tracking with a flip gate wired to
  `mmz --is-fresh --tag gate`.

### Changed

- **Coverage: `cargo-tarpaulin` → `cargo-llvm-cov`.** llvm-cov merges the profraw
  of child processes, so subprocess-based CLI e2e tests attribute coverage
  correctly — tarpaulin missed them. The dev shell now exports `LLVM_COV` and
  `LLVM_PROFDATA` from a standalone LLVM matching the rustc version.
- **Pre-commit hook: `just check` → `mmz --is-fresh --tag gate`.** The hook is
  now a freshness assertion rather than a re-run, making it cheaper. The hook
  script moved from a Justfile heredoc to `scripts/pre-commit`.
- **`just install-hooks`** now copies `scripts/pre-commit` rather than
  generating it inline.
- **`just release`** now asserts `mmz --is-fresh --tag gate` instead of
  re-running `just check`.
- **Root CI** now matrices `bin`/`lib` and uses pinned actions (SHA) with
  `cache-nix-action` instead of the deprecated `magic-nix-cache-action`.
- **Root `just validate`** parameterised with a `KIND` argument (bin/lib).
  Validated both kinds.
- **Root mmz dogfood:** a `.mmz/config.yaml` memoizes `just validate`, so a
  no-op re-run is free when `template/` is unchanged.

### Removed

- `template/tarpaulin.toml` (replaced by `cargo-llvm-cov`).

### Fixed

- `template/.gitignore` no longer ignores all of `.cargo/` — only
  `.cargo/config.toml`, so `.cargo/mutants.toml` is tracked.

- Memoized gates via [mmz](https://github.com/mlavrinenko/mmz). Every arm of
  `just check` now runs as `just mmz <subgate>` (i.e. `mmz just <subgate>`), so
  an arm whose declared inputs are unchanged since it last passed is skipped;
  the rules, input scopes and the `gate` tag live in a shipped
  `.mmz/config.yaml`. `chronic` is gone from `just check`: a hit prints one
  quiet `on_hit` line, a miss streams the recipe's real output, and a failure
  is readable where it happens instead of needing a bare re-run.
- `just install-hooks`: writes a `pre-commit` hook that runs `just check` inside
  the flake dev shell (via `direnv exec`, falling back to `nix develop`).
  Gating every commit on the full suite is affordable only because of the
  memoization above.
- `.mmz/config.yaml` is an `outdatty` `dev-docs` source, so a change to what
  the gates read flags `CONTRIBUTING.md`/`AGENTS.md` for review.

### Changed

- `just fix-check` now runs `clippy-fix` before `fmt`: a clippy autofix can land
  unformatted, so formatting has to come after it for the trailing `check` to
  stay green.
- The template dev shell takes `mmz` as a direct flake input rather than through
  `qahq`, whose pin (v0.3.0) predates the `tags:` the manifest uses.
- Bumped the `qahq` input (it now also carries `jscpd`).
- `just validate` additionally asserts the gate wiring: a second `just check`,
  then `mmz --is-fresh --tag gate`, then `just install-hooks` producing an
  executable hook. An arm of `just check` with no rule in `.mmz/config.yaml`
  now fails template validation instead of shipping.

### Removed

- Dropped the `sccache` rustc-wrapper from the template dev shell and its
  `just validate` gate. Rust caching is now expected from a system-wide wrapper
  (e.g. kache set via `RUSTC_WRAPPER` in the host session), which the dev shell
  inherits; pinning a per-project wrapper is redundant and would override it.
  The clean-sandbox `nix build` check in `just validate` is retained.

### Fixed

- Generated projects no longer fail `nix build`. The `rustc-wrapper = "sccache"`
  dev speedup moved from a committed `.cargo/config.toml` (which naersk vendored
  into the sandboxed package build, where sccache is absent) to the flake dev
  shell's `RUSTC_WRAPPER`. `just validate` now also runs `nix build` so this
  class of package-build regression is caught.

### Added

- CRAP metric gate (`cargo-crap`): fails when a function is both complex and
  undertested, which a global coverage threshold can hide. Wired into CI and `just validate`.
- Dependency drift gate (`outdatty`) with a default `outdatty.yaml` that couples
  source files to the docs and notes that must track them.
- Unused-dependency check (`cargo-machete`).
- CLI integration tests in `tests/cli.rs` using `assert_cmd` + `predicates`.
- Proactive inline-test ejection: `just fix-check` runs `ejectest` over files at or
  above a `linecop --baseline` percentage, splitting their `#[cfg(test)]` modules
  into sibling `_tests.rs` files before they breach the size limit.
- `just fix-check` aggregate recipe (fmt, clippy `--fix`, then checks).
- Minimal `clap` CLI example (a `greet` command) wired through `main.rs` and `lib.rs`.
- Release version guard: a pushed `vX.Y.Z` tag must match the `Cargo.toml` version.
- Cross-platform release matrix (Linux x86_64/aarch64, macOS x86_64/aarch64, Windows x86_64).
- `args` parameter for `just build`.
- `ejectest` in the default dev shell.

### Changed

- File-size enforcement now uses `linecop` (replaces the previous `tokei` + `jq` script).
- CI runs inside the Nix dev shell, so local `just check` and CI execute the same gates.
- CI caches the Nix store via `cache-nix-action`, replacing the deprecated magic-nix-cache.
- Pinned all GitHub Actions (first-party to release tags, third-party to commit SHAs).
- Release `publish` now waits on the cross-platform `build` job and runs `cargo publish --locked`.
- Checks run in parallel via `moreutils parallel` + `chronic`.
- Coverage excludes `var/`; `CHANGELOG.md` is bundled into the published crate.
- Renamed `AGENT.md` to `AGENTS.md`.
- README "What you get" restructured; all gates and prompts documented.

### Removed

- Unused `serde` + `serde_json` dependencies.

### Fixed

- `clippy-fix` tolerates a dirty or staged tree (it runs before commit).
- Expose both `devShells.default` and the legacy `devShell` for broader Nix compatibility.
- Exclude all workflow files from `cargo-generate` substitution, so GitHub Actions
  `${{ ... }}` expressions generate verbatim.

## [0.1.0] - 2026-03-10

Initial release.

### Added

- Rust 2024 edition project scaffold with strict clippy lints
- Error handling with `anyhow` + `thiserror`
- CLI support via `clap` (with `derive` feature)
- Serialization with `serde` + `serde_json`
- Logging with `log` + `env_logger`
- Nix flake dev environment (rustc, cargo, clippy, rustfmt, just, rust-analyzer, etc.)
- `Justfile` with common recipes (`check`, `test`, `clippy`, `cover`, `fmt`, `release`, etc.)
- Code coverage via `cargo-tarpaulin` (70% minimum threshold)
- File size limits enforced via `tokei` + `jq` (500 lines for Rust, 200 for Markdown)
- `AGENT.md` with conventions for LLM coding agents
- `CONTRIBUTING.md` with contribution guidelines
- Template validation script (`just validate`)
- CI workflow (GitHub Actions)
- `cargo-generate` template with prompts for project name, description, license, and GitHub username
- Conditional license file inclusion (MIT, Apache-2.0, dual, GPL-3.0)
- Optimized release profile (strip, LTO, single codegen unit, abort on panic)

[Unreleased]: https://github.com/mlavrinenko/cratemplate/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/mlavrinenko/cratemplate/releases/tag/v0.1.0
