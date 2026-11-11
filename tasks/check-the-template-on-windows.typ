#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Check the template on Windows",
  priority: framework("ice", confidence: 0.7, ease: 5.0, impact: 5.0),
  difficulty: 4,
  estimate: (files: 3),
  status: done(2026, 11, 11),
  tags: ("template", "ci", "gating"),
  links: parent("land-the-corrected-renovation-backlog.typ"),
)

= Summary

The release matrix builds `x86_64-pc-windows-msvc` on `windows-latest` only at tag time, so a broken Windows build is found after the version is decided. Add a Windows MSVC job to ordinary CI; a local cross-check is optional and must not add a devShell or toolchain trade-off.

= Scope

- `template/.github/workflows/ci.yml`: add a `windows` job on `windows-latest` with `dtolnay/rust-toolchain`, running `cargo check --workspace --all-targets` and then `cargo test --no-run`. Do not pass `--locked`: a fresh project need not commit `Cargo.lock`.
- Ship a local `check-windows` recipe only if a `pkgsCross.mingwW64` or `cargo xwin` spike works with no devShell or toolchain trade-off. The recipe is optional; if it ships, comment that MinGW is early feedback, not the MSVC release build.
- Do not ship `devShells.windows` unless a spike proves it, and leave `devShells.default` unchanged.
- Keep the release matrix as the source of truth for binaries.
- Validate the workflow with `just lint::workflows`; the Windows job itself runs on GitHub.

= Notes

The local cross target and the MSVC release target link differently, so a green cross-check must not be read as a green Windows release.
