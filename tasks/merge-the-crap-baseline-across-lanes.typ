#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Merge the CRAP baseline across lanes",
  priority: framework("ice", confidence: 0.85, ease: 4.0, impact: 7.0),
  difficulty: 3,
  estimate: (files: 5),
  status: done(2026, 11, 11),
  tags: ("template", "tooling"),
  links: parent("land-the-corrected-renovation-backlog.typ")
    + depends-on("add-a-crap-ratchet-baseline.typ"),
)

= Summary

Two lanes that each improve a different function edit the same committed CRAP baseline, and the second `just land` conflicts on it. Test the shape first: a `.gitattributes` merge driver is added only if the repro actually conflicts.

= Scope

- Extend `template/.just/scripts/land-repro.sh` with two lanes that edit different functions in one file, run `crap-baseline` in each, and land both. Use `--sort file` so the baseline's order is stable.
- If the repro lands cleanly, stop there: no merge driver, and say so in the task note.
- If it conflicts, add `template/.gitattributes` `crap-baseline.json merge=crap-baseline` and `template/.just/scripts/crap-baseline-merge.sh`: merge the three inputs keyed `(file, function, line)`, keeping the lower score. A missing baseline in any input is a failure, never an empty file.
- `template/.just/scripts/install-hooks.sh`: define `merge.crap-baseline.driver`.
- `template/.mmz/config.yaml`: add the script and driver to `tooling-meta`.
- Keep `just validate bin` and `just validate lib` green.

= Dependencies

Needs `add-a-crap-ratchet-baseline`: this task merges the file it creates.

= Notes

`line` is the tie-breaker for two functions with the same name in one file (nested modules, generated impls). Without it, the merge silently keeps one function's score and drops the other.
