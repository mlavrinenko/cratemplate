#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Convert CONTRIBUTING and README to generated docs",
  priority: framework("ice", confidence: 0.7, ease: 5.0, impact: 5.0),
  difficulty: 5,
  estimate: (files: 7),
  status: done(
    2026,
    11,
    9,
  )[template CONTRIBUTING and README render from docs/src/{contributing,readme}.typ; docs-md-check keeps the committed Markdown and the sources in step, and both pass in generated bins and libs.],
  tags: ("template", "docs"),
)

= Summary

After the AGENTS pipeline and the docs slimming, the two remaining prose files still carry Liquid conditionals and crate-kind branches. Generated docs need variant-neutral prose and only simple placeholders, so `template/CONTRIBUTING.md` and `template/README.md` become Typst sources rendered to the same committed Markdown.

= Scope

- `template/docs/src/contributing.typ` and `template/docs/src/readme.typ`: move the content from `template/CONTRIBUTING.md` and `template/README.md`; use simple placeholders only (`{{project-name}}`, `{{gh-username}}`, `{{license}}`, `{{description}}`, `{{crate_name}}`).
- Do not use Liquid control flow (`{% if %}`, `{{crate_kind}}`) inside the Typst sources; write prose that is true for both a bin and a lib, or move the variant-specific line to a non-generated file.
- `template/docs/generate-md.sh` and the `docs-md-check` inputs: add both targets.
- `template/outdatty.yaml`: replace the Markdown sources/dependents with the generated files; keep `docs/src/**` coupled to them.
- `template/.linecop.yaml`: cap the Typst sources, not the generated Markdown.
- Validate `just docs-md-check`, `just check`, and `just validate bin`/`just validate lib`.

= Dependencies

Land `add-the-minimal-generated-docs-pipeline` and `slim-the-template-docs-by-bytes` first.

= Notes

If a sentence genuinely differs between a bin and a lib, the neutral form names both outcomes in one sentence rather than reintroducing Liquid.
