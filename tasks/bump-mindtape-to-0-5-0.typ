#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Bump MindTape to 0.5.0 in the root flake",
  priority: framework("ice", confidence: 0.95, ease: 8.0, impact: 8.0),
  difficulty: 2,
  estimate: (files: 3),
  status: done(
    2026,
    11,
    9,
  )[root flake pins github:mlavrinenko/mindtape/v0.5.0; mt --version is 0.5.0 and mt check passes 48 tasks. The template task pin stays 0.4.0 and existing tasks stay on 0.2.0.],
  tags: ("tooling",),
)

= Summary

The root `flake.nix` in HEAD has no direct `mindtape` input: its inputs are `flake-utils`, `mmz` and `nixpkgs`, so `mt` is whatever the developer installed. The task corpus imports `@local/mindtape:0.2.0` in all 23 existing files, while `.mindtape/templates/task.typ` now imports 0.4.0. The CLI release and the Typst prelude are different versions, and `@local/mindtape:0.5.0` does not exist. Pin the CLI at 0.5.0 and the prelude at 0.4.0, and keep the 23 existing task files on 0.2.0 because 0.5.0 still reads them and `mt fix --check` keeps them.

The working tree at filing already carries the `flake.nix`, `flake.lock` and `.mindtape/templates/task.typ` edits; this task is the validation and landing record.

= Scope

- `flake.nix`: add a `mindtape` input pinned `github:mlavrinenko/mindtape/v0.5.0` with `inputs.nixpkgs.follows = "nixpkgs"`, and add `mindtape.packages.${system}.default` to the root dev shell.
- `.mindtape/templates/task.typ`: import `@local/mindtape:0.4.0`; do not touch `tasks/*.typ`, which stay on 0.2.0.
- `flake.lock`: record the new input.
- Do not add `mt` to `template/flake.nix`; generated projects do not track tasks unless the optional tracker task lands.
- Validate `nix develop --command mt --version` prints `mt 0.5.0`, `mt check -q` exits 0 and reports the current task count, and `mt fix --check` exits 0.

= Notes

`mt 0.5.0` is the CLI release; the Typst prelude is 0.4.0. `@local/mindtape:0.5.0` is not a package.
