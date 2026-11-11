#import "@local/mindtape:0.4.0": *
#show: task.with(
  title: "Escape or reject quotes in the description placeholder",
  priority: framework("ice", confidence: 0.9, ease: 8.0, impact: 4.0),
  difficulty: 2,
  estimate: (files: 2),
  status: done(
    2026,
    11,
    9,
  )[the description regex rejects quote, backslash, CR/LF, C0 controls and DEL; cargo-generate >=0.16.0 enforces it before writing. scripts/test-description.sh is the regression.],
  tags: ("template", "ci"),
)

= Summary

`template/Cargo.toml:9` writes `description = "{{description}}"`. A prompt answer containing `"` or a newline produces invalid TOML, and any future docs or JSON generated from the same value breaks the same way. The validation generate uses `--define "description=Validation test project"`, which never exercises the case.

= Scope

- Reject a description containing `"` or a newline before scaffolding (a cargo-generate hook or the `scripts/validate.sh` wrapper), or TOML-escape it before it reaches `Cargo.toml`; pick one and state it in `template/cargo-generate.toml`.
- Add a `just validate` case with a quote in the description and assert the generated `Cargo.toml` parses (`cargo metadata --no-deps`); add a newline case only if the generator can pass one through.
- Do not use Liquid's `escape` for TOML; it escapes HTML, not TOML.
- Validate a generated bin and lib.

= Notes

A description is free text from a prompt, not a trusted manifest fragment; a refusal with a `hint:` line is better than a manifest that only fails at the first cargo command.
