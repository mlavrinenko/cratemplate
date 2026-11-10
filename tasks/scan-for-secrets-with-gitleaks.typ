#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Scan for secrets with gitleaks",
  priority: framework("ice", confidence: 0.7, ease: 3.0, impact: 7.0),
  difficulty: 2,
  estimate: (files: 5),
  status: accepted(2026, 11, 11),
  tags: ("template", "ci", "gating"),
  links: parent("land-the-corrected-renovation-backlog.typ"),
)

= Summary

No secret scan exists. A token pasted into a task, a fixture or an `.envrc` reaches history, and the `deny` gate only looks at dependency advisories. gitleaks is in nixpkgs. Keep the scan off the default gate: a full scan is slow and the fixtures contain fake secrets.

= Scope

- `template/flake.nix`: add `gitleaks` to the dev shell.
- `template/.gitleaks.toml`: default rules plus an allowlist for test fixtures and the docs examples.
- `template/.just/tools.just`: add `tools::secrets`, running `gitleaks dir .` over the tree, not full history. It is on demand and is not in `just check`.
- `template/.github/workflows/ci.yml`: add a separate `secrets` job running `nix develop --command just tools::secrets`.
- Validate a clean tree, a planted fake token, and a fixture the allowlist suppresses.

= Notes

A history scan belongs to a scheduled job or the release gate, not the per-commit path; the separate CI job keeps the default gate offline and fast.
