#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Run mutants under nextest and the workspace",
  priority: framework("ice", confidence: 0.9, ease: 9.0, impact: 5.0),
  difficulty: 1,
  estimate: (files: 3),
  status: done(
    2026,
    11,
    9,
  )[.cargo/mutants.toml sets test\_tool = "nextest", test\_workspace = true and profile = "mutants"; Cargo.toml gains \[profile.mutants\] inheriting dev with debug off.],
  tags: ("template", "tooling"),
)

= Summary

A mutation verdict must use the same runner and workspace as the gate, or a mutant can survive under one execution model while nextest kills it. The working tree at filing already adds `test_tool = "nextest"`, `test_workspace = true` and `profile = "mutants"` to `template/.cargo/mutants.toml`, and `[profile.mutants]` to `template/Cargo.toml`; this task is the validation and landing record.

= Scope

- `template/.cargo/mutants.toml`: keep `test_tool = "nextest"`, `test_workspace = true` and `profile = "mutants"`; keep the crate-kind `exclude_globs`.
- `template/Cargo.toml`: keep `[profile.mutants]` with `inherits = "dev"` and `debug = false`.
- `template/Justfile`: no new flags; `just mutants` and `just mutants-diff` inherit the config.
- Validate a generated bin and lib: `cargo mutants --list` reports the nextest tool and the workspace, and `just validate bin`/`just validate lib` stay green.

= Notes

`--list` proves the configuration without paying for a full mutation run; a full `just mutants` is a dev aid, never a gate.
