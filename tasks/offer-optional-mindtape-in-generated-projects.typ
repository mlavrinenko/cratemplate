#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Offer optional MindTape in generated projects",
  priority: framework("ice", confidence: 0.7, ease: 4.0, impact: 5.0),
  difficulty: 4,
  estimate: (files: 7),
  status: proposed(2026, 11, 9),
  tags: ("template", "tooling", "gating"),
)

= Summary

A generated project has no task tracker. `template/flake.nix` ships no `mt`, and no `tasks/` or `.mindtape/` exists. Offer `task_tracker = none|mindtape` at generation, ship the minimal tracker only when chosen, and gate it without putting `mt` in the default shell.

= Scope

- `template/cargo-generate.toml`: add `[placeholders.task_tracker]` with choices `none`, `mindtape`, default `none`; conditional ignores ship `.mindtape/config.toml`, `.mindtape/templates/task.typ` and `tasks/` only for `mindtape`.
- `template/flake.nix`: render the `mindtape` input and dev-shell package only when `task_tracker == "mindtape"`; the default flake stays free of the input.
- Add `template/.just/scripts/check-tasks.sh`: no-op when `.mindtape/` is absent; otherwise run `mt check -q` and `mt fix --check`. `template/Justfile` adds `check-tasks`, and `just check` calls it (a no-op for `none`).
- `template/.mmz/config.yaml`: add a `just check-tasks` gate rule; the script's own no-op keeps the `none` variant green.
- Add a minimal `template/.mindtape/config.toml`: the statuses, a derived `ct` tag, the 1-15 file estimate rule, and no flip gate. The task template imports `@local/mindtape:0.4.0`.
- Validate `just validate bin` and `just validate lib` for both tracker choices (four runs).

= Dependencies

Land `bump-mindtape-to-0-5-0` for the pinned `mt` and `slim-the-template-docs-by-bytes` so the added tracker prose does not undo the docs target.

= Notes

Do not add `mt check --commits` here; the commits pack is a separate decision. A `none` project must build and gate with no `mt` on PATH.
