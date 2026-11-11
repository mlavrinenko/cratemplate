# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **The template ships the renovation gates.** Generated projects now format
  every `*.nix` with `nixfmt`, scan the tree for secrets on demand, track
  upstream workarounds with canibump, check the crate on Windows MSVC in CI,
  and can opt into MindTape at generation. `just check` runs a fast batch and
  then a build batch, each in parallel, printing one verdict on green and only
  the failed arms' logs on red; `just check cover` adds the coverage pair.
- **CRAP and jscpd ratchet against committed baselines.** `cargo-crap`'s native
  `--baseline`/`--fail-regression` and `jscpd`'s `--baseline`/`--fail-on-new-clones`
  gate new findings; `just tools::crap-baseline` and `just tools::dry-baseline`
  are the only writers, and a missing baseline fails the gate.
- **The reference-not-copy decision** records which template pieces are
  versioned flake inputs, generated files and copied bodies, and the schema
  convention keeps every future crate config generated and drift-tested.

### Changed

- **The template's tool set moves to qahq `58f9ec9`.** Generated projects
  get canibump, mindtape 0.5.0, jscpd 5.4.1 (clone baselines and near-miss
  detection) and cargo-crap 0.3.1 (native CRAP baselines), with linecop,
  outdatty and mmz moving to their current releases. The pin is a commit, not
  a branch, so a generated `flake.lock` keeps the exact tool set.

- **A green `just machete`, `just deny` and `just test` print less.**
  `machete` shows its output only when it fails (its banner said "found
  nothing" in three lines), `deny` passes `-L error` (43 lines of duplicate
  version warnings down to 1), and `test` passes `--cargo-quiet` to nextest
  so a first build prints no `Compiling` lines.

### Fixed

- **A release works in the workspace the template grows into.** The release
  hook, `just release` and both release workflows read the crate name, version
  and repository from the root `Cargo.toml`, which a virtual workspace root does
  not have. They now share `.just/scripts/release-meta.sh`, which picks the one
  publishable package from `cargo metadata` and refuses zero or several;
  support members set `publish = false`. cargo-release resolves its
  replacements and hook against the member directory, so the hook dates the
  root CHANGELOG from `WORKSPACE_ROOT` and runs through it. A new workspace
  release test proves `just release --dry-run` selects the crate, checks the
  root CHANGELOG and pushes nothing.

- **A generated project's first release works.** crates.io attaches a Trusted
  Publisher only to a crate that already exists, so both release workflows use
  a scoped `CARGO_REGISTRY_TOKEN` when present and skip the OIDC exchange, then
  switch to OIDC once the secret is gone. `just release` also accepts an empty
  origin, so the first push can create main.

- **`just land` failed when a lane ended on a commit that only files a task.**
  `wt-lock.sh amend` put `outdatty.lock` into that last commit, which a
  commit-msg hook asking for a `Refs:` footer outside `tasks/` refuses. It now
  folds the lock into the newest commit with a `Refs:` footer, by fixup and
  autosquash, so the task-filing commit stays tasks-only. `just land-repro`
  gains a lane that ends on one, with a stand-in commit-msg hook.

- **`just mutants` failed in every generated project.** cargo-mutants 27
  rejects the `exclude` key in `.cargo/mutants.toml`; the template now writes
  `exclude_globs`, and spells the bin's entry point `**/src/main.rs` so it
  matches in a workspace member too.

- **Comments claimed `cargo llvm-cov nextest` ignores `--status-level`; it
  doesn't.** Measured on cargo-llvm-cov 0.9.0 and cargo-nextest 0.9.143: in a
  one-crate repro the flag takes 2 `PASS` lines to 0, and in a generated project
  `--status-level pass` printed 178 `PASS` lines against a `fail` in
  `.config/nextest.toml`. The level now lives only in that file, where `just
  test` and `just cover` both read it, and `just test` drops its own flag. The
  Justfile, `.mmz/config.yaml`, `outdatty.yaml`, `AGENTS.md` and
  `CONTRIBUTING.md` say only why the level lives in one place.

