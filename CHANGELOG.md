# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
