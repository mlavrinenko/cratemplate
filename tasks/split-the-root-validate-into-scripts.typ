#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Split the root validate into scripts",
  priority: framework("ice", confidence: 0.9, ease: 7.0, impact: 7.0),
  difficulty: 3,
  estimate: (files: 4),
  status: done(
    2026,
    11,
    9,
  )[root validate 277 -> 44 lines, now scripts/validate.sh with test-release.sh and test-workspace.sh; both outdatty-update calls removed.],
  tags: ("template", "tooling"),
)

= Summary

At filing, the root `Justfile` was 277 lines. `validate` started at line 13 and its body was 265 lines: generation, a long inner heredoc, the workspace conversion and a stubbed release simulation. Root `.mmz/config.yaml` already scopes `scripts/**`, so moving the body into scripts keeps memoization intact and makes each stage readable on its own.

= Scope

- `scripts/validate.sh`: move the `validate` body, keeping `#!/usr/bin/env bash`, `set -eo pipefail`, `TEMPLATE_DIR`, `WORK_DIR`, `cleanup`, `trap cleanup EXIT`, `unset BASH_ENV`, every assertion, every heredoc and the final `=== All checks passed ===`.
- `scripts/test-release.sh`: move the `just release` checks against the stubbed `gh`, the bare origin, the empty-origin case and the green/red CI cases.
- `scripts/test-workspace.sh`: move the copy, `scripts/to-workspace.sh`, the workspace gate and the `nix build`/`nix run` stage.
- Root `Justfile`: keep `default`, `[doc]`/`[group]` `mmz`, and `validate KIND='bin'`; `validate` validates `bin|lib` and runs `scripts/validate.sh "$KIND"`. Target 30 lines or fewer.
- Root `.mmz/config.yaml` already lists `scripts/**`; add no new input unless a helper lands outside it.
- Validate `just validate bin` and `just validate lib`; the scripts must produce the same output and exit codes as before.

= Notes

The root `Justfile`'s `[no-exit-message]` on `mmz` stays: it hides just's own failure line above mmz's reason.