- **A release could fail half-way and stay that way.** outdatty v0.6.0 and
  three library tags were published by hand before their tag was pushed, so
  the tag's `cargo publish` failed on "already exists", the run went red and a
  binary crate got no GitHub release. The template's release workflows now:
  - skip `cargo publish` when crates.io already has the version (any answer
    but 200 or 404 still stops the run), so the GitHub release still happens;
  - run again on an existing tag through `workflow_dispatch`
    (`gh workflow run release.yml -f tag=v1.2.3`), with every job checking out
    the tag and one run per tag at a time;
  - keep "Latest" on the highest tag when an older one is re-released, and
    update an existing GitHub release in place.

  `just release X.Y.Z` is now the whole release, so the push of main can't be
  forgotten and no tag lands on a red commit. It first refuses, with one
  `error:` and at most two `hint:` lines, a non-semver version, a dirty tree, a
  branch other than main, an origin/main with commits main lacks, an existing
  local or remote tag, a version already on crates.io, a CHANGELOG with nothing
  under `[Unreleased]`, failing gates and a failing `cargo publish --dry-run`.
  Then it pushes main (fast-forward only), waits for the `ci.yml` run on that
  exact commit, and tags and pushes the tag only if the run is green.
  `--dry-run` runs the checks and says what it would push:

  ```
  dry run: every check passed
  would push main, wait for ci.yml on it, then tag and push 'v0.3.0'
  ```

- **`just crap` failed in a lib cloned from git.** A lib ships no `tests/`;
  cargo-generate leaves an empty one, which a clone drops, and the staleness
  test behind `just crap` ran `find src tests`, which exits 1 on a directory
  that is not there. It now searches `tests` only where it exists, and `just
  validate` deletes empty directories first, so the lib is gated as a clone
  holds it.

- **`just check-dry` drew a 10-line table to say `0 clones`.** It now uses
  jscpd's `ai` reporter: 4 lines on a green run, and a red run still names both
  spans of every clone (`a.rs:1-14 ~ b.rs:1-14`).

- **Four gates whose output cost more than it was worth**, each measured on a
  real project built from this template and each fixed at the source rather than
  filtered:
  - `just deny` printed a full inclusion tree per crate it mentioned — **1411
    lines** to say `advisories ok, bans ok, licenses ok`, against 145 with
    `--hide-inclusion-graph` and the identical verdict.
  - `just crap` printed **every analyzed function**, passing ones included:
    3532 lines to report success, 10 with `--min 30` matched to the threshold.
    A red run still names every offender.
  - `just cover` printed one `PASS` line per test — **2316 lines, 2137 of them
    `PASS`**. The level moved to `.config/nextest.toml`, where both runners
    read it; 179 lines, same verdict, failures still printed in full.
    The file is a `gates-meta` mmz input, since it decides what the suite
    prints and, the day it grows retries or a default filter, what it runs.
  - `just cover` also merged profraw from binaries that no longer exist: the
    `--no-report` + separate `report` split deliberately keeps the pile so runs
    can be merged, so a long-lived checkout scored deleted code and reported a
    workspace total several points below the truth. It fails toward pessimism,
    which no floor complains about. `cargo llvm-cov clean --workspace` now runs
    first.
- **`just crap` scored whatever lcov happened to be on disk.** cargo-crap's
  `--missing pessimistic` grades a function with no coverage record as 0%, so a
  report older than the tree makes every file added since the last `just cover`
  look completely untested — measured elsewhere at ten failures naming real
  functions, every one an artifact, where `just cover` then reported one and
  exit 0. It now refuses a stale report through `just _lcov-stale-reason`,
  naming the remedy and printing no table. Deliberately *not* a `cover`
  prerequisite: that recipe is minutes of instrumented CPU and this gate is
  seconds, so re-reading the existing report has to stay possible. The same
  `--missing pessimistic` rule is why the gate now excludes `tests/**` and every
  ejected `*_tests.rs` — llvm-cov instruments the code under test, not the
  suite, so those files have no record and the gate was grading test helpers.
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
- **Three leftovers from the output port**, each in the template itself:
  `[no-exit-message]` on the root and template `mmz` recipes, so just's own
  `error: Recipe 'mmz' failed` line stops burying the reason a gate actually
  printed; `just count-tests` reads nextest's JSON listing instead of running
  the whole suite to scrape `N tests run` out of its summary; and `just test`
  forwards ARGS with `[positional-arguments]`, so a filter containing a space
  reaches each pass as one argument and a wildcard is not re-globbed. The
  template shell grows `jq` for the listing.
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

- **A generated project's first `just check` passes.** `outdatty-check`
  bootstraps a missing `outdatty.lock` and asks for a review; an existing lock
  is never refreshed, so real drift still fails. `outdatty.yaml` braces the
  `Cargo.toml` globs so a single-crate project no longer warns, and the docs
  note the one-time `Cargo.lock` miss. Bin, lib and workspace first checks are
  green.

