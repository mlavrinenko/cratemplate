#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Add a staged just check verdict",
  priority: framework("ice", confidence: 0.7, ease: 7.0, impact: 4.0),
  difficulty: 5,
  estimate: (files: 5),
  status: proposed(2026, 11, 9),
  tags: ("template", "gating"),
)

= Summary

`just check` is one `[parallel]` recipe with seven arms. Every arm streams its own log on a miss, even when only one fails, and there is no fast/build order between them. MindTape's `check.sh` runs stages, prints one verdict on green, and prints only the failed stage's log on red. Port that shape without adding `cover` or `crap` to the default gate.

= Scope

- `template/.just/scripts/check.sh`: run the current arms in a fast group (fmt-check, clippy, machete, check-file-size, check-dry) and a build group (test, outdatty-check), calling `mmz just <arm>` so a cache hit stays silent; green prints one verdict, red prints only the failed stage's captured log and exits non-zero.
- `template/Justfile`: `check STAGE=''` delegates to the script; `just check cover` also runs `cover` and `crap`; keep `[doc]`/`[group]` and the per-arm mmz rules.
- `template/.mmz/config.yaml`: keep every arm's rule and `gate` tag, or add one `just check` rule that names the stage set; do not tag `cover`/`crap`.
- Keep `just check` usable from the pre-commit hook and from `template/.config/wt.toml` without changing their command.
- Validate a green run, a red run in one arm, and the opt-in `just check cover` in a generated bin and lib.

= Dependencies

Land `restructure-the-template-justfile-into-scripts` first; this task adds another script and recipe shape.

= Notes

The default gate stays offline and fast. A stage that needs network (`deny`) or minutes of CPU (`cover`/`crap`) is opt-in, not a hidden extra stage.
