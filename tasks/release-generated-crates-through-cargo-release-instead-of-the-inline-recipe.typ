#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Release generated crates through cargo-release instead of the inline recipe",
  priority: framework("ice", confidence: 0.8, ease: 5.0, impact: 6.0),
  difficulty: 3,
  estimate: (files: 6),
  status: proposed(2026, 10, 11),
)

= Summary
`template/Justfile`'s `release` recipe is about 95 lines, copied into every generated crate. It refuses unless Cargo.toml was already bumped and CHANGELOG.md already dated by hand. mindtape replaced the same recipe with cargo-release on 2026-10-11 (commits c914a88b and 14580544 in ~/projects/home/mindtape, task `release-through-cargo-release-instead-of-a-hand-rolled-script`), and `just release 0.3.0 --dry-run` passed there.

cargo-release fits a hand-curated Keep a Changelog file. `pre-release-replacements` dates `## [Unreleased]` as `## [X.Y.Z] - {{date}}`. `pre-release-hook` takes the checks it lacks: origin ahead, existing tag, version on crates.io, gate freshness, `cargo publish --dry-run`. Its step subcommands (`version replace hook commit`, then `tag push`) keep the order of push main, wait for ci.yml, then tag. release-plz lost because it regenerates the changelog from commits.


= Scope
- `template/release.toml`: new, from mindtape's. `publish = false`, because `template/.github/workflows/release.yml` publishes on the tag. The replacement must handle a CHANGELOG with no version link lines yet, as a fresh crate has.
- `template/.just/scripts/release-hook.sh`: from mindtape's, keeping every refusal and hint of today's recipe.
- `template/Justfile`: `release VERSION $DRY_RUN=''`, built on the cargo-release steps.
- `template/flake.nix`: `cargo-release` in the dev shell.
- `template/AGENTS.md`, `template/CONTRIBUTING.md`: how releasing works.
- `just validate bin` and `just validate lib` pass, and a generated crate's `just release 0.1.0 --dry-run` passes.