- **A quote or line break in `description` is refused.** The placeholder regex
  rejects `"`, `\`, CR/LF, the other C0 controls and DEL, and
  `cargo-generate >= 0.16.0` enforces it before writing any file;
  `scripts/test-description.sh` is the regression.

### Added

- **Two parallel lanes land without a conflict.** Two `just fork` lanes that
  each add a CHANGELOG entry and re-confirm `outdatty.lock` stopped the second
  `just land` on both files. A generated crate now ships `.gitattributes`
  (`CHANGELOG.md` merges as a union, `outdatty.lock` goes to an `outdatty` merge
  driver that `just install-hooks` defines and that keeps main's copy). The
  `pre-merge` hooks in `.config/wt.toml` run `.just/scripts/wt-lock.sh`:
  `refresh` re-records the merged tree with `outdatty update` when the check is
  red, and `amend` folds the lock into the lane's last commit once the gate
  passed. `just land-repro` replays two such lanes in a scratch repo under
  /tmp, and `just validate` runs it. A line both lanes reworded stays twice in
  the changelog: read it after landing. Ported from corpuspeak (779d3b8).

- **The gates cover a Cargo workspace as well as one crate.** A project that
  moves its crates under `crates/` needs no edit to the template's files:
  `Justfile` reads the source roots from whether `crates/` exists
  (`_lcov-stale-reason`, `check-dry`, `eject`), the mmz `rust` and `manifests`
  scopes and outdatty's sources name `crates/` beside `src/`, and `flake.nix`
  sets a `pname`, without which `nix run` looked for the binary of
  `rust-workspace-unknown`. The doctest pass prints five lines per member even
  with no doctest, so `just test` now shows it only on failure. `just validate`
  converts a copy of the generated project to a workspace (a second member with
  a doctest) and gates that too. Release files still read the crate name from
  the root `Cargo.toml`.

- **Worktrunk delegation ships in the template.** Hooks in a user's own config
  don't travel with a clone, and without them `wt merge` squashes the branch,
  commits a dirty tree and runs no gate. A generated crate now carries
  `.config/wt.toml` and puts `worktrunk` in its dev shell. `just fork <slug>`
  makes a sibling worktree on a new branch (`pre-start` allows its `.envrc`);
  `just land` runs `wt merge --no-squash --no-commit --yes`, so every branch
  commit survives and a dirty tree is refused. Before the merge, `pre-merge`
  runs `just check`, then `mt check --commits <main>..HEAD` where the crate has
  a `.mindtape/` and `mt` is installed (the dev shell does not ship `mt`;
  otherwise `.just/scripts/wt-tasks.sh` skips it and says so). After it,
  `pre-remove` imports the gate records into the primary checkout with
  `mmz --import` (a no-op until the pinned mmz has that flag) and carries the
  coverage lcov over with `.just/scripts/wt-carry-lcov.sh`, so `just crap`
  there needs no second instrumented build. `just validate` runs the lcov
  carry through seven cases.
- **`just outdated`.** The dev shell now ships `cargo-outdated`
  (dependencies with newer versions published) as a dev aid wired into no
  gate: an upstream release is not a reason for CI to go red.
- **`just status`.** One-line view of every memoized rule's freshness
  (`mmz --status`): which arms of `just check` would re-run, and whether the
  pre-commit hook's `mmz --is-fresh --tag gate` would pass right now. Reads
  mmz's records only — runs no gate.
- **Template docs are generated from Typst sources.**
  `template/docs/src/*.typ` render through `docs/generate-md.sh` (Typst and
  typlite) into the committed `AGENTS.md`, `CONTRIBUTING.md` and `README.md`;
  `docs-md-check` fails on a hand edit or a stale render. The sources are
  variant-neutral, `typst`, `tinymist` and `typstyle` ship in the dev shell,
  and root `just docs-sync` / `docs-check` regenerate and verify them. The
  generated docs are leaner: AGENTS 17 lines/2.3 KB, CONTRIBUTING 96/6.7 KB,
  README 38/1.1 KB.
- **Static lint and rustdoc gates.** The template's `just check` runs
  `lint::workflows` (actionlint), `lint::shellcheck` (warning level, every
  tracked shebang script) and `lint::doc` (`RUSTDOCFLAGS=-D warnings cargo doc
  --workspace --no-deps --document-private-items`); root `just lint` runs
  actionlint and shellcheck over this repository too. Both tools ship in the
  root and template dev shells.
- **A commit refuses local machine paths.** The tracked
  `.githooks/local-paths` scans the staged index for `$HOME`, the checkout and
  the worktree's primary checkout, so a pasted log line cannot be committed;
  `pre-commit` runs it and `just install-hooks` wires `core.hooksPath`.
- **Dependency updates have owners.** Dependabot groups Cargo updates and
  covers GitHub Actions monthly; Renovate enables only the Nix manager for
  `flake.lock` (it needs the Renovate GitHub App installed).
- **CI gates the backlog.** Root `just check-tasks` runs `mt check && mt fix
  --check`, and `ci.yml` runs it as a step, so a malformed or stale task file
  fails the build.

### Changed

- **`just release` runs cargo-release instead of a 95-line recipe.** A generated
  crate gets `release.toml` and `.just/scripts/release-hook.sh`, and `cargo-release`
  in its dev shell. cargo-release bumps `Cargo.toml`, dates the entries under
  `[Unreleased]` as `## [X.Y.Z] - <date>` and commits, so nobody dates the
  CHANGELOG by hand any more; the hook keeps every refusal and hint of the old
  recipe, bar "requested a version that `Cargo.toml` does not carry", which the
  bump makes moot. The recipe still pushes main, waits for `ci.yml`
  (`.just/scripts/release-ci.sh`) and tags only on a green run. A re-run after
  a red run finds the bump and the dating done and changes nothing twice. The
  hook runs `just check` after the bump, since the bump itself makes the memoized
  gates stale, and refreshes outdatty's `release-notes` group.
- **Integration tests start as one binary.** A generated bin ships
  `tests/it/main.rs` (`mod cli;`) and `tests/it/cli.rs` instead of a lone
  `tests/cli.rs`. Cargo builds one executable per file directly in `tests/`,
  each linking every dependency again; a module under `tests/it/` joins the one
  `it` binary, and nextest still runs every test in its own process. A lib
  keeps no `tests/` at all, so it starts with no empty binary; `AGENTS.md` and

- **`just test` gates on cargo-nextest; doctests run in their own pass.** The
  gate is now `cargo nextest run --workspace --status-level fail` (one process
  per test, so a panic or a hang is isolated) followed by `cargo test
  --workspace --doc` — nextest does not run doctests, so a project with any
  keeps them gated and one with none pays a fast no-op. A green run prints the
  run header and the summary instead of a result block per binary (a thousand
  lines at 800 tests), and a red one prints every failure in full. `just cover`
  moves to `cargo llvm-cov nextest` so gate and coverage share the same runner
  — process-per-test and shared-process are different execution models, and a
  test must not pass under one and fail under the other with nothing saying
  so. The standalone `just nextest` recipe is folded into `just test` (it was
  the same command with a different status filter), and `just count-tests`
  scrapes nextest's `N tests run` summary line instead of `cargo test`'s
  `test result:` lines.
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
- **Tool bump: qahq to main.** `template/flake.lock` moves qahq from 0.4.0 to
  ae800a0: linecop v0.4.0 → v0.7.0, outdatty 0.7.0, ejectest 0.5.0, and a
  `jscpd` that evaluates without the `stdenv.isDarwin` / `stdenv.isLinux`
  deprecation warnings every generated dev shell printed on load. The shipped
  `.linecop.yaml` and `outdatty.yaml` need no change. `just eject` now masks
  only linecop's finding exit (1), so a broken linecop (exit 2 since 0.5)
  fails the recipe instead of reading as nothing to eject.
- **The template Justfile is a thin surface over scripts.**
  `template/Justfile` drops from 411 to 205 lines, labels every recipe with
  `[doc]`/`[group]`, and moves long bodies to `.just/scripts/`;
  `.just/scripts/**` is now a `gates-meta` input, and the cover/CRAP globs work
  in a workspace. Root `just validate` is 44 lines over `scripts/validate.sh`,
  `scripts/test-release.sh` and `scripts/test-workspace.sh`, with both
  `outdatty-update` calls gone.
- **Coverage reports a per-file floor, CRAP speaks GitHub, mutants use
  nextest.** `just cover` prints only the report header and TOTAL; the gate is
  70% workspace line coverage plus 60% for any production file with at least 5
  uncovered lines (tests excluded). `just crap` passes `--format github
  --threshold 30 --fail-above` and excludes `**/main.rs`, so green is silent
  and red names each offender. `.cargo/mutants.toml` runs mutants under
  nextest across the workspace with `profile = "mutants"`.
- **linecop measures hidden files.** Both configs set `include_hidden: true`;
  the template caps BASH/Shell at 200, Just at 210 and Typst at 250, and
  excludes `**/CHANGELOG.md`. Root `just check-docs` runs both configs.

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
