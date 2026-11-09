#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Quiet cover and add a per-file floor",
  priority: framework("ice", confidence: 0.85, ease: 6.0, impact: 7.0),
  difficulty: 3,
  estimate: (files: 4),
  status: done(
    2026,
    11,
    9,
  )[cover prints only the header and TOTAL; 70% workspace total plus 60% per production file with >=5 uncovered lines, tests excluded; the CI gate name is updated.],
  tags: ("template", "gating", "tooling"),
)

= Summary

At filing, `just cover` rendered the full per-file llvm-cov table and enforced only `--fail-under-lines 70` on the workspace total, so one well-covered file hides a 20% file. The CI job at `template/.github/workflows/ci.yml:61` already says "fails under 70%"; make the recipe body mean that. Print the header and TOTAL, and add a per-file floor with an uncovered-lines guard for tiny files.

= Scope

- Keep `cover`'s body in `template/.just/scripts/cover.sh` after the Justfile restructure; if it is still inline, move it first.
- Keep the lcov render unchanged; add `--fail-under-file-lines 60` to the text report (start at 60, tune to 70 once the tree is clean) and an uncovered-lines guard so a three-line file with one uncovered line cannot fail the floor.
- Exclude `tests/**` and `**/*_tests.rs` from the per-file floor, as `crap` already does, and render only the header plus TOTAL (for example with `--summary-only`) for the normal report.
- Fix `cover_ignore` to `(^|/)src/main\.rs|/registry/src/` so a workspace member's `main.rs` is excluded, and use the same regex in `crap`.
- `template/.github/workflows/ci.yml:61`: keep the job name truthful if the floor or the number changes.
- Validate a generated bin and lib: an under-covered file fails, a clean tree passes, and `just check` stays green.

= Dependencies

Land `restructure-the-template-justfile-into-scripts` first; this task moves the body it creates.
