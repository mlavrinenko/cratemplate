#import "@local/mindtape:0.2.0": *

#show: task.with(
  title: "Finish the output port in the template",
  priority: framework("ice", confidence: 0.9, ease: 8.0, impact: 5.0),
  difficulty: 2,
  estimate: (files: 3),
  status: proposed(2026, 9, 13),
)

= Summary

The template already runs the suite through nextest with a shared
`.config/nextest.toml`, a quiet cover, a `--min 30` crap and a graph-less deny
(f492fb3). Three leftovers keep it from the fully quiet shape mindtape arrived
at: both `mmz` recipes still let just print its own failure line, `count-tests`
runs the whole suite to scrape nextest's summary, and `just test` interpolates
`{{ ARGS }}`, which re-splits spaces and re-globs wildcards in a filter.

= Scope

- `[no-exit-message]` on the root and template `mmz *ARGS`.
- `count-tests` -> `cargo nextest list --message-format json | jq`, with `jq`
  added to `template/flake.nix` (the root flake already carries it).
- `just test` -> `[positional-arguments]` plus `"$@"`, like mindtape's.
- `just mmz validate bin` and `just mmz validate lib` pass, and the task closes
  with the gate fresh.

= Scope, deliberately excluded

Switch the template's doctest pairing: a generated library is exactly the case
the two-pass exists for, so it stays.
