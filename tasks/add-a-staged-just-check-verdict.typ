#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Add a staged just check verdict",
  priority: framework("ice", confidence: 0.7, ease: 7.0, impact: 4.0),
  difficulty: 5,
  estimate: (files: 5),
  status: done(2026, 11, 11),
  tags: ("template", "gating"),
  links: parent("land-the-corrected-renovation-backlog.typ")
    + depends-on(
      "format-nix-files-with-nixfmt.typ",
      "add-a-crap-ratchet-baseline.typ",
      "offer-optional-mindtape-in-generated-projects.typ",
      "tune-jscpd-and-add-a-clone-baseline.typ",
    ),
)

= Summary

`just check` is one `[parallel]` recipe with 11 arms. Every arm streams its own log on a miss, even when only one fails, and the fast checks and the builds are interleaved. MindTape's `check.sh` runs stages, prints one verdict on green, and prints only the failed stage's log on red. Port that shape, keeping `cover` and `crap` opt-in.

= Scope

- `template/.just/scripts/check.sh`: run two batches in order, each batch's arms in parallel. Fast: `fmt-check`, `machete`, `check-file-size`, `check-dry`, `docs-md-check`, `lint::workflows`, `lint::shellcheck`, `lint::doc`, plus the `nix-fmt-check` and `check-tasks` arms its dependencies add. Build: `clippy`, `test`, `outdatty-check`. Run each arm as `mmz just <arm>`, keep the arm list in one place, and do not hardcode its length.
- Green prints one verdict; red prints only the failed batch's captured logs and exits non-zero. A failed fast batch does not start the build batch.
- `template/Justfile`: `check STAGE=''` delegates to the script; `just check cover` also runs `cover` and `crap`; keep `[doc]`/`[group]`.
- `template/.mmz/config.yaml`: keep every arm's rule and `gate` tag; do not tag `cover`/`crap`.
- Keep `just check` usable from the pre-commit hook and `template/.config/wt.toml` without changing their command.
- Validate a green run, a red fast arm, a red build arm, and `just check cover` in a generated bin and lib.

= Dependencies

Runs after `format-nix-files-with-nixfmt`, `add-a-crap-ratchet-baseline`, `offer-optional-mindtape-in-generated-projects` and `tune-jscpd-and-add-a-clone-baseline`: each adds or reshapes an arm this script batches. The old "restructure the Justfile first" dependency is dropped; this task adds the one script it needs.

= Notes

The default gate stays offline and fast. A stage that needs network (`deny`) or minutes of CPU (`cover`/`crap`) is opt-in, not a hidden extra stage.
