#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Add the minimal generated docs pipeline",
  priority: framework("ice", confidence: 0.6, ease: 4.0, impact: 5.0),
  difficulty: 5,
  estimate: (files: 11),
  status: done(
    2026,
    11,
    9,
  )[docs/src/{lib,agents,contributing,readme}.typ render through docs/generate-md.sh --check into committed Markdown; typst/tinymist/typstyle in the dev shell, a docs-md-check gate, and root docs-sync/docs-check. Variant-neutral; template and generated bin/lib all pass.],
  tags: ("template", "docs", "tooling", "gating"),
)

= Summary

MindTape's docs approach is Typst source rendered to committed Markdown with typlite. The template has no `docs/` directory, `template/flake.nix` ships neither `typst` nor `tinymist`, and its prose is Liquid-templated Markdown, so variant logic and placeholders are entangled with the output. Ship only the AGENTS pipeline first, variant-neutral, and leave out `docs/project.json`, `tina`, `yq`, `gates.jq` and a docs site.

= Scope

- `template/docs/src/lib.typ`: helpers for the banner and shared metadata; `template/docs/src/agents.typ` with `<docs-md>` metadata on the block to export.
- `template/docs/generate-md.sh`: render with `typst eval 'query(<docs-md>).map(it => it.value)' --target html --features html` (not the deprecated `typst query`), pipe the result through `typlite`, and write the committed Markdown with a generated-file banner. `--check` renders to a temp file and diffs.
- Add `typst` and `tinymist` to the `template/flake.nix` dev shell.
- `template/Justfile`: `docs-md` and `docs-md-check` top-level recipes; add `(mmz "docs-md-check")` to `check`, with a `gate`-tagged rule and docs scopes in `template/.mmz/config.yaml`.
- `template/outdatty.yaml`: couple the docs source to the generated file; `template/.linecop.yaml`: cap the Typst source, not the generated Markdown output.
- Keep placeholders simple (`{{project-name}}`, `{{gh-username}}`, `{{license}}`, `{{description}}`); typlite corrupts `{{crate_kind}}` and `{% if %}`.
- Keep `.config/wt.toml` excluded from Liquid in `template/cargo-generate.toml`.
- Root `Justfile`: replace the README-filler regression (lines 110-122 at filing; it moved to `scripts/validate.sh` with the validate split) with an untracked near-limit fixture so generated docs cannot break `just fix-check`.
- Validate `just docs-md-check`, a clean `just check`, and `just validate bin`/`just validate lib`.

= Dependencies

The README-filler regression moves to `scripts/validate.sh` with `split-the-root-validate-into-scripts`; land that first or edit the script in place.

= Notes

The generated Markdown is the reviewed artifact; the Typst source is what linecop measures. A missing `typlite` must fail the recipe loudly, not leave a stale Markdown file.
