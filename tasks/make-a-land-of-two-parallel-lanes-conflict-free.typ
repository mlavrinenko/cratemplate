#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Make a land of two parallel lanes conflict-free",
  priority: framework("ice", confidence: 0.8, ease: 5.0, impact: 6.0),
  difficulty: 3,
  estimate: (files: 8),
  status: done(2026, 10, 23),
)

= Summary
Two lanes forked with `just fork` that each add a CHANGELOG entry and re-confirm `outdatty.lock` conflict on the second `just land`: both edit the same changelog spot and the same lock line. corpuspeak fixed it in its own copy (779d3b8); the template still ships the conflict.


= Scope
- `template/.gitattributes`: `CHANGELOG.md merge=union`, `outdatty.lock merge=outdatty`.
- `template/Justfile`: `install-hooks` defines the `outdatty` merge driver; a `land-repro` recipe; comments.
- `template/.config/wt.toml`: `pre-merge` hooks `lock` (refresh) and `amend` around the gate.
- `template/.just/scripts/wt-lock.sh`, `template/.just/scripts/land-repro.sh`: new.
- `template/AGENTS.md`: the paragraph saying landing never stops on either file.
- `just validate` runs `just land-repro` in the generated project.

