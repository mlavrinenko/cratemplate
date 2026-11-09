#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Scan for secrets with gitleaks",
  priority: framework("ice", confidence: 0.7, ease: 3.0, impact: 7.0),
  difficulty: 2,
  estimate: (files: 3),
  status: proposed(2026, 11, 9),
  tags: ("template", "ci", "gating"),
)

= Summary

No secret scan exists. A token pasted into a task, a fixture or an `.envrc` reaches history, and the template's `deny` gate only looks at dependency advisories. gitleaks is not in `template/flake.nix`. This is low priority and must not join `just check` by default: a full-history scan is slow and the fixtures contain fake secrets.

= Scope

- `template/flake.nix`: add `gitleaks`.
- `template/.gitleaks.toml` (or `.config/gitleaks.toml`): default rules plus an allowlist for test fixtures and the docs examples.
- `template/.github/workflows/ci.yml`: a separate `secrets` job running a bounded `gitleaks dir .` (or `gitleaks detect --source . --no-git`) so it scans the tree, not full history.
- `template/Justfile`: a `secrets` dev recipe; do not add it to `just check`.
- Validate the job on a clean tree and on a planted fake token, and confirm the allowlist suppresses the known fixture.

= Notes

A history scan belongs to a scheduled job or the release gate, not the per-commit path; the separate CI job keeps the default gate offline and fast.
