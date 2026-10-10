#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Ship a generated JSON schema for every config a crate reads",
  priority: framework("ice", confidence: 0.8, ease: 6.0, impact: 5.0),
  difficulty: 3,
  estimate: (files: 3),
  status: proposed(2026, 10, 10),
)

= Summary
A crate that reads a config file (canibump.toml, a .mindtape/config.toml) is
edited by hand in an editor that cannot validate or complete it unless the
file names a schema. A hand-written schema goes stale; canibump generates its
own from the manifest types with schemars (8f11e92) and a test fails when the
committed copy drifts, the shape mindtape already uses.


= Scope
- `template/AGENTS.md`: the convention, any config a crate reads ships a JSON schema generated from its types, never hand-written.
- `template/` (bin): an opt-in `schema` subcommand, `schema/<crate>.schema.json`, a staleness test and `just schema`, as canibump does; `just install` writes it to `~/.config/<crate>/`.
- `just validate bin` covers it.

