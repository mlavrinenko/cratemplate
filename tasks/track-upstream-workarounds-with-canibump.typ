#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Track upstream workarounds with canibump",
  priority: framework("ice", confidence: 0.8, ease: 3.0, impact: 8.0),
  difficulty: 2,
  estimate: (files: 4),
  status: accepted(2026, 11, 11),
  tags: ("template", "tooling"),
  links: parent("land-the-corrected-renovation-backlog.typ"),
)

= Summary

The template carries workarounds but nothing records when upstream fixes them: naersk cannot build git dependencies, the nixpkgs cargo-generate 0.25 lacks its `git` feature so `validate` runs `git init`, and nixpkgs' rustc ships no `llvm-tools-preview` so the shell exports `LLVM_COV`/`LLVM_PROFDATA`. qahq now packages canibump, so use the existing pin; no new flake input.

= Scope

- `template/flake.nix`: add `qahq.packages.${system}.canibump` to the dev shell.
- Add `template/.config/canibump.toml` with `[settings] fail-on = ["bumpable"]`. Exit 9 is the only finding; 0 is clean; any other non-zero is a tool failure.
- Seed only workarounds with checkable upstream issue/PR/package state. Start from the three candidates above; leave one out and say so in the file if it has no checkable state. Never file an upstream issue.
- `template/.just/tools.just`: add `tools::canibump` on demand. It needs network, so it is not in `just check` and has no `gate` rule.
- Validate a seeded entry is reported with exit 9 and a clean entry is silent with exit 0, in a generated bin and lib.

= Notes

A workaround entry must name the upstream condition, not just the symptom. "Remove when naersk supports git dependencies" is checkable; "nix is weird" is not.
