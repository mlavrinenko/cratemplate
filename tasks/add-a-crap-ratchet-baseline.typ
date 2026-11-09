#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Add a CRAP ratchet baseline",
  priority: framework("ice", confidence: 0.75, ease: 5.0, impact: 4.0),
  difficulty: 4,
  estimate: (files: 7),
  status: proposed(2026, 11, 9),
  tags: ("template", "gating", "tooling"),
)

= Summary

`just crap` uses a fixed absolute threshold of 30. A function that improves from 90 to 70 still passes and can rot back to 89. A committed baseline lets the gate ratchet down without raising the absolute threshold, so an already-bad function cannot get worse while the tree is being cleaned up.

= Scope

- Add `template/.config/crap-baseline.json`: per file and function, the score and coverage from a known-good run.
- `.just/scripts/crap.sh` (after the Justfile restructure): fail when a function is above its baseline score or above 30; an equal or better score passes. A function absent from the baseline is held to the absolute threshold.
- `template/Justfile`: `crap-baseline` updates the file deliberately; the gate never writes it.
- `template/.mmz/config.yaml`: add the baseline file to `just crap` inputs; `just crap` stays untagged and outside `just check`.
- `template/CONTRIBUTING.md`/`AGENTS.md`: one sentence about the baseline after the docs slimming task; do not repeat the CRAP rationale.
- Validate a generated bin and lib: a worse score fails, an equal or better score passes, and `just crap-baseline` changes the file.

= Notes

The absolute threshold stays; the baseline is a second, tighter bound. Deleting the baseline must not silently pass the gate: a missing file falls back to the absolute threshold and says so.
