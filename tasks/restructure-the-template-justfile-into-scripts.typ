#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Restructure the template Justfile into scripts",
  priority: framework("ice", confidence: 0.9, ease: 5.0, impact: 6.0),
  difficulty: 4,
  estimate: (files: 10),
  status: done(
    2026,
    11,
    9,
  )[template Justfile 411 -> 205 lines with \[doc\]/\[group\] labels; long bodies moved to .just/scripts/ and .just/scripts/\*\* is a gates-meta input. Workspace cover/CRAP globs fixed.],
  tags: ("template", "tooling", "gating"),
)

= Summary

At filing, `template/Justfile` was 411 lines, 241 of them comments. Multi-line bash lived inline in `test`, `cover`, `crap`, `_lcov-stale-reason`, `eject`, `release` and `mutants-diff`, and the comments repeat rationale that belongs in a script header. The sibling `../nix-bump-preview/Justfile` shows the low-comment shape: every public recipe has `[doc]` and `[group]`, long bodies live under `.just/scripts/`, and recipes are one line. Port that shape without changing behavior.

= Scope

- Add `[doc]` and `[group]` to every public recipe, using the groups `workflow`, `gate`, `dev`, `advisory`, `release` and `delegation`.
- Move the bodies of `test`, `cover`, `crap`, `lcov-stale-reason`, `eject`, `install-hooks`, `release` and `mutants-diff` into `template/.just/scripts/`; keep `.just/scripts/wt-*.sh` and `land-repro.sh` where they are.
- Keep `[arg('VERSION', pattern=...)]`, `[arg('DRY_RUN', long='dry-run', value='true')]`, `[no-exit-message]`, `[positional-arguments]` and `[parallel]` on the recipes that carry them.
- Keep one-line safety comments on `set shell`, `set ignore-comments`, `rust_roots`/`eject_root` and `cover_ignore`.
- `template/.mmz/config.yaml`: add `.just/scripts/**` to `gates-meta`, because a moved body decides what the gate runs.
- Fix `cover_ignore` to `(^|/)src/main\.rs|/registry/src/`, and change `crap`'s exclusion from `--exclude 'src/main.rs'` to `--exclude '**/main.rs'` so a workspace member's `main.rs` is excluded too.
- Target 170-210 lines for `template/Justfile`.
- Do not edit `template/CONTRIBUTING.md`, `template/AGENTS.md` or `template/README.md`; the docs tasks own them.
- Validate `just validate bin` and `just validate lib` (or the memoized `just mmz validate ...`) after the move.

= Notes

`../nix-bump-preview/Justfile` is the reference for `[doc]`/`[group]` and one-line recipes, not a file to copy verbatim: its recipes differ from this template's.
