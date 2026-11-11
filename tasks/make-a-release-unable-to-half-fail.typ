#import "@local/mindtape:0.2.0": *

#show: task.with(
  title: "Make a release unable to half-fail",
  priority: framework("ice", confidence: 0.9, ease: 6.0, impact: 8.0),
  difficulty: 3,
  estimate: (files: 6),
  tags: ("ci", "template"),
  status: done(2026, 10, 7)[both validates green; adopted downstream],
)

= Summary

Four tags of projects built from this template went red in their release
workflow: outdatty v0.6.0, typst-world v0.4.0, typst-harvest v0.4.0 and
mindtape v0.2.0. Each version had been published by hand before the tag was
pushed, so the tag's `cargo publish` failed on "already exists"; for a binary
crate the GitHub release, which waits on publish, never happened. typst-world
v0.3.2 went red at its check job on a transient nix fetch error and was then
published by hand too. Nothing in the workflow could finish the release on the
same tag, and nothing in `just release` stopped a tag that could not succeed.

= Scope

- Both release workflows skip `cargo publish` when crates.io has the version,
  and stop on any crates.io answer other than 200 or 404.
- Both run again on an existing tag through `workflow_dispatch` with a `tag`
  input; every job checks out that tag; one run per tag at a time.
- The bin workflow names the release's tag explicitly, updates an existing
  release in place, and gives "Latest" only to the highest tag.
- `just release X.Y.Z [--dry-run]` refuses, with an `error:` and a `hint:`
  line, before tagging: a non-semver version, a `Cargo.toml` mismatch, a dirty
  tree, a branch other than main, main differing from origin/main, an existing
  local or remote tag, a version on crates.io, no dated CHANGELOG section, a
  HEAD without green `ci.yml`, stale gates, a failing `cargo publish --dry-run`.
- `just mmz validate bin` and `just mmz validate lib` pass.

= Outcome

- Commit 5cdf393. `just mmz validate bin` and `just mmz validate lib` pass,
  and both now assert that `just release` refuses a version `Cargo.toml` does
  not carry and an uncommitted tree, leaving no tag.
- The hardened workflow and recipe were adopted by outdatty, typst-world,
  typst-harvest, typst-cst, typst-edit, typst-cleanup, artifact-gate,
  swhid-mint, and mindtape on its release-pipeline branch; outdatty v0.6.0
  was finished with `gh workflow run release.yml -f tag=v0.6.0`.
