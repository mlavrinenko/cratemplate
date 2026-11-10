#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Document the flake package's git-dependency limit",
  priority: framework("ice", confidence: 0.9, ease: 8.0, impact: 3.0),
  difficulty: 1,
  estimate: (files: 2),
  status: accepted(2026, 11, 11),
  links: parent("land-the-corrected-renovation-backlog.typ"),
)

= Summary

`template/flake.nix` builds with naersk, which cannot build git dependencies, so `nix build` fails once a generated crate takes one. The install prose also promises a crates.io path that a git dependency makes impossible. Document both limits and keep naersk; do not rewrite the package builder for a case the template does not have.

= Scope

- `template/flake.nix`: at `packages.default = naersk'.buildPackage`, comment that naersk cannot build git dependencies and a crate that takes one needs a different builder.
- `template/docs/src/readme.typ`: in the install section, state that a git dependency makes the crates.io install impossible; keep the binary-release path.
- Do not switch to `buildRustPackage`, add a git dependency, or build and switch builders in this task.

= Notes

The template has no git dependency, so the failure cannot be exercised; the comment and the prose are the whole deliverable.
