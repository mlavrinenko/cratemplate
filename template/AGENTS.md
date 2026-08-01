# {{project-name}}

## Agent Rules

- See and use [Justfile](Justfile). Add any repeatable and regular operations there.
  `set shell` already gives every recipe line `bash -eo pipefail`, so a new recipe
  needs no `#!/usr/bin/env bash` + `set -eo pipefail` preamble. just runs each line
  in a fresh shell though — add a shebang only when the body needs one shell across
  lines (a variable read back later, a `trap`).
- At the end ensure that `just fix-check` is green.
{% if crate_kind == "bin" -%}
- Tests: inline `#[cfg(test)]` units; CLI/integration in `tests/` (`assert_cmd` + `predicates`). `just fix-check` auto-ejects inline tests from oversized files via `ejectest`.
{% endif -%}
{% if crate_kind == "lib" -%}
- Tests: inline `#[cfg(test)]` units next to the code they exercise; add `tests/` integration tests for public-API behaviour that spans modules. `just fix-check` auto-ejects inline tests from oversized files via `ejectest`.
{% endif -%}
- Coverage and CRAP gates run separately (CI + `just validate`): `just cover`
  then `just crap`. `just cover` uses `cargo-llvm-cov` (not tarpaulin) — it
  merges child-process profraw, so subprocess-based e2e tests attribute
  correctly. If `just crap` flags a function, add tests or reduce its
  branching — don't raise the threshold to dodge it.
- Every arm of `just check` is `just mmz <subgate>`:
  [mmz](https://github.com/mlavrinenko/mmz) skips arms whose declared inputs are
  unchanged since they last passed, so a new or retargeted gate needs its rule in
  [.mmz/config.yaml](.mmz/config.yaml) — an unmatched command is a hard error, not
  a silent skip. Don't wrap `just check` arms in `chronic`: a cache hit is already
  quiet, and a miss must stream its output.
- Be careful with the context. Omit non-necessary command outputs using `chronic` or `grep`.
- [outdatty.yaml](outdatty.yaml) couples sources to dependents. When `just check`
  reports drift, update the listed dependents, then run `just outdatty-update`
  to re-confirm. Add a group whenever you introduce files that must stay in sync.
- `just check-dry` (jscpd) flags duplicated Rust blocks of >=70 tokens. Fix
  a finding by extracting a shared helper — never by shuffling tokens until
  the detector loses the scent.
- `just deny` (cargo-deny: advisories, licenses, bans) is not in `just check` —
  it needs network. Run it after touching dependencies. Widen `deny.toml`'s
  allow-list deliberately; never to silence a finding.
- Eating your own dog food: the tool should use itself if applicable.

See [CONTRIBUTING.md](CONTRIBUTING.md) for project conventions and code standards.
