# {{project-name}}

[![CI](https://github.com/{{gh-username}}/{{project-name}}/actions/workflows/ci.yml/badge.svg)](https://github.com/{{gh-username}}/{{project-name}}/actions/workflows/ci.yml)
[![crates.io](https://img.shields.io/crates/v/{{project-name}}.svg)](https://crates.io/crates/{{project-name}})
[![License: {{license}}](https://img.shields.io/crates/l/{{project-name}}.svg)](LICENSE-MIT)

{{description}}

## Install
{%- if crate_kind == "bin" %}

### From crates.io

```bash
cargo install {{project-name}}
```

### From binary releases

Download a pre-built binary from the
[latest release](https://github.com/{{gh-username}}/{{project-name}}/releases/latest).
{%- endif %}
{%- if crate_kind == "lib" %}

```bash
cargo add {{crate_name}}
```
{%- endif %}

## Usage
{%- if crate_kind == "bin" %}

```bash
{{project-name}}
```
{%- endif %}
{%- if crate_kind == "lib" %}

```rust
{{crate_name}}::greet("world")?;
```
{%- endif %}

## Development

Prerequisites: [Nix](https://nixos.org/) with flakes enabled.

```bash
direnv allow         # or: nix develop
just install-hooks   # pre-commit hook running the (memoized) gate

just check           # fmt + clippy + tests + file-size + drift check
just build
just test
just cover           # code coverage (70% minimum)
just fmt             # format code
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for coding conventions.

## License

{{license}}
