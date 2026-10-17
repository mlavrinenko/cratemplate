#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Silence a green CRAP gate with github format",
  priority: framework("ice", confidence: 0.8, ease: 8.0, impact: 3.0),
  difficulty: 1,
  estimate: (files: 3),
  status: proposed(2026, 10, 17),
)

= Summary
`template/Justfile`'s `crap` recipe passes `--min 30 --threshold 30`, so a green run prints only the table header and the rows at the cutoff, about 10 lines. `--format github` prints one `::error` line per failing function and nothing at all on a pass. typst-world switched to it (commit 66e8ad5) with no loss on red: each line names the file, line, function and score.

Projects generated before `--min 30` landed (f492fb3) still print every analyzed function on green: swhid-mint, artifact-gate and corkystrator. Those are fixed in their own repos; this task is the generator's half.

= Scope
- `template/Justfile` `crap`: replace `--min 30` with `--format github`, and rewrite the comment above it to say a green run prints nothing and a red run one line per offender.
- `template/CONTRIBUTING.md`, `README.md`: wherever they show `just crap` output.
- `just validate bin` and `just validate lib` pass, and the generated project's green `just crap` prints nothing.
- `CHANGELOG.md`: an Unreleased entry.
