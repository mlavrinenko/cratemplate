#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Automate Cargo and flake input updates",
  priority: framework("ice", confidence: 0.8, ease: 5.0, impact: 8.0),
  difficulty: 2,
  estimate: (files: 3),
  status: done(
    2026,
    11,
    9,
  )[Dependabot groups Cargo and covers GitHub Actions monthly; Renovate enables only the Nix manager for flake.lock and needs the Renovate app installed.],
  tags: ("template", "ci", "tooling"),
)

= Summary

Both `.github/dependabot.yml` files update only `github-actions`. `Cargo.toml`/`Cargo.lock` and `flake.lock` are updated by hand, even though the template teaches pinned actions and keeps a validated toolchain in `flake.lock`. Add a Cargo updater and a flake lock strategy, or document why neither is automatic.

= Scope

- `template/.github/dependabot.yml` and root `.github/dependabot.yml`: add a `cargo` ecosystem at `/`, grouped for dependencies/dev-dependencies, monthly, with the same `ci` commit-message prefix as the actions updater.
- `flake.lock`: either add Renovate (`renovate.json` with the `nix` manager and `lockFileMaintenance`) or document in `template/CONTRIBUTING.md` that `nix flake update` is deliberate and Dependabot cannot do it.
- Keep action pins SHA-based; do not let an updater unpin them.
- Validate the Dependabot/Renovate config parses, and `just validate bin`/`just validate lib` stay green.

= Notes

A grouped Cargo PR is one reviewable bump; an ungrouped one is a week of noise. If Renovate is chosen, its flake lock PR still needs the same `just validate bin`/`lib` gate as a manual bump.
