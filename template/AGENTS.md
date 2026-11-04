# {{project-name}}

## Agent Rules

- See and use [Justfile](Justfile). Add any repeatable and regular operations there.
  `set shell` already gives every recipe line `bash -eo pipefail`, so a new recipe
  needs no `#!/usr/bin/env bash` + `set -eo pipefail` preamble. just runs each line
  in a fresh shell though — add a shebang only when the body needs one shell across
  lines (a variable read back later, a `trap`).
- At the end ensure that `just fix-check` is green.
{% if crate_kind == "bin" -%}
- Tests: inline `#[cfg(test)]` units; CLI/integration in `tests/it/` (`assert_cmd` + `predicates`), one test binary: a new file is `tests/it/<name>.rs` plus `mod <name>;` in `tests/it/main.rs`, never a new top-level `tests/<name>.rs`. `just fix-check` auto-ejects inline tests from oversized files via `ejectest`.
{% endif -%}
{% if crate_kind == "lib" -%}
- Tests: inline `#[cfg(test)]` units next to the code they exercise; add integration tests for public-API behaviour that spans modules in `tests/it/<name>.rs` with `mod <name>;` in `tests/it/main.rs` (create it for the first one): one test binary, never a top-level `tests/<name>.rs`. `just fix-check` auto-ejects inline tests from oversized files via `ejectest`.
{% endif -%}
- Coverage and CRAP gates run separately (CI + `just validate`): `just cover`
  then `just crap`. `just cover` uses `cargo-llvm-cov` (not tarpaulin) — it
  merges child-process profraw, so subprocess-based e2e tests attribute
  correctly. If `just crap` flags a function, add tests or reduce its
  branching — don't raise the threshold to dodge it.
- Every arm of `just check` is `just mmz <subgate>`:
  [mmz](https://github.com/mlavrinenko/mmz) skips arms whose declared inputs are
  unchanged since they last passed, so a new or retargeted gate needs its rule in
  [.mmz/config.yaml](.mmz/config.yaml) — an unmatched command is a hard error, not
  a silent skip. Don't wrap `just check` arms in `chronic`: a cache hit is already
  quiet, and a miss must stream its output.
- Be careful with the context. Omit non-necessary command outputs using `chronic` or `grep`.
- [outdatty.yaml](outdatty.yaml) couples sources to dependents. When `just check`
  reports drift, update the listed dependents, run `just outdatty-update`, and
  commit the refreshed `outdatty.lock` with the change. Add a group whenever you
  introduce files that must stay in sync.
- `just check-dry` (jscpd) flags duplicated Rust blocks of >=70 tokens. Fix
  a finding by extracting a shared helper — never by shuffling tokens until
  the detector loses the scent.
- `just deny` (cargo-deny: advisories, licenses, bans) is not in `just check` —
  it needs network. Run it after touching dependencies. Widen `deny.toml`'s
  allow-list deliberately; never to silence a finding. `just outdated`
  (cargo-outdated) is network-bound too and reports newer upstream releases;
  it is a dev aid, never a gate.
- `just test` gates the suite on cargo-nextest, whose output level lives in
  `.config/nextest.toml` — a green run prints only the summary, a red one
  prints each failure's full output — plus a `cargo test --doc` pass, because
  nextest does not run doctests. `just cover` instruments that same runner via
  `cargo llvm-cov nextest`, so a test cannot pass under the gate and fail under
  coverage (or the reverse) with nothing saying so.
- Release only with `just release X.Y.Z`, after `just release X.Y.Z --dry-run`
  passes; never `cargo publish` by hand, never bump `Cargo.toml` or date the
  CHANGELOG yourself, and don't push main first. Keep the release's entries
  under `[Unreleased]`: [cargo-release](https://github.com/crate-ci/cargo-release)
  (`release.toml`) bumps the version, dates them and commits. Its
  `pre-release-hook`, [.just/scripts/release-hook.sh](.just/scripts/release-hook.sh),
  refuses a dirty tree, a branch but main, an origin/main that main lacks
  commits of, an existing tag, a version already on crates.io, a CHANGELOG with
  nothing to release, failing gates (`just check`) and a failing
  `cargo publish --dry-run`. Then the recipe pushes main, waits for `ci.yml` on
  that commit (`.just/scripts/release-ci.sh`), and tags only if it is green; a
  red run leaves main pushed and no tag, and a re-run after fixing it changes
  nothing the first run did. A release whose workflow failed
  is finished on the same tag with `gh workflow run <release workflow> -f
  tag=vX.Y.Z`; a pushed tag never moves. The workflow publishes through
  crates.io Trusted Publishing, but crates.io attaches a publisher only to a
  crate that already exists. For the first release, create a scoped API token
  and store it as `CARGO_REGISTRY_TOKEN` (repository or the `crates-io`
  environment); the workflow uses it and skips OIDC. Then add the Trusted
  Publisher (owner, repository, workflow file, environment `crates-io`) and
  delete the secret. Later tags need no secret.
- Delegated work forks with `just fork <slug>` (a sibling worktree on a new
  branch, dev shell allowed) and lands with `just land` run in that worktree:
  it gates, fast-forwards main and removes the worktree. Both wrap
  [worktrunk](https://worktrunk.dev); [.config/wt.toml](.config/wt.toml) holds
  the hooks, and `.just/scripts/` the scripts they run. Never run a bare
  `wt merge`: it squashes away the branch's commits and commits a dirty tree.
  `pre-merge` also runs `mt check --commits` where the crate tracks tasks with
  MindTape and `mt` is installed (the dev shell does not ship it), else skips it.
  `pre-remove` imports the gate records into the primary checkout when its mmz
  has `mmz --import`, else skips that too.
- Landing never stops on `CHANGELOG.md` or `outdatty.lock`.
  [.gitattributes](.gitattributes) merges the changelog as a union, so two lanes'
  new entries both stay (a line both reworded stays twice: read it after
  landing), and gives the lock to the `outdatty` merge driver, which
  `just install-hooks` defines and which keeps main's copy. The `pre-merge`
  hooks in `.config/wt.toml` run `.just/scripts/wt-lock.sh`: `refresh` re-records
  the merged tree with `outdatty update` when the check is red, and `amend`
  folds the lock into the lane's newest commit with a `Refs:` footer after the
  gate passes, so a trailing task-filing commit stays tasks-only. `just
  land-repro` replays two such lanes in a scratch repo under /tmp.
- Eating your own dog food: the tool should use itself if applicable.

See [CONTRIBUTING.md](CONTRIBUTING.md) for project conventions and code standards.
