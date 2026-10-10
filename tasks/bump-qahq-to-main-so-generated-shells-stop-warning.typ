#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Bump qahq to main so generated shells stop warning",
  priority: framework("ice", confidence: 0.9, ease: 6.0, impact: 6.0),
  difficulty: 2,
  estimate: (files: 3),
  status: proposed(2026, 10, 10),
)

= Summary
Every generated project prints the stdenv.isDarwin and stdenv.isLinux deprecation warnings on each dev-shell load. qahq d9f932d fixes jscpd evaluation, but template/flake.lock pins qahq a10960e (0.4.0).

= Scope
- `template/flake.lock`: advance qahq to main (ae800a0), which also moves linecop 0.4.0 to 0.7.0, outdatty 0.7.0 and ejectest 0.5.0.
- Adapt template configs to the new tool versions.
- `just validate bin` and `just validate lib` pass, and `nix develop -c true` in a generated project prints no deprecation warning.
