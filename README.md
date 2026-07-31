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

You'll be prompted for project name, GitHub username, description, license, and
crate kind (`bin` or `lib`).

## What you get

**Language & toolchain**
- Rust 2024 edition, `rust-toolchain.toml`, `rustfmt.toml`, clippy at `deny` with `clippy.toml` thresholds
- Either kind of crate: a `bin` gets `main.rs`, a `clap` CLI, `assert_cmd` e2e tests
  and a cross-platform release matrix; a `lib` drops all of that and ships a
  publish-only release workflow

**Quality gates**
- Code coverage via `cargo-llvm-cov` (70% minimum) — it merges child-process
  profraw, so subprocess-based CLI tests actually attribute
- CRAP metric gate via `cargo-crap`
- Copy-paste gate via [jscpd](https://github.com/kucherenko/jscpd)
- File size limits via [linecop](https://github.com/mlavrinenko/linecop) (500 lines Rust, 200 Markdown)
- Dependency drift detection via [outdatty](https://github.com/mlavrinenko/outdatty)
- Unused dependency detection via `cargo-machete`
- Advisory, license and dependency-ban audit via `cargo-deny`
- MSRV asserted in CI against the `rust-version` in `Cargo.toml`
- Per-gate memoization via [mmz](https://github.com/mlavrinenko/mmz): every arm of
  `just check` is skipped when its declared inputs are unchanged, which makes the
  `just install-hooks` pre-commit hook (a gate-freshness assertion, every commit)
  affordable

**Testing**
- Inline tests extraction via `ejectest`
- CLI integration testing with `assert_cmd` + `predicates`
- Mutation testing recipes via `cargo-mutants` (a dev aid, never a gate)

**Error handling & CLI**
- `thiserror` for library errors; for a `bin`, `anyhow` + `clap` 4 + `env_logger`

**Nix dev environment**
- Flake with `nix develop` (rustc, cargo, clippy, rustfmt, just, rust-analyzer, nixd, ...)
- `direnv` / `.envrc` for automatic shell activation
- `Justfile` with common recipes (`just check`, `just test`, `just cover`, `just crap`, ...)
- `just install-hooks` for a pre-commit gate

**Docs & conventions**
- `CHANGELOG.md` (Keep a Changelog + SemVer)
- `CONTRIBUTING.md` with detailed conventions
- `AGENTS.md` with rules for LLM agents
- Multiple license support (MIT / Apache-2.0 / dual / GPL-3.0-only)

**CI/CD**
- GitHub Actions: CI (checks, coverage, dependency audit, MSRV), Pages deployment,
  cross-platform release + crates.io publish, all with pinned actions
- `dependabot.yml` for automated action bumps

## Template maintenance

After making changes to the template, validate that it still produces a working project:

```bash
just validate bin    # or: just validate lib
just mmz validate bin  # same, memoized — free when template/ is unchanged
```

This generates a project of that kind in a temp directory and runs fmt, clippy, tests, build, coverage, CRAP gate, file size checks, `cargo-deny` and a sandboxed `nix build` against it. It also asserts the gate wiring: a second `just check` must leave every gate-tagged mmz rule fresh, `mmz --is-fresh --tag gate` must then pass without running anything, and `just install-hooks` must produce an executable hook. An arm of `just check` with no rule in `.mmz/config.yaml` fails validation instead of shipping.

Both kinds are validated — CI matrices `bin` and `lib` — because an unvalidated
template branch rots silently.
