#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Decide the reference-not-copy flake seam",
  priority: framework("ice", confidence: 0.6, ease: 5.0, impact: 5.0),
  difficulty: 5,
  estimate: (files: 3),
  status: done(2026, 11, 11),
  tags: ("docs", "tooling"),
  links: parent("land-the-corrected-renovation-backlog.typ"),
)

= Summary

`docs/research/template-sync.md` surveys generation, patching, composable flakes and custom CI, and recommends an approach for this Nix + Rust + `just` stack. The repo has not decided which parts become a versioned flake input and which stay copied prose and Justfile bodies, so every downstream sync is ad hoc.

= Scope

- Add `docs/decision/reference-not-copy.md`: classify each `template/` piece as (a) a versioned flake input, (b) a generated file, or (c) a copied prose/Justfile body; name the coupling and the upgrade path for each.
- Cite `docs/research/template-sync.md` in the record; do not rewrite the survey.
- Link the record from the root `README.md` only. Do not link it from `template/CONTRIBUTING.md`: `docs/decision/` is not shipped to generated projects.
- No code and no change to `template/` behavior. Validate only `mt check -q`, `mt fix --check` and `just check-docs`.

= Notes

The decision covers the seam, not the migration: a later task can move one piece at a time once the record says which pieces are candidates.
