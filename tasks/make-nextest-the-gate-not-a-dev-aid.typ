#import "@local/mindtape:0.2.0": *

#show: task.with(
  title: "Make nextest the gate, not a dev aid",
  priority: framework("ice", confidence: 0.8, ease: 6.0, impact: 6.0),
  difficulty: 3,
  estimate: (files: 4),
  status: proposed(2026, 8, 28),
)

= Summary

`cargo-nextest` is already in the template's dev shell and already has a `just
nextest` recipe, and the gate still runs `cargo test`. The recipe's own comment
explains why — nextest does not run doctests — and that reason is sound for a
template while being the wrong default for what it produces.

Measured in a generated project that had grown to 807 tests (kimmable):

#table(
  columns: 3,
  [*Runner*], [*Output*], [*Wall*],
  [`cargo test`], [1024 lines], [20.5 s],
  [`cargo nextest run`], [816 lines], [9.7 s],
  [`cargo nextest run --status-level fail`], [6 lines], [8.7 s],
)

Two-plus times faster, and a green run says six lines instead of a thousand.
The gap is far wider on a *filtered* run, because `cargo test` starts every
test binary and lets each one print a result block for the zero tests it
matched: seven network tests reported themselves in 263 lines, and 12 under
nextest. `-q` makes that case worse rather than better — it drops the
`Running tests/foo.rs` header and keeps every empty block.

= The doctest question is real here, unlike downstream

kimmable could switch outright because it has *zero* doctests — its ten
doc-comment fences are all `toml`, `json` and `text`. A template cannot assume
that: a generated library crate is exactly the kind of project that will have
doctests, and silently ceasing to run them is the worst outcome available.

So the template's answer is nextest's own documented pairing rather than a
straight swap:

```
cargo nextest run --workspace
cargo test --workspace --doc
```

Both, in one recipe. A project with no doctests pays a fast no-op for the
second line; one with doctests keeps them gated. Nothing silently stops
running.

= Scope

- `just test` runs both, with `--status-level fail` so a green gate is quiet
  and a red one is not.
- `just cover` moves to `cargo llvm-cov nextest`, which exists. Gate and
  coverage must use the *same* runner: process-per-test and shared-process are
  different execution models, and splitting them means a test can pass under
  one and fail under the other with nothing saying so.
- `just nextest` is then redundant as a separate dev aid — fold it in or drop
  it, but do not leave a recipe whose comment contradicts the gate beside it.
- `just count-tests` scrapes `test result:` lines out of `cargo test` and
  breaks under nextest's format. It needs nextest's summary line, or `--json`.
- The comments in `template/Justfile` and `template/flake.nix` both state the
  old reasoning as settled. Both are wrong once this lands.

= Scope, deliberately excluded

Making the doctest half conditional on whether the generated project has any.
Detecting that is a scan the recipe would have to keep true, and running an
empty doctest pass costs about a second.
