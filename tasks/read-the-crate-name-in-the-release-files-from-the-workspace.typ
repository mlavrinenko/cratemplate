#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Read the crate name in the release files from the workspace",
  priority: framework("ice", confidence: 0.6, ease: 4.0, impact: 4.0),
  difficulty: 2,
  estimate: (files: 3),
  status: proposed(2026, 10, 23),
)

= Summary
`release-hook.sh`, `release.yml` and `release-lib.yml` read the crate name, version and repository from the root `Cargo.toml` with `sed`. In a workspace with a virtual root manifest there is none, so the release refuses or the workflow fails. Found porting corpuspeak's workspace layout; deliberately out of scope for the gates task.


= Scope
- Do not implement until the release model is decided (see Notes).
- `template/.just/scripts/release-hook.sh`: name the published crate without the root `[package]`.
- `template/.github/workflows/release.yml`, `template/.github/workflows/release-lib.yml`: the same.
- `just validate` releases a workspace project as well.

= Notes
The release model comes first: one publishable crate at the workspace root, or every member published separately. If the template keeps one publishable crate, reading the root manifest can stay and this task closes. If every member publishes, the hook and both workflows need a member list and per-member versions, which is a larger change than the `sed` fix this task names.
