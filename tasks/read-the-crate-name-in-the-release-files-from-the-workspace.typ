#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Read the crate name in the release files from the workspace",
  priority: framework("ice", confidence: 0.6, ease: 4.0, impact: 4.0),
  difficulty: 2,
  estimate: (files: 7),
  status: accepted(2026, 11, 11),
  links: parent("land-the-corrected-renovation-backlog.typ"),
)

= Summary

`release-hook.sh`, `release.sh` and both release workflows read the crate name, version and repository from the root `Cargo.toml` with `sed`. A virtual workspace root has no `[package]`, so the release refuses or the workflow fails. The decision is one publishable crate under the virtual workspace root, selected by `cargo metadata`; every support member is `publish = false`.

= Scope

- Add one shared metadata helper (name, version, repository and bin target) under `template/.just/scripts/` and use it from `release-hook.sh`, `release.sh`, `release.yml` and `release-lib.yml` instead of `sed`.
- The selector reads `cargo metadata` and refuses zero or more than one package with `publish` not false. Support members are marked `publish = false`.
- `template/.just/scripts/release.sh`: resolve the package and pass `-p <crate>` to `cargo release`; `release-hook.sh` uses the same name for the crates.io lookup and `cargo publish -p`.
- Both release workflows' `meta` jobs install Rust to run `cargo metadata`, then emit the name, version, repository and binary from the shared helper.
- `scripts/to-workspace.sh` (repo root): mark the extra member `publish = false`.
- Add a workspace `just release --dry-run` test to `scripts/test-workspace.sh` (or the release test script beside it).
- Validate the selector on a root crate and a virtual workspace; the bin and lib gates stay green.

= Notes

The root-package model would need a multi-root gate refactor: jscpd and eject would silently miss a root `src/`. The virtual root plus the strict selector is the trustworthy choice for this template.
