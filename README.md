<p align="center">
  <img src="logo.svg" width="200" alt="cratemplate logo">
</p>

# CRATEmPLATE

[![CI](https://github.com/mlavrinenko/cratemplate/actions/workflows/ci.yml/badge.svg)](https://github.com/mlavrinenko/cratemplate/actions/workflows/ci.yml)
[![cargo-generate](https://img.shields.io/badge/cargo--generate-template-blue)](https://github.com/cargo-generate/cargo-generate)

An opinionated [cargo-generate](https://github.com/cargo-generate/cargo-generate) template for Rust projects.

## Usage

```bash
cargo generate gh:mlavrinenko/cratemplate
# or using nix:
nix run nixpkgs#cargo-generate -- generate --git https://github.com/mlavrinenko/cratemplate
```

You'll be prompted for project name, GitHub username, description, and license.

## What you get

**Language & toolchain**
- Rust 2024 edition, `rust-toolchain.toml`, `rustfmt.toml`, clippy at `deny` with `clippy.toml` thresholds

**Quality gates**
- Code coverage via `cargo-tarpaulin` (70% minimum)
- CRAP metric gate via `cargo-crap`
- File size limits via [linecop](https://github.com/mlavrinenko/linecop) (500 lines Rust, 200 Markdown)
- Dependency drift detection via [outdatty](https://github.com/mlavrinenko/outdatty)
- Unused dependency detection via `cargo-machete`

**Testing**
- Inline tests extraction via `ejectest`
- CLI integration testing with `assert_cmd` + `predicates`

**Error handling & CLI**
- `anyhow` + `thiserror` for errors, `clap` 4 for CLI, `log` + `env_logger`

**Nix dev environment**
- Flake with `nix develop` (rustc, cargo, clippy, rustfmt, just, rust-analyzer, nixd, sccache, ...)
- `direnv` / `.envrc` for automatic shell activation
- `Justfile` with common recipes (`just check`, `just test`, `just cover`, `just crap`, ...)

**Docs & conventions**
- `CHANGELOG.md` (Keep a Changelog + SemVer)
- `CONTRIBUTING.md` with detailed conventions
- `AGENTS.md` with rules for LLM agents
- Multiple license support (MIT / Apache-2.0 / GPL-3.0)

**CI/CD**
- GitHub Actions: CI, Pages deployment, cross-platform release + crates.io publish

## Template maintenance

After making changes to the template, validate that it still produces a working project:

```bash
just validate
```

This generates a project in a temp directory and runs fmt, clippy, tests, build, coverage, CRAP gate, and file size checks against it.
