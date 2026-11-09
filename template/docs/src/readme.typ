// docs/src/readme.typ — source for the generated README.md at the repo root.
// `just docs-md` reads the <docs-md> block below, renders this file with
// typlite, and writes the declared output; never hand-edit README.md.
//
// Variant-neutral: the install and usage tables name both kinds, so the source
// carries no Liquid control flow and no `crate_kind` placeholder.
#import "lib.typ": (
  badge, description, doc-table, doc-title, gh-user, license, project,
)

#metadata((
  output: "README.md",
)) <docs-md>

#doc-title[#project]

#badge(
  "https://github.com/" + gh-user + "/" + project + "/actions/workflows/ci.yml",
  "https://github.com/"
    + gh-user
    + "/"
    + project
    + "/actions/workflows/ci.yml/badge.svg",
  "CI",
)
#badge(
  "https://crates.io/crates/" + project,
  "https://img.shields.io/crates/v/" + project + ".svg",
  "crates.io",
)

#description

= Install

#doc-table(
  ([Kind], [Command]),
  (
    ([Binary], [`cargo install {{project-name}}`]),
    ([Library], [`cargo add {{crate_name}}`]),
  ),
)

= Usage

#doc-table(
  ([Kind], [Example]),
  (
    ([Binary], [`{{project-name}}`]),
    ([Library], [`{{crate_name}}::greet("world")?;`]),
  ),
)

= Development

Prerequisites: #link("https://nixos.org/")[Nix] with flakes enabled.

```bash
direnv allow    # or: nix develop
just check      # the full gate
just test       # tests + doctests
just cover      # coverage (70% floor)
```

Run `just` for the rest; see #link("CONTRIBUTING.md")[CONTRIBUTING.md] for
conventions.

= License

#license
