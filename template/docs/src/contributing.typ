// docs/src/contributing.typ — source for the generated CONTRIBUTING.md at the
// repo root. `just docs-md` reads the <docs-md> block below, renders this file
// with typlite, and writes the declared output; never hand-edit CONTRIBUTING.md.
//
// Variant-neutral: only simple placeholders, no Liquid control flow. typlite
// escapes Markdown link syntax, Markdown emphasis and underscore placeholders
// in prose, so use #link, *bold* and code spans for `{{crate_name}}`.
#import "lib.typ": doc-title, project

#metadata((
  output: "CONTRIBUTING.md",
)) <docs-md>

#doc-title[Contributing to #project]

= Setup

Prerequisites: #link("https://nixos.org/")[Nix] with flakes enabled. The dev
shell pins every tool the gates use.

```bash
direnv allow    # or: nix develop
just            # list recipes
just check      # the full gate, memoized
```

A fresh project ships no `outdatty.lock`: the first `just check` creates one
and prints a review-and-commit notice. An existing lock is never refreshed
automatically, so real drift still fails. A new `Cargo.lock` also causes a
one-time mmz miss; later runs skip every arm whose inputs did not change.

= Code style and errors

Every configured clippy lint is `deny`: the project does not compile with a
violation. No `unwrap()` or `expect()`, no `todo!()`, `unimplemented!()` or
`unreachable!()`, no `unsafe`, no wildcard imports, no single-character names.
Functions stay under 70 lines, 5 arguments and cognitive complexity 20.
Propagate errors with `?`; use `anyhow::Result` in application code and
`thiserror::Error` for library errors callers match on.

= Project structure

A bin keeps `main.rs` a thin entry point — argument parsing, logger init, a
call into the library; it is excluded from coverage, so logic there is
untested. All logic belongs in `lib.rs` and its modules; a library keeps its
public API small and documented, with `# Errors` sections where relevant.

= Testing

- Unit tests live inline in `#[cfg(test)] mod tests` beside the code they
  exercise.
- Integration tests live in `tests/it/`, the one integration binary: a new
  file is `tests/it/<name>.rs` plus `mod <name>;` in `tests/it/main.rs` (create
  it with the first one), never a top-level `tests/<name>.rs`. Shared helpers
  go in `tests/it/common/mod.rs`, declared once as `mod common;`.
- A bin drives the built binary with #link("https://docs.rs/assert_cmd")[`assert_cmd`]
  and #link("https://docs.rs/predicates")[`predicates`], while a lib exercises
  its public API.
- `just test` runs nextest plus doctests; `just cover` instruments the same
  runner. `just fix-check` ejects inline tests from files near the linecop cap.

= File size limits

Rust files: 500 lines. Markdown: 200. Split a file into modules or separate
documents; #link(".linecop.yaml")[.linecop.yaml] holds the limits.

= Dependency drift

#link("outdatty.yaml")[outdatty.yaml] couples sources to dependents.
`just check` fails when a source moved and its dependents were not
re-confirmed. Update the listed dependents, run `just outdatty-update`, and
commit `outdatty.lock`. Add a group when files must stay in sync.

= Coverage and CRAP

`just cover` enforces a 70% workspace line total plus 60% on each production
file with at least 5 uncovered lines; `tests/` and `*_tests.rs` are exempt. A
green run prints only the report header and TOTAL. `just crap` scores the lcov
`just cover` wrote with `cargo crap --format github` at a threshold of 30: it
prints nothing when green, refuses a stale lcov, and excludes `**/main.rs`,
`tests/` and `*_tests.rs`. It also reads the committed
#link(".config/crap-baseline.json")[.config/crap-baseline.json]: a function may
rise back to its recorded score but not past it. Only
`just tools::crap-baseline` tightens the ratchet, a missing baseline fails the
gate, and `just land-repro` proves the file merges across lanes. Neither gate is
in the default `just check`; CI runs them, and `just check cover` runs them on
demand. Fix a finding with tests or less branching, never a lower threshold.

= Memoized gates

Every arm of `just check` is `just mmz <subgate>`; rules, scopes and the `gate`
tag live in #link(".mmz/config.yaml")[.mmz/config.yaml]. A new or renamed gate
needs its rule there — an unmatched invocation is a hard error, not a silent
skip. `just status` prints freshness, there is no `--force`, and the
pre-commit hook asserts `mmz --is-fresh --tag gate`.

