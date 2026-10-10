#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Build the flake package when a crate has git dependencies",
  priority: framework("ice", confidence: 0.7, ease: 6.0, impact: 4.0),
  difficulty: 3,
  estimate: (files: 2),
  status: proposed(2026, 10, 10),
)

= Summary
`template/flake.nix` builds with naersk, which cannot build git dependencies,
so `nix build` fails once a crate takes one; the README also promises a
crates.io install that a git dependency makes impossible. nix-why-build
switched to `buildRustPackage` (354377b).


= Scope
- `template/flake.nix`: build with `buildRustPackage` (or keep naersk and document the limit).
- `template/README.md`: keep the crates.io install section true.

