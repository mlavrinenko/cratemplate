#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Ship a generated JSON schema for every config a crate reads",
  priority: framework("ice", confidence: 0.8, ease: 9.0, impact: 4.0),
  difficulty: 1,
  estimate: (files: 1),
  status: proposed(2026, 10, 10),
)

= Summary
A crate that reads a config file (canibump.toml, a .mindtape/config.toml) is
edited by hand in an editor that cannot validate or complete it unless the
file names a schema. A hand-written schema goes stale; canibump generates its
own from the manifest types with schemars (8f11e92) and a test fails when the
committed copy drifts. The template has no crate that reads a config yet, so
the actionable part is one convention, not a `schema` subcommand.

= Scope
- `template/AGENTS.md` (or `docs/src/agents.typ` after the docs pipeline): one
  rule: any config a crate reads ships a JSON schema generated from its types,
  never hand-written, with a test that fails when the committed schema drifts.
- Do not add a `schema` subcommand, a `schema/` directory or `just schema`
  until a generated crate actually reads a config.
- When that happens, follow canibump's shape: generate from the manifest types
  with schemars, commit the schema, and test for drift.
- No template validation beyond `just fix-check`; this task is prose only.
