#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Decide the reference-not-copy flake seam",
  priority: framework("ice", confidence: 0.6, ease: 5.0, impact: 5.0),
  difficulty: 5,
  estimate: (files: 2),
  status: proposed(2026, 11, 9),
  tags: ("docs", "tooling"),
)

= Summary

`docs/research/template-sync.md` surveys generation, patching, composable flakes and custom CI, and recommends an approach for this Nix + Rust + `just` stack. The repo has not decided which parts become a versioned flake input and which stay copied prose and Justfile bodies. Without that line, every downstream sync is ad hoc and the template grows one fork per project.

= Scope

- Add `docs/decision/reference-not-copy.md`: a decision record classifying each `template/` piece as (a) a versioned flake input, (b) a generated file, or (c) a copied prose/Justfile body; name the coupling and the upgrade path for each.
- `docs/research/template-sync.md`: cite the relevant recommendations; do not rewrite the survey.
- `README.md`/`template/CONTRIBUTING.md`: link the record once it lands, after the docs slimming task.
- No code and no change to `template/` behavior in this task.

= Notes

The decision covers the seam, not the migration: a later task can move one piece at a time once the record says which pieces are candidates. Task files are outside the template gate, so the only validation is `mt check -q` and `mt fix --check`.
