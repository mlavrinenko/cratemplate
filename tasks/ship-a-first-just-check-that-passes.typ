#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Ship a first just check that passes",
  priority: framework("ice", confidence: 0.9, ease: 7.0, impact: 6.0),
  difficulty: 3,
  estimate: (files: 3),
  status: done(
    2026,
    11,
    9,
  )[a generated project bootstraps a missing outdatty.lock at check time with a review notice; a stale lock still fails. outdatty.yaml braces the Cargo.toml globs, the docs explain the one-time Cargo.lock miss, and bin/lib/workspace first checks are green.],
)

= Summary
A freshly generated project fails its first `just check`: it ships no
`outdatty.lock`, so `outdatty-check` reports every tracked file as untracked,
and no `Cargo.lock`, so the arms that declare it miss once. Both nix-why-build
and canibump hit this on 2026-10-10. Do not ship a static lock: bootstrap a
missing one at check time, and document the one-time `Cargo.lock` miss.

= Scope
- `template/Justfile` `outdatty-check`: when `outdatty.lock` is missing, run
  `outdatty update --format quiet`, print a one-line notice, then run
  `outdatty check`. Leave an existing lock alone.
- Root `Justfile`: remove both `just outdatty-update` calls in the `validate`
  body (currently lines 93 and 249); the bootstrap replaces them.
- `template/outdatty.yaml`: replace the separate `Cargo.toml` and
  `crates/*/Cargo.toml` entries with `{Cargo.toml,crates/*/Cargo.toml}` so the
  missing path no longer warns in a single-crate project.
- `template/CONTRIBUTING.md`: keep the paragraph saying a fresh clone has no
  `Cargo.lock`, the first build writes it, and the mmz arms that declare it
  miss once more (currently lines 141-143); add it if the docs slimming task
  removes it.
- Validate a fresh generated bin and lib: the first `just check` is green, the
  second is a full mmz hit, and `mmz --is-fresh --tag gate` plus the
  pre-commit hook pass.
- Do not commit an `outdatty.lock` to `template/` and do not add a
  lock-generation step to cargo-generate.
