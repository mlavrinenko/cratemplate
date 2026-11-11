#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Refuse local machine paths in commits",
  priority: framework("ice", confidence: 0.85, ease: 6.0, impact: 8.0),
  difficulty: 2,
  estimate: (files: 4),
  status: done(
    2026,
    11,
    9,
  )[.githooks/local-paths scans the staged index for HOME, the checkout and the primary worktree; .githooks/pre-commit runs it and install-hooks wires core.hooksPath.],
  tags: ("template", "gating"),
)

= Summary

A pasted `/home/<user>/...` path or a checkout path in a commit reads as plain evidence in review, breaks every other machine, and stays in history once pushed. MindTape ships `.githooks/local-paths` for this; the template's `.githooks/` has only `pre-commit`, and `install-hooks` chmods only that file.

= Scope

- Add `template/.githooks/local-paths`, adapted from `../mindtape/.githooks/local-paths`: scan `git grep --cached` for `$HOME`, the checkout root and the primary worktree, skip empty or `/` needles, and exit 1 with a message naming the replacement (`<repo>`, `<worktree>`, `~`).
- `template/.githooks/pre-commit`: run `local-paths` before `exec mmz --is-fresh --tag gate`.
- `install-hooks` (Justfile now, `.just/scripts/install-hooks.sh` after the restructure): chmod +x `.githooks/local-paths`.
- `template/.mmz/config.yaml`: add `.githooks/**` to `tooling-meta` so a hook edit re-runs `outdatty-check`.
- Validate a generated bin and lib: a staged local path fails the hook, a clean stage passes, and `just land-repro` stays green.

= Notes

Do not scan `tasks/` differently: a task may legitimately quote a path from a remote report, but a commit message or a staged source file must not name this machine.
