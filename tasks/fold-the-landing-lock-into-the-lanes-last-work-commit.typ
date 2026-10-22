#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Fold the landing lock into the lane's last work commit",
  priority: framework("ice", confidence: 0.9, ease: 7.0, impact: 5.0),
  difficulty: 2,
  estimate: (files: 4),
  status: proposed(2026, 10, 23),
)

= Summary
When a lane ends on a commit that only files a task, the template's `wt-lock.sh amend` puts outdatty.lock into that commit, and a commit-msg hook that wants a `Refs:` footer outside tasks/ refuses it. corpuspeak fixed it in f2b98f8; the template still ships the old amend.

= Scope
- `template/.just/scripts/wt-lock.sh`: `amend` folds the lock into the newest lane commit with a `Refs:` footer, by fixup and autosquash when task-filing commits follow it.
- `template/.just/scripts/land-repro.sh`: a stand-in commit-msg hook and a lane that ends on a task-filing commit; red on the old script.
- `template/.config/wt.toml`, `template/AGENTS.md`: the comments and paragraph.
- `CHANGELOG.md`: an Unreleased entry.
- `just validate bin` and `just validate lib` pass.
