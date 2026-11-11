#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Ship worktrunk delegation in the template so a clone needs no host setup",
  priority: framework("ice", confidence: 0.7, ease: 5.0, impact: 6.0),
  difficulty: 4,
  estimate: (files: 6),
  status: done(2026, 10, 11),
)

= Summary
Delegated work in generated crates should fork and land through worktrunk (`wt`), configured in the repo. Hooks in the user's ~/.nix don't travel with a clone, and without them `wt merge` squashes the branch (losing each commit's `Refs:` footer), commits a dirty tree and runs no gate. worktrunk's project config (`.config/wt.toml`) can hold hooks and aliases but not merge defaults, so Justfile recipes carry the flags.

mindtape designs it first (~/projects/home/mindtape, task `configure-worktrunk-in-the-repo-so-a-fresh-clone-needs-no-host-setup`). Start this only after that lands, and copy its files.


= Scope
- `template/flake.nix`: `worktrunk` in the dev shell.
- `template/.config/wt.toml`: `pre-start` direnv allow and load. `[[pre-merge]]` runs `just check`, then the wip check. `pre-remove` carries the gate records and lcov into the primary checkout.
- `template/.just/scripts/wt-tasks-done.sh`, `template/.just/scripts/wt-carry-gate.sh`: copied from mindtape's result.
- `template/Justfile`: `fork <slug>` runs `wt switch --create <slug> --yes`; `land` runs `wt merge --no-squash --no-commit --yes`.
- `template/AGENTS.md`: delegate with `just fork`, land with `just land`.
- `just validate bin` and `just validate lib` pass.

- If they have landed, use `mt check --commits {{ target }}..HEAD` (mindtape task `refuse-a-commit-range-that-leaves-a-task-it-names-in-progress-at-its-tip`) and `mmz --import` (mmz task `import-gate-records-from-another-checkout-of-the-same-repo`) instead of the two scripts.
