#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Build the flake package when a crate has git dependencies",
  priority: framework("ice", confidence: 0.9, ease: 8.0, impact: 3.0),
  difficulty: 1,
  estimate: (files: 2),
  status: proposed(2026, 10, 10),
)

= Summary
`template/flake.nix` builds with naersk, which cannot build git dependencies,
so `nix build` fails once a crate takes one; the README also promises a
crates.io install that a git dependency makes impossible. nix-why-build
switched to `buildRustPackage` (a344cd5). The decision here is the opposite:
document both limits and keep naersk, because switching the package builder
for a case the template does not yet have would rewrite the build for every
project.

= Scope
- `template/flake.nix`: add a comment at `packages.default = naersk'.buildPackage`
  saying naersk cannot build git dependencies and a crate that takes one needs
  a different builder.
- `template/README.md` (or `docs/src/readme.typ` after the docs pipeline): in
  the install section, state that a git dependency makes the crates.io install
  impossible; keep the binary-release path.
- Do not switch to `buildRustPackage` and do not add a git dependency.
- Validate a generated bin and lib still pass `nix build .#default`; the
  git-dependency failure cannot be exercised without taking one.
