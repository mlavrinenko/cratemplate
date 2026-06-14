# {{project-name}}

## Agent Rules

- See and use [Justfile](Justfile). Add any repeatable and regular operations there.
- At the end ensure that `just fix-check` is green.
- Tests: inline `#[cfg(test)]` units; CLI/integration in `tests/` (`assert_cmd` + `predicates`). `just fix-check` auto-ejects inline tests from oversized files via `ejectest`.
- Coverage and CRAP gates run separately (CI + `just validate`): `just cover`
  then `just crap`. If `just crap` flags a function, add tests or reduce its
  branching — don't raise the threshold to dodge it.
- Be careful with the context. Omit non-necessary command outputs using `chronic` or `grep`.
- [outdatty.yaml](outdatty.yaml) couples sources to dependents. When `just check`
  reports drift, update the listed dependents, then run `just outdatty-update`
  to re-confirm. Add a group whenever you introduce files that must stay in sync.
- Eating your own dog food: the tool should use itself if applicable.

See [CONTRIBUTING.md](CONTRIBUTING.md) for project conventions and code standards.
