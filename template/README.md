<!-- Generated from docs/src/readme.typ by just docs-md. Do not edit; edit the source. -->

# {{project-name}}

<a href="https://github.com/{{gh-username}}/{{project-name}}/actions/workflows/ci.yml"><img src="https://github.com/{{gh-username}}/{{project-name}}/actions/workflows/ci.yml/badge.svg" alt="CI" /></a> <a href="https://crates.io/crates/{{project-name}}"><img src="https://img.shields.io/crates/v/{{project-name}}.svg" alt="crates.io" /></a>

{{description}}

## Install

| **Kind** | **Command** |
| --- | --- |
| Binary | `cargo install {{project-name}}` |
| Library | `cargo add {{crate_name}}` |

## Usage

| **Kind** | **Example** |
| --- | --- |
| Binary | `{{project-name}}` |
| Library | `{{crate_name}}::greet("world")?;` |

## Development

Prerequisites: [Nix](https://nixos.org/) with flakes enabled.

```bash
direnv allow    # or: nix develop
just check      # the full gate
just test       # tests + doctests
just cover      # coverage (70% floor)
```

Run `just` for the rest; see [CONTRIBUTING.md](CONTRIBUTING.md) for conventions.

## License

{{license}}
