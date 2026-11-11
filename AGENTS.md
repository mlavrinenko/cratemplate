Template files live in `template/`. See `template/AGENTS.md` for generated project conventions.

To validate changes: `just validate bin` and `just validate lib` (or `just mmz
validate <kind>` to skip a re-run when `template/` is unchanged). Both kinds
must pass — a template branch nothing validates rots silently.

A plain `just validate` proves the template but does not record a pass for the gate.
