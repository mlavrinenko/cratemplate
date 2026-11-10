#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Land the corrected renovation backlog",
  priority: framework("ice", confidence: 1.0, ease: 8.0, impact: 10.0),
  difficulty: 6,
  estimate: (files: 15),
  kind: "umbrella",
  status: wip(2026, 11, 11),
  tags: ("tooling", "gating"),
)

= Summary

The renovation backlog was filed against tools the template did not yet ship. This umbrella lands the 13 corrected children on the qahq pin in `template/flake.nix`: commit `58f9ec9` (template commit `c3404c1`), which carries canibump, mindtape 0.5.0, jscpd 5.4.1, cargo-crap 0.3.1, linecop 0.8.1, outdatty 0.10.0 and mmz 0.15.1. No child adds a flake input for a tool the pin already carries.

= Scope

- Wave 1, tool plumbing: `format-nix-files-with-nixfmt`, `track-upstream-workarounds-with-canibump`, `scan-for-secrets-with-gitleaks`.
- Wave 2, gate shape: `add-a-crap-ratchet-baseline`, `merge-the-crap-baseline-across-lanes`, `tune-jscpd-and-add-a-clone-baseline`, `add-a-staged-just-check-verdict`, `check-the-template-on-windows`.
- Wave 3, generated projects: `offer-optional-mindtape-in-generated-projects`, `read-the-crate-name-in-the-release-files-from-the-workspace`.
- Wave 4, prose: `build-the-flake-package-when-a-crate-has-git-dependencies`, `ship-a-generated-json-schema-for-every-config-a-crate-reads`, `decide-the-reference-not-copy-flake-seam`.
- Keep the default gate offline and fast: canibump, gitleaks and the tracker check are on demand or conditional, as each child states.

= Notes

The qahq pin is already landed, so no child depends on it. Each child is accepted on its own and may land in any order inside its wave. `add-a-staged-just-check-verdict` waits for the four gates that decide its batches.
