#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Publish to crates.io through Trusted Publishing",
  priority: framework("ice", confidence: 0.9, ease: 8.0, impact: 7.0),
  difficulty: 2,
  estimate: (files: 4),
  status: proposed(2026, 10, 28),
  tags: ("ci", "template"),
)

= Summary
Both release workflows publish with `CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_REGISTRY_TOKEN }}`, a repo-level secret that expires. On 2026-10-28 mindtape's release failed at publish because its stored token, set 2026-03-07, had expired: `error: failed to publish mindtape v0.3.0 to registry at https://crates.io ... (status 403 Forbidden): authentication failed`. Every project generated from this template breaks the same way when its token expires. nix-why-build (9743ef71) and mindtape (b958a586) already switched to Trusted Publishing, which mints a short-lived token per run and keeps no secret.

= Scope
- `template/.github/workflows/release.yml` and `template/.github/workflows/release-lib.yml`: the `publish` job, which already has `environment: crates-io`, gets `permissions` of `contents: read` and `id-token: write`. A step after the toolchain, `Authenticate with crates.io` with id `auth`, uses `rust-lang/crates-io-auth-action@c6f97d42243bad5fab37ca0427f495c86d5b1a18 # v1.0.5`. The publish step sets `CARGO_REGISTRY_TOKEN: ${{ steps.auth.outputs.token }}`, and `secrets.CARGO_REGISTRY_TOKEN` goes.
- `template/AGENTS.md`: the release paragraph says each published crate needs a Trusted Publisher on crates.io (owner, repo, workflow file name, environment `crates-io`) before its first tag, and that no secret is set.
- `CHANGELOG.md`: an Unreleased entry.
- `just validate bin` and `just validate lib` pass.
- The owner's crates.io step does not apply to cratemplate, which publishes no crate. Each generated project does it for its own crates at https://crates.io/crates/CRATE/settings, under Trusted Publishing, Add, GitHub: owner `mlavrinenko`, its repo, workflow `release.yml` (bin) or `release-lib.yml` (lib), environment `crates-io`. After the first green publish, `gh secret delete CARGO_REGISTRY_TOKEN -R mlavrinenko/REPO` and optionally revoke the token.
