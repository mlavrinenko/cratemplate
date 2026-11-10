<!-- Generated from docs/src/agents.typ by just docs-md. Do not edit; edit the source. -->

# {{project-name}}

## Agent Rules

- Use the [Justfile](Justfile) for every repeatable operation. `set shell` gives each recipe line `bash -eo pipefail`, so no `#!/usr/bin/env bash` preamble is needed; add a shebang only when one shell must span lines (a variable read later, a `trap`).
- Finish with `just fix-check` green.
- Tests: inline `#[cfg(test)]` units beside the code; integration tests in `tests/it/` as one binary — a new file is `tests/it/<name>.rs` plus `mod <name>;` in `tests/it/main.rs` (create it with the first one), never a top-level `tests/<name>.rs`. `just fix-check` ejects inline tests from oversized files.
- Any config a crate reads ships a JSON schema generated from the crate’s types with `schemars`, never hand-written. Commit the schema beside the config and add a test that fails when the committed copy drifts; follow canibump’s shape.
- Every arm of `just check` is `just mmz <subgate>`. A new or renamed gate needs its rule in [.mmz/config.yaml](.mmz/config.yaml). An unmatched invocation is a hard error, not a silent skip.
- [outdatty.yaml](outdatty.yaml) couples sources to dependents. On drift, update the listed dependents, run `just outdatty-update`, and commit the refreshed `outdatty.lock`.
- Never hand-edit [README.md](README.md), [AGENTS.md](AGENTS.md) or [CONTRIBUTING.md](CONTRIBUTING.md). Edit the `docs/src/*.typ` source, run `just docs-md`, and commit the regenerated Markdown; `just docs-md-check` fails on drift.
- Never dodge a gate: no lowered threshold, widened allow-list or added exclude. Fix the finding.
- Keep command output small; omit what you do not need (`chronic`, `grep`).
- Release only with `just release X.Y.Z`, after `just release X.Y.Z --dry-run` passes. Keep entries under `[Unreleased]`; never `cargo publish` by hand and never edit the version or date the CHANGELOG yourself. The tag push is the only publish path; the recipe pushes `main`, waits for `ci.yml` on that commit, and tags only a green run. A failed release is re-run on the same tag, never re-tagged. First release only: crates.io cannot attach a Trusted Publisher to a crate that does not exist, so store a scoped `CARGO_REGISTRY_TOKEN` secret for that tag, then add the publisher and delete the secret.
- Delegate with `just fork <slug>` and land with `just land` in that worktree; never run a bare `wt merge`.
- See [CONTRIBUTING.md](CONTRIBUTING.md) for conventions and code standards.
