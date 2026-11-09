#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Scan hidden files and the changelog with linecop",
  priority: framework("ice", confidence: 0.9, ease: 8.0, impact: 5.0),
  difficulty: 2,
  estimate: (files: 3),
  status: done(
    2026,
    11,
    9,
  )[include\_hidden is on; BASH/Shell 200, Just 210, Typst 250, CHANGELOG excluded; root .linecop.yaml plus check-docs in root validate.],
  tags: ("template", "tooling", "gating"),
)

= Summary

`template/.linecop.yaml` sets only `Rust: 500` and `Markdown: 200`, `count_mode: total`, and excludes `target` and `archive`. It does not scan hidden directories, so `.just/scripts/*.sh` and `.githooks/*` are unmeasured; it has no shell, Just or Typst limits, no `**/CHANGELOG.md` override, and there is no root `.linecop.yaml` for this repository's own sources.

= Scope

- `template/.linecop.yaml`: add `include_hidden: true`; add BASH/Shell and Just limits (Just <=210 after the Justfile restructure, BASH <=200) and a Typst limit for `docs/src`; add an `overrides` entry excluding `**/CHANGELOG.md`; exclude generated docs output so the cap applies to the source.
- Add a root `.linecop.yaml` for this repo's `tasks/`, `scripts/`, root `Justfile`, `docs/` and workflows. `docs/research/template-sync.md` is 598 lines, so it needs an override or an exclude rather than a raised global cap.
- `template/.mmz/config.yaml`: add the script and docs scopes to `check-file-size` so a cap or source edit re-runs the gate.
- Validate `just check-file-size` in a generated bin and lib, and a hidden script over its limit is reported.

= Dependencies

Take the Just limit after `restructure-the-template-justfile-into-scripts`, and the generated-docs exclusions after `add-the-minimal-generated-docs-pipeline`.
