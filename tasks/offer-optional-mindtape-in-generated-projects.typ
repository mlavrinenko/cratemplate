#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Offer optional MindTape in generated projects",
  priority: framework("ice", confidence: 0.7, ease: 4.0, impact: 5.0),
  difficulty: 4,
  estimate: (files: 9),
  status: done(2026, 11, 11),
  tags: ("template", "tooling", "gating"),
  links: parent("land-the-corrected-renovation-backlog.typ"),
)

= Summary

A generated project has no task tracker. Offer `task_tracker = none|mindtape` at generation, ship the minimal tracker only when chosen, and gate it without putting `mt` in the default shell. qahq already packages mindtape 0.5.0, so no new flake input or second lock is needed.

= Scope

- `template/cargo-generate.toml`: add `[placeholders.task_tracker]` with choices `none`, `mindtape`, default `none`; conditional ignores for `.mindtape/` and `tasks/` when the choice is `none`.
- `template/flake.nix`: add `qahq.packages.${system}.mindtape` to the dev shell only when `task_tracker == "mindtape"`; keep the default flake free of a second input and lock.
- Add `template/.just/scripts/check-tasks.sh`: no-op when `.mindtape/` is absent; otherwise run `mt check -q` and `mt fix --check`, and fail when `mt` is missing.
- Fix `template/.just/scripts/wt-tasks.sh`: when `.mindtape/` exists but `mt` is missing, fail instead of printing a skip.
- `template/Justfile`: add `check-tasks`; `just check` calls it. `template/.mmz/config.yaml`: add a `just check-tasks` rule tagged `gate`, with `.mindtape/**`, `tasks/**`, the script and `gates-meta` as inputs.
- Add `template/.mindtape/config.toml` (statuses, a derived `ct` tag, the 1-15 file estimate rule, no flip gate) and `template/.mindtape/templates/task.typ` importing `@local/mindtape:0.4.0`.
- Validate one kind (`bin`) with the tracker and both kinds without it. The tracker path is orthogonal to crate kind, so a lib-with-tracker run is not a separate case.

= Notes

Do not add `mt check --commits` here; the commits pack is a separate decision. A `none` project must build and gate with no `mt` on PATH.
