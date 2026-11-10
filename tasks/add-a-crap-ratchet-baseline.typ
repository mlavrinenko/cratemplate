#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Add a CRAP ratchet baseline",
  priority: framework("ice", confidence: 0.75, ease: 5.0, impact: 4.0),
  difficulty: 4,
  estimate: (files: 7),
  status: accepted(2026, 11, 11),
  tags: ("template", "gating", "tooling"),
  links: parent("land-the-corrected-renovation-backlog.typ"),
)

= Summary

`just crap` uses a fixed absolute threshold of 30, so a function that improves from 90 to 70 still passes and can rot back to 89. A committed baseline lets the gate ratchet down without raising the absolute threshold, so an already-bad function cannot get worse while the tree is cleaned up.

= Scope

- Add `template/.config/crap-baseline.json`, generated with `cargo crap --format json --sort file --output .config/crap-baseline.json`.
- `template/.just/scripts/crap.sh`: keep the stale-lcov refusal and the three excludes, and gate with `--format github --threshold 30 --fail-above --baseline .config/crap-baseline.json --fail-regression --sort file`. cargo-crap 0.3.1 supplies every flag; no custom JSON comparator.
- A missing baseline is a hard failure. Never fall back to the absolute threshold.
- `template/Justfile`: `crap-baseline` regenerates the file deliberately; the gate never writes it.
- `template/.mmz/config.yaml`: add the baseline to `just crap` inputs as a literal path, like `lcov`.
- `template/docs/src/contributing.typ`: one sentence about the baseline, after the docs slimming task; do not repeat the CRAP rationale.
- Validate a generated bin and lib: a worse score fails, an equal or better score passes, and the workspace path is covered too.

= Notes

The ratchet only holds after `crap-baseline` is deliberately updated: a later score can still rise to the old baseline, and only a fresh baseline tightens it.
