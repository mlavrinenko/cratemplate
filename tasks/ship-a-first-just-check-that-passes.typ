#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Ship a first just check that passes",
  priority: framework("ice", confidence: 0.8, ease: 6.0, impact: 6.0),
  difficulty: 3,
  estimate: (files: 2),
  status: proposed(2026, 10, 10),
)

= Summary
A freshly generated project fails its first `just check`: it ships no
`outdatty.lock` and no `Cargo.lock`, so `outdatty-check` and the arms that
declare `Cargo.lock` fail or miss until someone records them by hand. Both
nix-why-build and canibump hit this on 2026-10-10.


= Scope
- Generate or ship `outdatty.lock` (and a `Cargo.lock`) so `just check` is green on the first run.
- `just validate bin` and `just validate lib` assert a first `just check` passes.

