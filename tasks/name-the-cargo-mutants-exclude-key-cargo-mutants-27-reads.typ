#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Name the cargo-mutants exclude key cargo-mutants 27 reads",
  priority: framework("ice", confidence: 0.9, ease: 9.0, impact: 4.0),
  difficulty: 1,
  estimate: (files: 1),
  status: proposed(2026, 10, 10),
)

= Summary
`template/.cargo/mutants.toml` sets `exclude`, which cargo-mutants 27
rejects, so `just mutants` fails in every generated project. nix-why-build
fixed its copy with `exclude_globs` (9119650).


= Scope
- `template/.cargo/mutants.toml`: `exclude` -> `exclude_globs`.

