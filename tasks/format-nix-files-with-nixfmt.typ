#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Format Nix files with nixfmt",
  priority: framework("ice", confidence: 0.9, ease: 3.0, impact: 8.0),
  difficulty: 2,
  estimate: (files: 3),
  status: proposed(2026, 11, 9),
  tags: ("template", "tooling", "gating"),
)

= Summary

`template/flake.nix` is the only Nix file and nothing formats or checks it. A generated project that adds modules has no `nix fmt` entry and no gate for `*.nix`. Add `nixfmt`, expose it as the flake `formatter`, and gate `*.nix` files.

= Scope

- `template/flake.nix`: add `nixfmt` (or `nixfmt-rfc-style`, whichever the pinned nixpkgs provides) to the dev shell and add `formatter = pkgs.nixfmt;` so `nix fmt` works.
- `template/Justfile` (or `.just/scripts/nix-fmt.sh` after the restructure): `nix-fmt` runs `nixfmt --check` over every `*.nix` outside `target/`.
- `template/.mmz/config.yaml`: add a `just nix-fmt` rule with the `gate` tag and the `gates-meta` input.
- Add `(mmz "nix-fmt")` to `just check`.
- Validate a generated bin and lib: a misformatted flake fails, `nix fmt` fixes it, and `just check` is green.

= Notes

`nix fmt` and `nixfmt --check` must use the same formatter; a flake `formatter` that names a different package would make the two disagree.
