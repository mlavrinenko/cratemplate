#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Tune jscpd and add a clone baseline",
  priority: framework("ice", confidence: 0.85, ease: 5.0, impact: 6.0),
  difficulty: 3,
  estimate: (files: 6),
  status: done(2026, 11, 11),
  tags: ("template", "gating", "tooling"),
  links: parent("land-the-corrected-renovation-backlog.typ"),
)

= Summary

`template/Justfile` runs `jscpd --no-tips -k 70 -f rust --exit-code 1 -r ai {{ rust_roots }}`. It compares identifiers and literals, so two unrelated functions with the same shape can be called a clone, and every finding fails. qahq now pins jscpd 5.4.1, whose `--ignore-identifiers`, `--ignore-literals`, `--similarity`, `--baseline`, `--update-baseline`, `--fail-on-new-clones` and built-in `--merge-baseline` flags change this. Those flags find more clones, not fewer; the baseline is the false-positive control.

= Scope

- `template/Justfile` `check-dry` (or its script after the restructure): add `--ignore-identifiers --ignore-literals --similarity=0.8`, keep the `ai` reporter and the 70-token threshold.
- Drop `--exit-code 1`, or pair it with `--new-only`; gate new clones with `--fail-on-new-clones` against `.config/jscpd-baseline.json`.
- Add a `dry-baseline` recipe that regenerates the committed baseline with `--update-baseline`; the gate never writes it.
- Register the built-in `jscpd --merge-baseline %O %A %B` driver in `template/.gitattributes` only if the baseline actually needs a merge driver; otherwise leave it out.
- `template/.mmz/config.yaml`: add `.config/jscpd-baseline.json` to the `just check-dry` inputs.
- Validate a known clone is accepted in the baseline and a new clone fails; keep `just validate bin` and `just validate lib` green.

= Notes

A baseline hides existing clones; it does not forgive them forever. `dry-baseline` is a deliberate commit, like a coverage ratchet, and a new clone still fails the gate.
