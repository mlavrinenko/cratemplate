#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Silence a green CRAP gate with github format",
  priority: framework("ice", confidence: 0.9, ease: 8.0, impact: 3.0),
  difficulty: 1,
  estimate: (files: 2),
  status: done(
    2026,
    11,
    9,
  )[crap.sh passes --format github --threshold 30 --fail-above and excludes \*\*/main.rs; a green run is silent, a red one emits one ::warning per offender.],
)

= Summary
`template/Justfile`'s `crap` recipe passes `--min 30 --threshold 30`, so a green run prints only the table header and the rows at the cutoff, about 10 lines. `--format github` prints one `::warning` line per failing function and nothing at all on a pass. typst-world switched to it (commit 66e8ad5) with no loss on red: each line names the file, line, function and score.

Projects generated before `--min 30` landed (f492fb3) still print every analyzed function on green: swhid-mint, artifact-gate and corkystrator. Those are fixed in their own repos; this task is the generator's half.

= Scope
- `template/.just/scripts/crap.sh` (the body moves there in the Justfile restructure): replace `--min 30` with `--format github`; keep `--threshold 30 --fail-above`; add `--exclude '**/main.rs'` so a workspace member's `main.rs` is excluded, not only `src/main.rs`.
- Rewrite the comment above the recipe to say a green run prints nothing and a red run one `::warning` per offender.
- Do not touch `README.md` or `CONTRIBUTING.md`; neither shows CRAP output. They describe the threshold, which stays.
- `CHANGELOG.md`: an Unreleased entry.
- `just validate bin` and `just validate lib` pass, and the generated project's green `just crap` prints nothing.

= Dependencies
Land `restructure-the-template-justfile-into-scripts` first; otherwise edit `template/Justfile` and move the flag with the body.
