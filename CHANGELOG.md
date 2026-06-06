# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
