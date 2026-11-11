#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Format Nix files with nixfmt",
  priority: framework("ice", confidence: 0.9, ease: 3.0, impact: 8.0),
  difficulty: 2,
  estimate: (files: 5),
  status: done(2026, 11, 11),
  tags: ("template", "tooling", "gating"),
  links: parent("land-the-corrected-renovation-backlog.typ"),
)

= Summary

`template/flake.nix` is the only Nix file and nothing formats or checks it. A generated project that adds modules has no `nix fmt` entry and no gate for `*.nix`. Add `nixfmt`, expose it as the flake formatter, and gate `*.nix` without growing a Justfile already at 199 of 210 lines.

= Scope

- `template/flake.nix`: add `nixfmt` to the dev shell and add `formatter = pkgs.nixfmt;` so `nix fmt` works.
- Add `template/.just/tools.just` and `mod tools '.just/tools.just'` in `template/Justfile`. `tools::nix-fmt` writes with `nixfmt`; `tools::nix-fmt-check` is the pure check over every `*.nix` outside `target/`.
- `template/Justfile`: `fmt` calls `tools::nix-fmt` so `fix-check` repairs a misformatted flake; `check` adds only `tools::nix-fmt-check`.
- `template/.mmz/config.yaml`: add a `just tools::nix-fmt-check` rule tagged `gate`, with `gates-meta` as its inputs.
- `template/outdatty.yaml`: add `.just/tools.just` to the `dev-docs` sources.
- Validate a generated bin and lib: a misformatted flake fails the gate, `just fmt` fixes it, and the gate turns green.

= Notes

`nix fmt` and `tools::nix-fmt-check` must run the same nixfmt package; a formatter pinned separately would let the two disagree.
