# {{project-name}}

{{description}}

## Development

Prerequisites: [Nix](https://nixos.org/) with flakes enabled.

```bash
# Enter dev shell
direnv allow
# or: nix develop

# Run checks (clippy + tests + file size limits)
just check

# Build
just build

# Run tests
just test

# Code coverage
just cover

# Format
just fmt
```

## License

{{license}}
