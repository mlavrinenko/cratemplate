# {{project-name}}

{{description}}

## Development

Prerequisites: [Nix](https://nixos.org/) with flakes enabled.

```bash
# Enter dev shell
direnv allow
# or: nix develop

just check # clippy + tests + lines-limit-check
just build
just test
just cover

# Format
just fmt
```

## License

{{license}}
