#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Bump qahq to main so generated shells stop warning",
  priority: framework("ice", confidence: 0.9, ease: 6.0, impact: 6.0),
  difficulty: 2,
  estimate: (files: 3),
  status: done(
    2026,
    10,
    10,
  )[both validates green; the dev shell loads without warnings],
)

= Summary
Every generated project prints the stdenv.isDarwin and stdenv.isLinux deprecation warnings on each dev-shell load. qahq d9f932d fixes jscpd evaluation, but template/flake.lock pins qahq a10960e (0.4.0).

= Scope
- `template/flake.lock`: advance qahq to main (ae800a0), which also moves linecop 0.4.0 to 0.7.0, outdatty 0.7.0 and ejectest 0.5.0.
- Adapt template configs to the new tool versions.
- `just validate bin` and `just validate lib` pass, and `nix develop -c true` in a generated project prints no deprecation warning.

= Outcome

- `template/flake.lock` now pins qahq ae800a0. The shipped `.linecop.yaml` and
  `outdatty.yaml` needed no change for linecop 0.7, outdatty 0.7 or ejectest 0.5.
- `just eject` masked every linecop exit; it now masks only exit 1 (findings), so
  exit 2 (a broken run) fails it. `just validate` gained the regression.
- `just validate bin` and `just validate lib` pass. `nix develop --no-eval-cache
  -c true` in a generated project prints nothing, where the old lock printed two
  `stdenv` deprecation warnings.
