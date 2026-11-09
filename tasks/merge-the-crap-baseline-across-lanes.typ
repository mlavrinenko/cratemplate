#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Merge the CRAP baseline across lanes",
  priority: framework("ice", confidence: 0.85, ease: 4.0, impact: 7.0),
  difficulty: 3,
  estimate: (files: 5),
  status: proposed(2026, 11, 9),
  tags: ("template", "tooling"),
)

= Summary

Two lanes that each improve a different function edit the same committed CRAP baseline, and the second `just land` conflicts on it. The `outdatty.lock` merge driver already handles the same shape; key the CRAP baseline by file, function and ordinal.

= Scope

- `template/.gitattributes`: `crap-baseline.json merge=crap`.
- `template/.just/scripts/crap-baseline-merge.sh` (new): merge three versions by the key `(file, function, ordinal)`, keeping the lower score; on a genuine conflict, leave the target and fail loudly with both versions.
- `install-hooks` (or its moved `.just/scripts/install-hooks.sh`): define `merge.crap.driver`.
- `template/.mmz/config.yaml`: add the driver and script to `tooling-meta`; `template/AGENTS.md` gets the one-line landing note after the docs slimming task.
- Extend `just land-repro` with a two-lane CRAP baseline edit and keep `just validate bin`/`just validate lib` green.

= Dependencies

Land `add-a-crap-ratchet-baseline` first; this task merges the file it creates.

= Notes

The ordinal is the tie-breaker for two functions with the same name in one file (nested modules, generated impls). Without it, the merge silently keeps one function's score and drops the other.
