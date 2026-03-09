# {{project-name}}

[![CI](https://github.com/{{gh-username}}/{{project-name}}/actions/workflows/ci.yml/badge.svg)](https://github.com/{{gh-username}}/{{project-name}}/actions/workflows/ci.yml)
[![crates.io](https://img.shields.io/crates/v/{{project-name}}.svg)](https://crates.io/crates/{{project-name}})
[![License: {{license}}](https://img.shields.io/crates/l/{{project-name}}.svg)](LICENSE-MIT)

{{description}}

## Install

### From crates.io

```bash
cargo install {{project-name}}
```

### From binary releases

Download a pre-built binary from the
[latest release](https://github.com/{{gh-username}}/{{project-name}}/releases/latest).

## Usage

```bash
{{project-name}}
```

## Development

Prerequisites: [Nix](https://nixos.org/) with flakes enabled.

```bash
direnv allow   # or: nix develop

just check     # fmt + clippy + tests + file-size check
just build
just test
just cover     # code coverage (70% minimum)
just fmt       # format code
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for coding conventions.

## License

{{license}}
