// docs/src/lib.typ — shared helpers for the docs sources that
// docs/generate-md.sh renders with typlite. This file is not a source: it
// carries no <docs-md> block, so the generator skips it.
//
// typlite shifts `=` to `##` and `==` to `###`; it cannot emit a bare `#`.
// `doc-title` goes through html.elem("h1"), the one form typlite keeps, and
// the generator demotes that leading <h1> line back to an ATX `#`.
//
// Constraints worth knowing before adding a source:
//   - plain `[text](path)` is escaped; write #link("path")[text];
//   - Markdown image syntax is escaped too; use the `badge` helper;
//   - never break a backtick span across a source line — typlite emits the
//     newline literally and corrupts the Markdown;
//   - `@` can be read as a citation; escape it as `\@` in prose;
//   - Markdown emphasis (`**bold**`, `__bold__`) is not Typst emphasis:
//     write *bold* or _italic_, or typlite doubles the markers;
//   - a placeholder with an underscore (`{{crate_name}}`) is escaped in prose,
//     so keep it inside a code span or a raw block.
//
// No external packages: the dev shell's typst and tinymist are the whole
// toolchain.
#let doc-title(body) = html.elem("h1")[#body]

// Simple cargo-generate placeholders. typlite preserves these forms; the
// underscore one is only safe inside raw (see above).
#let project = "{{project-name}}"
#let gh-user = "{{gh-username}}"
#let description = "{{description}}"
#let license = "{{license}}"

// One Markdown table per call: bold header cells, then the body rows.
#let doc-table(header, rows) = table(
  columns: header.len(),
  align: left,
  ..header.map(h => strong(h)),
  ..rows.flatten(),
)

// An HTML badge: typlite escapes Markdown image syntax, so emit the anchor
// and image elements directly.
#let badge(href, src, alt) = html.elem("a", attrs: (href: href))[
  #html.elem("img", attrs: (src: src, alt: alt))
]