`just check` runs the fast batch first and the build batch only when it is
green; every arm in a batch runs in parallel through `mmz`. A green run prints
one verdict, and a red run prints only the failed arms' logs. `just check
cover` adds the opt-in coverage pair.

= Static lint gates

- `just lint::workflows` runs actionlint over `.github/workflows/*.yml`.
- `just lint::shellcheck` runs shellcheck at warning severity over every
  tracked script with a bash or sh shebang; the hooks are inline shell, so
  they are covered too.
- `just lint::doc` runs rustdoc with `RUSTDOCFLAGS="-D warnings"`, private
  items included.
- `just tools::nix-fmt-check` gates every `*.nix`; `just fmt` rewrites them
  with the same `nixfmt`, and `nix fmt` uses the flake formatter.
- `just docs-md-check` fails when a generated document is stale; see
  #link("#generated-docs")[Generated docs].

All five are arms of `just check`.

= Copy-paste gate

`just check-dry` fails only on a Rust clone absent from
#link(".config/jscpd-baseline.json")[.config/jscpd-baseline.json];
`just tools::dry-baseline` rewrites it deliberately. Extract a shared helper
instead of shuffling tokens; a library without `tests/` is scanned as just
`src`.

= Dependency audits

`just deny` checks advisories, licenses and bans; it needs network and is not
in `just check` (CI runs it in its own job). The policy is
#link("deny.toml")[deny.toml] — widen it deliberately, never to silence a
finding. `just outdated` is a dev aid, never a gate.

`just tools::secrets` scans the working tree for secrets; CI runs it in its own
`secrets` job, and it is not in `just check`. `just tools::canibump` reports
the workarounds upstream has fixed; it needs network and stays out of
`just check` too.

Dependabot owns Cargo (one grouped PR) and GitHub Actions, both monthly.
Renovate owns only the Nix flake inputs; #link("renovate.json")[renovate.json]
is inert until the Renovate GitHub App is installed.

= MSRV

`rust-version` in `Cargo.toml` is the minimum supported Rust; CI compiles it in
a separate job. CI also compiles and tests the crate on Windows MSVC; the
release matrix still builds the shipped binaries.

= Mutation testing

`just mutants-diff` sweeps mutants touched by the branch; `just mutants` is a
full sweep. Both are dev aids, never gates; a surviving mutant is an assertion
gap. See the recipe headers.

= Git hooks

The tracked #link(".githooks/pre-commit")[.githooks/pre-commit] first refuses a
path that names this machine's `$HOME` or checkout (`local-paths`), then
asserts gate freshness. `just install-hooks` points git at it, and the dev
shell runs that on entry. Bypass one commit with `git commit --no-verify`.

= Generated docs

The README, AGENTS.md and CONTRIBUTING.md are generated from
`docs/src/*.typ`. Never hand-edit them: edit the source, run `just docs-md`,
and commit the rendered Markdown. `just docs-md-check` fails on any drift and
runs in `just check`.

= Tasks

Task tracking is optional. Generate with `task_tracker = mindtape` to ship
`.mindtape/` and `tasks/`, put `mt` in the dev shell, and add
`just tools::check-tasks` to `just check`; the default `none` has neither and
the arm no-ops.

= Releasing

`just release X.Y.Z --dry-run` first, then without the flag. Keep entries under
`[Unreleased]`; #link("https://github.com/crate-ci/cargo-release")[cargo-release]
(`release.toml`) bumps `Cargo.toml`, dates them and commits. Never
`cargo publish` by hand and never edit the version or the CHANGELOG date
yourself.

The recipe pushes `main`, waits for `ci.yml` on that commit and tags only a
green run; the tag push is the only publish path. A failed release is re-run on
the same tag with `gh workflow run <workflow> -f tag=vX.Y.Z`; a pushed tag
never moves.

In a workspace, `just release` selects the one publishable crate with
`cargo metadata`; every support member sets `publish = false`.

First release only: crates.io attaches a Trusted Publisher only to an existing
crate, so store a scoped `CARGO_REGISTRY_TOKEN` secret for that tag, then add
the publisher and delete the secret.

= Before submitting

1. `just fix-check` — formats, applies clippy fixes, then runs the full gate.
2. `just cover` meets the 70% total and per-file floors; `just crap` is green.
3. Edited a coupled source? Run `just outdatty-update` and commit the lock.
4. Edited a docs source? Run `just docs-md` and commit the rendered Markdown.
