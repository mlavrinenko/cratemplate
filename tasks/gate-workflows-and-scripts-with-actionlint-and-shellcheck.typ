#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Gate workflows and scripts with actionlint and shellcheck",
  priority: framework("ice", confidence: 0.9, ease: 7.0, impact: 7.0),
  difficulty: 3,
  estimate: (files: 6),
  status: done(
    2026,
    11,
    9,
  )[template lint::workflows, lint::shellcheck and lint::doc; root just lint runs actionlint and shellcheck; both tools ship in the dev shells. SC2016/SC2069/SC2012 disables where shellcheck cannot see the intent.],
  tags: ("template", "ci", "gating"),
)

= Summary

`template/flake.nix` ships neither `actionlint` nor `shellcheck`. The workflow files in `template/.github/workflows/` and the shebang scripts in `template/.just/scripts/`, `template/.githooks/` and root `scripts/` are ungated. `template/.just/scripts/land-repro.sh:34` deliberately embeds `$1` in a single-quoted `printf` (SC2016), so the shell gate must allow that one case or run at warning severity.

= Scope

- `template/flake.nix`: add `actionlint` and `shellcheck` to the dev shell.
- `template/Justfile`: `workflows-check` over `template/.github/workflows/*.yml`, and `shell-check` over shebang-aware files under `.just/scripts/`, `.githooks/` and root `scripts/`; add both to `just check` with `gate`-tagged mmz rules.
- `template/.mmz/config.yaml`: add scopes for `.github/workflows/**`, `.just/scripts/**`, `.githooks/**` and the script set.
- `template/.just/scripts/land-repro.sh:34`: add a targeted `# shellcheck disable=SC2016` (or run shellcheck at warning severity), never a blanket disable.
- Root `Justfile`: a root lint for `scripts/*.sh` and `.github/workflows/*.yml`.
- Validate `just check` in a generated bin and lib, and a deliberately malformed workflow or script fails the new arms.

= Notes

Run shellcheck on files with a bash or sh shebang, not on every `*.sh` name: `land-repro.sh` and the root helpers already carry one, but a future script may not.
