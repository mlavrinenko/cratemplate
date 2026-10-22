#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Quiet a green machete, deny and test run in the template",
  priority: framework("ice", confidence: 0.9, ease: 9.0, impact: 3.0),
  difficulty: 1,
  estimate: (files: 3),
  status: done(2026, 10, 23),
)

= Summary
`template/Justfile` recipes `machete`, `deny` and `test` print more than a green run needs. cargo-machete prints a three-line banner to say it found nothing, `cargo deny` warns once per duplicate version in the lock (43 lines to say all three ok, against 1 with `-L error`), and `cargo nextest run` lists every `Compiling` line of a first build. corpuspeak quieted all three; the doctest capture already came over.

= Scope
- `template/Justfile`: `machete` shows its output only on failure; `deny` passes `-L error`; `test` passes `--cargo-quiet` to nextest.
- `CHANGELOG.md`: an Unreleased entry.
- `just validate bin` and `just validate lib` pass and print fewer lines.
