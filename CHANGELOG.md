# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- **`just fix-check` no longer goes red over a near-limit Markdown file.**
  `just eject` piped `linecop --baseline 90 --format paths` into ejectest under
  `bash -eo pipefail`; linecop exits 1 to FLAG files at/over the baseline (a
  finding, not a failure to run), so the pipeline died on the producer before
  ejectest ever ran — any file at ≥90% of its limit red the whole
  `fix-check`, even when nothing was ejectable (the scan also handed Markdown
  paths to a tool that moves inline Rust test modules). The recipe now masks
  linecop's finding-exit and narrows the scan to `*.rs`. `just validate` grows
  a generated project's README.md past the 90% baseline and requires
  `just fix-check` to stay green.
- **`just validate` re-asserts the shipped `flake.lock` after the nix block.**
  `nix develop` silently re-resolves (and rewrites `flake.lock` in place) if
  the lock ever drifts from `flake.nix`'s inputs; the pre-nix byte-identity
  check only proved the lock shipped. A post-nix `cmp` fails the gate instead
  of letting it test upstream HEAD on a re-resolved lock.
- **Generated projects inherit a validated `flake.lock`, and `just validate`
  now tests exactly what ships.** cargo-generate used to drop `flake.lock`
  (`cargo-generate.toml`), so a generated project re-resolved every input at
  upstream HEAD on its first `nix develop` — a stale pin in
  `template/flake.lock` (qahq v0.2.0, outdatty 0.3.0) could never trip the
  gate, even though any project that carried the lock failed `just check` out
  of the box (`unknown field require_tracked` — outdatty learned the field
  only in 0.4.0). The lock now ships with every generated project (bump with
  `nix flake update` on your own schedule), and validate asserts the
  generated lock is byte-identical to the template's — a regression in the
  ignore list fails loudly instead of silently stopping the gate from
  testing the shipped pins. qahq is pinned to v0.4.0 (outdatty 0.4.0, mmz
  0.10.0, linecop 0.4.0), with mmz now taken through qahq rather than a
  direct input.
- **Generated projects pass `just check` on their first real commit.** The
  template ships an explicit `require_tracked` in `outdatty.yaml`, listing only
  files that carry hand-written coupling (`src/**`, `www/**`, the docs, and the
  manifests). Without it outdatty defaults to requiring every tracked file, so
  the scaffold's configs, CI, and lockfiles had to belong to a group for
  `outdatty-check` to pass at all. New source modules still trip the gate — the
  failure message now points at the manifest, which says to add them to a group.

### Added

- **`just nextest` and `just outdated`.** The dev shell now ships
  `cargo-nextest` (per-test process isolation and readable output) and
  `cargo-outdated` (dependencies with newer versions published). Both are dev
  aids, wired into no gate: nextest does not run doctests, so `just test` stays
  what `just check` and `just cover` drive, and an upstream release is not a
  reason for CI to go red.
- **`just status`.** One-line view of every memoized rule's freshness
  (`mmz --status`): which arms of `just check` would re-run, and whether the
  pre-commit hook's `mmz --is-fresh --tag gate` would pass right now. Reads
  mmz's records only — runs no gate.

### Changed

- **Git hook is tracked and auto-wired.** `.githooks/pre-commit` follows the
  clone (no post-clone copy); `just install-hooks` now runs
  `git config core.hooksPath .githooks` (the dev-shell `shellHook` runs the
  same recipe on entry), so the gate-freshness assertion the hook runs
  (`mmz --is-fresh --tag gate`) is live with no manual step. Edits to the
  tracked hook take effect immediately, and the legacy `cp scripts/pre-commit
  .git/hooks/pre-commit` step is gone.
- **Recipe shell settings are global.** The template Justfile sets
  `shell := ["bash", "-eo", "pipefail", "-c"]` and `ignore-comments := true`,
  so recipes no longer repeat a `#!/usr/bin/env bash` + `set -eo pipefail`
  preamble and every line gets errexit plus pipefail (just's default `sh -cu`
  gives neither). `cover`, `check-dry`, and `install-hooks` are plain recipes
  now; `release` and `mutants-diff` keep a shebang because they need one shell
  across several lines. No `-u`.

## [0.2.0] - 2026-07-31

### Added

#### Crate kinds

