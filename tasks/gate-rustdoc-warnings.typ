#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Gate rustdoc warnings",
  priority: framework("ice", confidence: 0.9, ease: 8.0, impact: 4.0),
  difficulty: 1,
  estimate: (files: 2),
  status: done(
    2026,
    11,
    9,
  )[lint::doc runs RUSTDOCFLAGS=-D warnings cargo doc --workspace --no-deps --document-private-items; wired into template check and root lint.],
  tags: ("template", "gating"),
)

= Summary

`just check` gates fmt, clippy, tests, machete, file size, copy-paste and outdatty, but never builds docs. A broken intra-doc link or an invalid doc attribute therefore ships. Add a rustdoc warnings gate; it catches broken links and malformed docs, not missing documentation.

= Scope

- `template/Justfile`: add a `docs-check` recipe that runs `RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps --document-private-items --quiet`.
- `template/.mmz/config.yaml`: add `just docs-check` with the `gate` tag and the `rust`/`gates-meta` inputs.
- Add `(mmz "docs-check")` to `just check`; keep it out of `fix-check` only if its build time proves too high.
- Validate a generated bin and lib: a broken intra-doc link reds `just check`, and a clean tree stays green.

= Notes

`--document-private-items` makes a private item's broken link visible too; drop it only if a downstream crate objects to private-item docs.
