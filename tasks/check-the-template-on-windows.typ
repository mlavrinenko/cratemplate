#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Check the template on Windows",
  priority: framework("ice", confidence: 0.7, ease: 5.0, impact: 5.0),
  difficulty: 4,
  estimate: (files: 5),
  status: proposed(2026, 11, 9),
  tags: ("template", "ci", "gating"),
)

= Summary

The release matrix in `template/.github/workflows/release.yml:93-109` builds `x86_64-pc-windows-msvc` on `windows-latest`, so Windows is only tested at tag time; a broken Windows build is found after the version is decided. `template/flake.nix` has only `devShells.default`, and there is no `check-windows` recipe.

= Scope

- `template/flake.nix`: add `devShells.windows` from `pkgsCross.mingwW64` with the Rust target and linker environment, leaving `devShells.default` unchanged.
- `template/Justfile` (or `.just/scripts/check-windows.sh`): `check-windows` runs `cargo check --workspace --all-targets --target x86_64-pc-windows-gnu` in that shell; pass the target explicitly so a host without the target fails loudly.
- `template/.github/workflows/ci.yml`: add a `windows` job using `dtolnay/rust-toolchain` with the target and `cargo check`/`cargo test --no-run`; keep the release matrix as the source of truth for binaries.
- Validate the cross check on Linux and leave `just validate bin`/`just validate lib` green.

= Notes

A MinGW cross-check is early feedback, not a replacement for the msvc release build: the two targets link differently. Say so in the recipe comment so a green `check-windows` is not read as a green Windows release.
