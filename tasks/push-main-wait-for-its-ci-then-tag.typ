#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Push main, wait for its CI, then tag",
  priority: framework("ice", confidence: 0.8, ease: 6.0, impact: 7.0),
  difficulty: 3,
  estimate: (files: 6),
  status: done(2026, 10, 7)[both validates green; adopted by the eight crates],
  tags: ("ci", "template"),
)

= Summary
`just release` refuses unless main already equals origin/main and the
`ci.yml` run on HEAD is green. So a release takes three steps by hand:
push main, wait for CI, run the recipe. The push is easy to forget, and
a wait done by eye can tag a commit whose CI later goes red.

= Scope
- `template/Justfile`: `just release` runs every check that needs no push,
  then pushes main fast-forward only, waits for the `ci.yml` run on that
  exact commit, and tags and pushes the tag only if that run is green.
- `--dry-run` runs the same checks and says what it would push.
- Refusals keep one `error:` line, at most two `hint:` lines, values in
  single quotes.
- `just validate` drives the new path in the scratch project with a
  stubbed `gh` and a local bare origin.
- The downstream crates adopt the recipe.


= Outcome

- Commit a0c1cda. `just mmz validate bin` and `just mmz validate lib` pass,
  and both drive the new path against a local bare origin and a `gh` stub.
- Adopted by outdatty, typst-world, typst-harvest, typst-cst, typst-edit,
  typst-cleanup, artifact-gate and swhid-mint; mindtape's release-pipeline
  branch is pending.
