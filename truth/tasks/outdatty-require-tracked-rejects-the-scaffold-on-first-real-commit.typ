#import "@local/mindtape:0.2.0": *

#show: task.with(
  title: "outdatty require_tracked rejects the scaffold on first real commit",
  priority: framework("ice", confidence: 0.9, ease: 8.0, impact: 7.0),
  difficulty: 2,
  estimate: (files: 2),
  status: proposed(2026, 8, 16),
)

= Summary

`outdatty check` defaults `require_tracked` to `["**"]`, so every file git
tracks must belong to some group's `source` or `dependents`. The generated
scaffold ships ~31 files in no group (`.envrc`, `.githooks/`, `.github/`,
`clippy.toml`, `deny.toml`, `rustfmt.toml`, `rust-toolchain.toml`,
`LICENSE-MIT`, `Cargo.lock`, `flake.lock`, ...), so `just check` fails on
`outdatty-check` the first time a project runs the gate for real — with an
`[untracked] N file(s) covered by no group` report that reads nothing like
the doc-drift failure the gate exists to catch.

It also fires for every new source module: a crate that grows past
`src/lib.rs` and `src/main.rs` trips it again on each added file.

Fix by shipping an explicit `require_tracked` in the template's
`outdatty.yaml`, listing only what carries hand-written coupling. Observed in
tank03-rgb, which settled on:

```yaml
require_tracked:
  - "src/**"
  - "docs/**"
  - "www/**"
  - "README.md"
  - "CHANGELOG.md"
  - "CONTRIBUTING.md"
  - "AGENTS.md"
  - "Cargo.toml"
  - "Justfile"
  - "flake.nix"
```

Worth pairing with a comment in the generated manifest saying a new module
needs adding to a group, since the failure message does not suggest it.
