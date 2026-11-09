#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Tune jscpd and add a clone baseline",
  priority: framework("ice", confidence: 0.85, ease: 5.0, impact: 6.0),
  difficulty: 3,
  estimate: (files: 7),
  status: proposed(2026, 11, 9),
  tags: ("template", "gating", "tooling"),
)

= Summary

`template/Justfile:284` runs `jscpd --no-tips -k 70 -f rust --exit-code 1 -r ai {{ rust_roots }}`. It compares identifiers and literals, so two unrelated functions with the same shape can be called a clone, and a finding can only be fixed by extracting code. Add `--ignore-identifiers --ignore-literals --similarity=0.8`, commit a baseline, and gate against new clones only.

= Scope

- `template/Justfile` (or `.just/scripts/check-dry.sh` after the restructure): add `--ignore-identifiers --ignore-literals --similarity=0.8`; keep `--exit-code 1` spelled with its value and keep the `ai` reporter.
- Add `.config/jscpd-baseline.json` (committed) and a `dry-baseline` recipe that regenerates it deliberately; the gate reads it with the baseline flag the packaged jscpd supports.
- `template/.gitattributes`: `jscpd-baseline.json merge=jscpd`; `install-hooks` defines the driver.
- `template/.mmz/config.yaml`: add `.config/jscpd-baseline.json` to the `just check-dry` inputs.
- Validate a known clone is ignored when it is in the baseline and reported when it is new; `just validate bin`/`just validate lib` stay green.

= Notes

A baseline hides existing clones; it does not forgive them forever. `dry-baseline` is a deliberate commit, like a coverage ratchet, and a new clone still fails the gate.
