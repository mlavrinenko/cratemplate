#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Ignore cargo-mutants output in generated projects",
  priority: framework("ice", confidence: 0.95, ease: 9.0, impact: 4.0),
  difficulty: 1,
  estimate: (files: 1),
  status: done(2026, 10, 10)[validate bin and lib green],
)

= Summary
`just mutants` writes `mutants.out/` (and `mutants.out.old/`) at the project
root, and the template ignores neither, so the next `git add -A` commits
hundreds of files: nix-why-build tracked 434 of them (fdd4424).


= Scope
- `template/.gitignore`: ignore `/mutants.out` and `/mutants.out.old`.

