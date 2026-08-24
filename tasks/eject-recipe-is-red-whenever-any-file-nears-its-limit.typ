#import "@local/mindtape:0.2.0": *

#show: task.with(
  title: "Eject recipe is red whenever any file nears its limit",
  priority: framework("ice", confidence: 1.0, ease: 9.0, impact: 6.0),
  difficulty: 2,
  estimate: (files: 2),
  status: done(2026, 8, 24),
)

= Summary

A freshly generated project fails `just fix-check` as soon as any file sits at
or above the eject baseline, whether or not anything needs ejecting.

`just eject` runs

```
linecop --baseline 90 --format paths | ejectest apply src --files-from - --lenient
```

under just's `bash -eo pipefail`. `linecop --baseline 90` exits 1 when a file is
at or over the baseline; that is its way of reporting a finding, not a failure to
run. `ejectest` itself exits 0. So the pipeline fails on the producer.

Found in a generated project where `CONTRIBUTING.md` reached 183 of its 200-line
limit, which is 91.5 per cent. Nothing about that file can be ejected: ejectest
moves inline Rust test modules, and the scan is not filtered by language, so a
Markdown path is handed to a tool that has no use for it.

Two independent defects, then: an exit code read as fatal when it is
informational, and a scan that is not restricted to the language being ejected.

= Scope

- Restrict the baseline scan to Rust.
- Stop treating linecop's threshold exit code as a pipeline failure.
- Assert it in `just validate`: a generated project with a near-limit Markdown
  file must still pass `just fix-check`.
