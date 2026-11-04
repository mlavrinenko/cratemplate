#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Publish to crates.io through Trusted Publishing",
  priority: framework("ice", confidence: 0.9, ease: 8.0, impact: 7.0),
  difficulty: 2,
  estimate: (files: 4),
  status: done(2026, 11, 5),
  tags: ("ci", "template"),
)

= Summary
Both release workflows publish with `CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_REGISTRY_TOKEN }}`, a repo-level secret that expires. On 2026-10-28 mindtape's release failed at publish because its stored token, set 2026-03-07, had expired: `error: failed to publish mindtape v0.3.0 to registry at https://crates.io ... (status 403 Forbidden): authentication failed`. Every project generated from this template breaks the same way when its token expires. nix-why-build (9743ef71) and mindtape (b958a586) already switched to Trusted Publishing, which mints a short-lived token per run and keeps no secret.

crates.io has no pending publishers, so the first upload cannot use OIDC. The workflows use a scoped token when the secret is present, skip the OIDC exchange, and switch to OIDC once the secret is deleted.

= Scope
- `template/.github/workflows/release.yml` and `template/.github/workflows/release-lib.yml`: the `publish` job, which already has `environment: crates-io`, gets `permissions` of `contents: read` and `id-token: write`. A job-level `HAS_REGISTRY_TOKEN` flag, an `Authenticate with crates.io` step with id `auth` using `rust-lang/crates-io-auth-action@c6f97d42243bad5fab37ca0427f495c86d5b1a18 # v1.0.5` when no token is set, and `CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_REGISTRY_TOKEN || steps.auth.outputs.token }}`.
- `template/.just/scripts/release-hook.sh`: an empty origin has no main yet, so the first release skips the ancestry check and lets the push create main; once origin/main exists the refusal stays.
- `template/AGENTS.md`: the release paragraph says the first release uses a scoped `CARGO_REGISTRY_TOKEN`, then a Trusted Publisher is added and the secret deleted; later tags need no secret.
- `CHANGELOG.md`: an Unreleased entry.
- `just validate bin` and `just validate lib` pass, including a dry run against an empty origin.
- The owner's crates.io step does not apply to cratemplate, which publishes no crate. Each generated project does it for its own crates at https://crates.io/crates/CRATE/settings, under Trusted Publishing, Add, GitHub: owner `mlavrinenko`, its repo, workflow `release.yml` (bin) or `release-lib.yml` (lib), environment `crates-io`. The first release supplies the token secret; after the crate exists, add the publisher, `gh secret delete CARGO_REGISTRY_TOKEN -R mlavrinenko/REPO`, and optionally revoke the token.

= Outcome

- Both release workflows use OIDC when no token is set and fall back to a scoped `CARGO_REGISTRY_TOKEN` for the first publish.
- `template/.just/scripts/release-hook.sh` lets an empty origin create main on the first release.
- `just mmz validate bin` and `just mmz validate lib` pass, including a dry run against an empty origin.
