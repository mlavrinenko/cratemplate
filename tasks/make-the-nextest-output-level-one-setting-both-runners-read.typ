#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Make the nextest output level one setting both runners read",
  priority: framework("ice", confidence: 0.9, ease: 8.0, impact: 5.0),
  difficulty: 1,
  estimate: (files: 7),
  status: proposed(2026, 10, 10),
)

= Summary
The template claims `cargo llvm-cov nextest` accepts `--status-level` and ignores it, so `just test` carries the flag and `just cover` must not. Measured false on cargo-llvm-cov 0.9.0 and cargo-nextest 0.9.143: in a one-crate repro the flag cut 2 PASS lines to 0, and in canibump `--status-level pass` printed 178 PASS lines against a `fail` in `.config/nextest.toml`. The flag works; the comments that argue otherwise mislead.

= Scope
- `template/.config/nextest.toml`: state the level once, for both runners.
- `template/Justfile`: `just test` drops `--status-level fail`; its comments say only why the level lives in one place.
- `template/.mmz/config.yaml`, `template/outdatty.yaml`, `template/AGENTS.md`, `template/CONTRIBUTING.md`: drop the ignored-flag claim.
- `CHANGELOG.md`: add a Fixed entry.
- `just validate bin` and `just validate lib` pass.
