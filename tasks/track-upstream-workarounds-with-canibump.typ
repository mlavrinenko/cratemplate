#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Track upstream workarounds with canibump",
  priority: framework("ice", confidence: 0.8, ease: 3.0, impact: 8.0),
  difficulty: 2,
  estimate: (files: 4),
  status: proposed(2026, 11, 9),
  tags: ("template", "tooling"),
)

= Summary

The template carries workarounds but nothing records when upstream fixes them: naersk cannot build git dependencies, the nixpkgs cargo-generate 0.25 lacks its `git` feature so `validate` runs `git init`, and nixpkgs' rustc ships no `llvm-tools-preview` so the shell exports `LLVM_COV`/`LLVM_PROFDATA`. Without a record, the workarounds outlive their cause. canibump exits 9 on a finding, not a tool failure; qahq is already a flake input.

= Scope

- Add `template/.config/canibump.toml` seeded only with real workarounds and the upstream issue/PR plus the condition to remove each; start with the three above.
- `template/flake.nix`: add canibump from the existing `qahq` input to the dev shell.
- `template/Justfile` (or `.just/scripts/canibump.sh`): `just canibump` prints findings and fails the gate when a workaround is still needed; exit 9 is a finding, any other non-zero is a tool failure.
- `template/.mmz/config.yaml`: add a rule only if canibump joins `just check`; it needs network, so keep it out of the default gate and run it in its own CI job or on demand.
- Validate a seeded entry is reported and a clean entry is silent in a generated bin and lib.

= Notes

A workaround entry must name the upstream condition, not just the symptom. "Remove when naersk supports git dependencies" is checkable; "nix is weird" is not.
