#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Make the template's gates cover a Cargo workspace",
  priority: framework("ice", confidence: 0.8, ease: 5.0, impact: 6.0),
  difficulty: 3,
  estimate: (files: 8),
  status: done(2026, 10, 23),
)

= Summary
corpuspeak moved its crates under `crates/`, and every place the template assumes one crate at the root broke: `_lcov-stale-reason`, `check-dry` and `eject` hardcode `src`/`tests`; the mmz `rust` and `manifests` scopes and outdatty's `src/**` miss `crates/`; `nix run` fails for want of a `pname`; the doctest pass prints five lines per crate on green.


= Scope
- `template/Justfile`: one file-scope variable names the source roots (`crates` when it exists, else `src tests`); the three recipes read it; the doctest pass prints only on failure.
- `template/.mmz/config.yaml`: `crates/**` in `rust`, `crates/*/Cargo.toml` in `manifests`.
- `template/outdatty.yaml`: `crates/*/src/**` beside `src/**`.
- `template/flake.nix`: `pname`, so `nix run` finds the binary.
- `just validate` converts the generated project to a workspace (crate under `crates/`, a second crate) and gates that too.

