#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Gate the backlog in CI",
  priority: framework("ice", confidence: 0.85, ease: 4.0, impact: 8.0),
  difficulty: 2,
  estimate: (files: 2),
  status: done(
    2026,
    11,
    9,
  )[root check-tasks runs mt check && mt fix --check; ci.yml runs it as a step, so a malformed or stale task file fails the backlog gate.],
  tags: ("ci", "tooling"),
)

= Summary

Root `.github/workflows/ci.yml` runs only `just validate`; nothing runs `mt check -q` or `mt fix --check`, so a malformed task file or a stale import reaches main. The root dev shell now pins `mt` 0.5.0, so CI can run the same pair. Do not add `mt check --commits` until the commits pack is adopted.

= Scope

- Root `Justfile`: add a `check-tasks` recipe that runs `mt check -q` and `mt fix --check`.
- Root `.github/workflows/ci.yml`: add a step that runs `nix develop --command just check-tasks`, after the nix setup and before or beside `just validate`.
- Do not run `mt check --commits`; do not add `mt` to `template/flake.nix`.
- Validate the step fails on a deliberately malformed task and passes on the current corpus; `just validate bin`/`just validate lib` stay green.

= Dependencies

Land `bump-mindtape-to-0-5-0` first; without the pinned root input, CI has no `mt`.

= Notes

`mt check -q` and `mt fix --check` are fast and deterministic. A commit-range check would need the commits pack and the full history, which is a different task.
