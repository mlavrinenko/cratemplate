#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: slot(
    "title",
    prompt: "Starts with a verb: Make a release unable to half-fail",
    example: "Make a release unable to half-fail",
  ),
)

= Summary
#slot(
  "summary",
  kind: "raw",
  prompt: "What went wrong, where, and why it matters",
  example: "Four release tags went red at `cargo publish`.",
)

= Scope
#slot(
  "scope",
  kind: "raw",
  prompt: "Bullets: what this task changes",
  example: "- `template/Justfile`: refuse a tag that cannot succeed.",
)
