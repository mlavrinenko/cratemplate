#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Slim the template docs by bytes",
  priority: framework("ice", confidence: 0.9, ease: 7.0, impact: 7.0),
  difficulty: 3,
  estimate: (files: 5),
  status: done(
    2026,
    11,
    9,
  )[generated AGENTS 17 lines/2.3 KB, CONTRIBUTING 96 lines/6.7 KB, README 38 lines/1.1 KB; root README 51 lines.],
  tags: ("template", "docs"),
)

= Summary

Measured at filing on 2026-11-09: `template/AGENTS.md` is 90 lines / 2.0 KB, `template/CONTRIBUTING.md` is 215 lines / 4.9 KB, `template/README.md` is 64 lines / 1.4 KB, and root `README.md` is 89 lines / 2.1 KB. They repeat gate, coverage, release and landing rationale that now lives in recipe and script comments. Keep only rules used in almost every session or whose omission causes a very bad outcome.

= Scope

- `template/AGENTS.md` -> 35-45 lines (6 KB ceiling): `just fix-check`, the one integration binary under `tests/it/`, the mmz arm rule, the outdatty lock, output discipline (`chronic`/`grep`), release, fork/land, and never dodge a gate. Drop per-tool rationale.
- `template/CONTRIBUTING.md` -> 110-130 lines (9 KB ceiling): code style, error handling, layout, testing, coverage floor, CRAP, file sizes, drift, memoized gates, release, mutation, hooks.
- `template/README.md` -> 45-60 lines; root `README.md` -> 50-55 lines.
- Move long gate/coverage/release/landing rationale into the `.just/scripts/` headers created by the Justfile restructure, or into future docs sources.
- Do not create docs files yet; the generated-docs task owns the source layout.
- Do not edit `template/.linecop.yaml`; the linecop task owns the caps.
- Leave the existing crate-kind Liquid conditionals in place until the generated-docs task moves them.
- Validate `just fix-check` in a generated bin and lib; linecop still passes.

= Dependencies

Land `restructure-the-template-justfile-into-scripts` first so the moved script headers exist to receive the rationale.