- **`crate_kind` prompt (`bin` or `lib`).** A `lib` generation drops `src/main.rs`
  and `tests/cli.rs`, omits the `[[bin]]` target and the CLI-only dependencies
  (`anyhow`, `clap`, `env_logger`), and ships a lib-only release workflow
  (`release-lib.yml`: version guard, check, `cargo publish`) instead of the
  cross-platform build matrix. `README.md`, `CONTRIBUTING.md`, `AGENTS.md`,
  `outdatty.yaml` and `.cargo/mutants.toml` all branch on it.

#### Gates

- **Memoized gates via [mmz](https://github.com/mlavrinenko/mmz).** Every arm of
  `just check` runs as `just mmz <subgate>` (i.e. `mmz just <subgate>`), so an
  arm whose declared inputs are unchanged since it last passed is skipped. The
  rules, their input scopes and the `gate` tag live in a shipped
  `.mmz/config.yaml`. `chronic` is gone from `just check`: a hit prints one quiet
  `on_hit` line, a miss streams the recipe's real output, and a failure is
  readable where it happens instead of needing a bare re-run.
- **Git hooks (`just install-hooks`).** Copies `scripts/pre-commit`, which runs
  `mmz --is-fresh --tag gate` — an assertion that every gate-tagged rule already
  passed against this worktree, running nothing itself. Cheap enough for every
  commit. Enters the dev shell cheapest-first: already inside it, else `direnv`,
  else `nix develop`.
- Copy-paste gate via [jscpd](https://github.com/kucherenko/jscpd):
  `just check-dry` fails on duplicated Rust blocks of >=70 tokens.
- Dependency audit via `cargo-deny` (`just deny`, plus its own CI job):
  advisories, a license allow-list, and dependency bans. Kept out of `just check`
  because it fetches the advisory database and would break an offline commit.
- MSRV job in CI: compiles the workspace on the `rust-version` from `Cargo.toml`,
  so the declared minimum is asserted rather than assumed.
- CRAP metric gate (`cargo-crap`): fails when a function is both complex and
  undertested, which a global coverage threshold can hide.
- Dependency drift gate ([outdatty](https://github.com/mlavrinenko/outdatty))
  with a default `outdatty.yaml` coupling source files to the docs that track
  them. `.mmz/config.yaml` is itself a `dev-docs` source, so a change to what the
  gates read flags `CONTRIBUTING.md`/`AGENTS.md` for review.
- Unused-dependency check (`cargo-machete`).
- `.github/dependabot.yml` for automated GitHub Actions bumps.

#### Testing

- CLI integration tests in `tests/cli.rs` using `assert_cmd` + `predicates`.
- Proactive inline-test ejection: `just fix-check` runs `ejectest` over files at
  or above a `linecop --baseline` percentage, splitting their `#[cfg(test)]`
  modules into sibling `_tests.rs` files before they breach the size limit.
- `cargo-mutants` recipes (`just mutants-diff`, `just mutants`) with a
  `.cargo/mutants.toml`, as dev aids — never gates.

#### Recipes and release

- `just fix-check` aggregate recipe (eject, clippy `--fix`, fmt, then checks).
- Minimal `clap` CLI example (a `greet` command) wired through `main.rs` and
  `lib.rs`.
- Release version guard: a pushed `vX.Y.Z` tag must match the `Cargo.toml`
  version.
- Cross-platform release matrix (Linux x86_64/aarch64, macOS x86_64/aarch64,
  Windows x86_64).
- `args` parameter for `just build`.

#### This repository

- `.mindtape/config.toml` for task tracking, with a flip gate wired to
  `mmz --is-fresh --tag gate`.
- `.mmz/config.yaml` memoizing `just validate`, so a no-op re-run is free when
  `template/` is unchanged. Both rules carry the `gate` tag — the tag the
  MindTape flip gate asserts, which passes vacuously when no rule bears it.
- `.github/dependabot.yml`, the same config the template ships: this repo pins
  its actions to SHAs, which only stays safe if something bumps them.

### Changed

- **Coverage: `cargo-tarpaulin` → `cargo-llvm-cov`.** llvm-cov merges the profraw
  of child processes, so subprocess-based CLI e2e tests attribute coverage
  correctly — tarpaulin missed them, which meant both the 70% floor and the CRAP
  gate were scoring a distorted picture. The dev shell now exports `LLVM_COV`
  and `LLVM_PROFDATA` from a standalone LLVM matching the rustc version.
- **Licence choice `GPL-3.0` → `GPL-3.0-only`.** Plain `GPL-3.0` is a deprecated
  SPDX identifier; it warns in `cargo deny check licenses` and is what crates.io
  parses out of the `license` field.
- File-size enforcement now uses [linecop](https://github.com/mlavrinenko/linecop)
  (replaces the previous `tokei` + `jq` script).
- Shared QA tooling (`cargo-crap`, `ejectest`, `jscpd`, `linecop`, `outdatty`)
  now comes from the `qahq` flake. `mmz` is taken as a direct input rather than
  through `qahq`, whose pin predates the `tags:` the manifest uses.
- `just fix-check` runs `clippy-fix` before `fmt`: a clippy autofix can land
  unformatted, so formatting has to come after it for the trailing `check` to
  stay green.
- `just release` asserts `mmz --is-fresh --tag gate` instead of re-running
  `just check`.
- CI runs inside the Nix dev shell, so local `just check` and CI execute the same
  gates; checks run in parallel via `moreutils parallel`.
- CI caches the Nix store via `cache-nix-action`, replacing the deprecated
  magic-nix-cache. All GitHub Actions pinned (first-party to release tags,
  third-party to commit SHAs).
- Release `publish` waits on the cross-platform `build` job and runs
  `cargo publish --locked`.
- Coverage excludes `var/`; `CHANGELOG.md` is bundled into the published crate.
- Renamed `AGENT.md` to `AGENTS.md`; README "What you get" restructured.
- **Root `just validate`** takes a `KIND` argument (`bin`/`lib`) and additionally
  asserts the gate wiring: a second `just check` must be a full cache hit, then
  `mmz --is-fresh --tag gate`, then `just install-hooks` must produce an
  executable hook, then `just deny` must pass. An arm of `just check` with no
  rule in `.mmz/config.yaml`, or a `deny.toml` that has drifted out of
  cargo-deny's schema, now fails template validation instead of shipping.
- **Root CI** matrices `bin`/`lib` and uses pinned actions (SHA) with
  `cache-nix-action` instead of the deprecated `magic-nix-cache-action`.

### Removed

- `tarpaulin.toml`, replaced by `cargo-llvm-cov`.
- The `sccache` rustc-wrapper and its `just validate` gate. Rust caching is now
  expected from a system-wide wrapper (e.g. kache set via `RUSTC_WRAPPER` in the
  host session), which the dev shell inherits; pinning a per-project wrapper is
  redundant and would override it.
- Unused `serde` + `serde_json` dependencies.
- The `CLAUDE.md` symlink (cargo-generate skips symlinks, so it never generated).

### Fixed

- **`deny.toml` was rejected outright by cargo-deny >= 0.16.** It still used the
  retired `advisories.vulnerability`/`notice` and `licenses.unlicensed`/
  `copyleft`/`default` keys and a top-level `targets`, so every generated
  project's dependency-audit CI job failed on a config deserialisation error.
  Rewritten to the current schema (`[graph] targets`, `unmaintained =
  "workspace"`, `unused-allowed-license = "allow"`), and `just validate` now
  runs it so this cannot rot again.
- A `GPL-3.0-only` generation failed `cargo deny check licenses`: cargo-deny
  checks workspace members too, so the crate's own licence has to appear in the
  allow-list. `deny.toml`'s allow-list is now licence-aware.
- The `README.md` licence badge linked to `LICENSE-MIT` regardless of the licence
  chosen, a dead link for Apache-2.0 and GPL generations.
- Generated projects no longer fail `nix build`. The `rustc-wrapper = "sccache"`
  dev speedup moved out of a committed `.cargo/config.toml`, which naersk
  vendored into the sandboxed package build where sccache is absent.
  `just validate` now runs `nix build` so this class of regression is caught.
- `.gitignore` no longer ignores all of `.cargo/` — only `.cargo/config.toml`,
  so `.cargo/mutants.toml` is tracked.
- Lib generations pass `just check`: `outdatty.yaml` is `crate_kind`-aware
  (`src/main.rs` only exists for a bin), and the Liquid conditionals in the
  templated docs and manifests trim their whitespace.
- `clippy-fix` self-heals a read-only `target/` and tolerates a dirty or staged
  tree (it runs before commit).
- Both `devShells.default` and the legacy `devShell` are exposed, for broader Nix
  compatibility.
- All workflow files are excluded from `cargo-generate` substitution, so GitHub
  Actions `${{ ... }}` expressions generate verbatim.

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

[Unreleased]: https://github.com/mlavrinenko/cratemplate/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mlavrinenko/cratemplate/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/mlavrinenko/cratemplate/releases/tag/v0.1.0
