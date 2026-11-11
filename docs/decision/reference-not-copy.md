# Decision: reference, generate, copy

Status: accepted, 2026-11-11.

`template/` is copied once per project, so every copied byte can drift and no
copy records where it came from. [`../research/template-sync.md`](../research/template-sync.md)
surveys the options and recommends consuming what can be consumed by reference
and keeping the residual copied. This record fixes that split for each kind of
piece in `template/`. The survey holds the reasoning; this record holds the
decision and cites the survey by section.

## Decision

- **qahq is the one versioned flake input the template owns**, pinned by commit
  `58f9ec9` in `template/flake.nix` and locked in `template/flake.lock`. Every
  qahq tool (`cargo-crap`, `ejectest`, `jscpd`, `linecop`, `mmz`, `outdatty`)
  is referenced as `qahq.packages.${system}.<tool>` and never copied into
  `template/`, so the template keeps no tool source that can drift.
- **Generated Markdown stays generated.** `AGENTS.md`, `README.md` and
  `CONTRIBUTING.md` are rendered from `template/docs/src/*.typ`; the committed
  output is a build product, never edited.
- **The rest is copied.** Justfile bodies, scripts, hooks, workflows, config,
  prose sources and the project skeleton are copied into every generated
  project, then upgraded by re-copying from a template revision whose
  `just validate bin` and `just validate lib` both passed.
- **Baselines are copied state.** A CRAP or clone baseline records the
  project's own scores. It is generated and regenerated inside the project and
  never synced from the template.

`nixpkgs`, `naersk` and `flake-utils` are ordinary upstream inputs that the
template consumes; they are not template-owned surface and need no
classification here.

## Classification

| `template/` piece | Class | Coupling | Upgrade path |
| --- | --- | --- | --- |
| qahq tool set | (a) versioned flake input | referenced by attribute path in the devShell; the pin is the input URL plus `flake.lock` | bump the URL commit and lock, run both validate kinds; a project bumps with `nix flake update qahq` on its own cadence |
| `AGENTS.md`, `README.md`, `CONTRIBUTING.md` | (b) generated file | each source declares its output in a `<docs-md>` block; `docs/generate-md.sh` renders it and `just docs-md-check` fails on drift (an mmz rule in `just check`) | edit the Typst source, run `just docs-md`, commit source and output together; at the template root that is `just docs-sync` |
| `docs/src/*.typ`, `docs/src/lib.typ`, `docs/generate-md.sh` | (c) copied prose and script | copied verbatim or Liquid-rendered at generation; the project owns its sources after that | re-copy the file or hunk from a green template revision, then run `just check` in the project |
| `Justfile`, `.just/*.just` | (c) copied Justfile bodies | bodies call the copied scripts and the referenced qahq tools; no line records their template origin | same re-copy; a repo-specific recipe stays repo-specific instead of forcing the template's |
| `.just/scripts/*.sh` | (c) copied scripts | invoked by Justfile bodies; inputs and outputs are named in `.mmz/config.yaml` | same re-copy |
| `.githooks/*`, `.config/wt.toml` | (c) copied hooks | the pre-commit hook asserts gate freshness; the `wt` hooks fire on fork and land; the dev shell installs them | same re-copy |
| `.github/workflows/*.yml`, `.github/dependabot.yml` | (c) copied workflows | CI calls the same Justfile gate; Dependabot owns Cargo and Actions | same re-copy, then read the YAML diff instead of trusting it |
| `clippy.toml`, `deny.toml`, `rustfmt.toml`, `rust-toolchain.toml`, `release.toml`, `outdatty.yaml`, `.linecop.yaml`, `.mmz/config.yaml`, `.config/nextest.toml`, `.cargo/mutants.toml`, `renovate.json`, `.envrc`, `.gitignore`, `.gitattributes` | (c) copied config | read by the copied scripts and the dev shell; `cargo-generate.toml` decides render versus verbatim copy | same re-copy; a project may diverge deliberately |
| `.config/crap-baseline.json`, `.config/jscpd-baseline.json` | (c) copied state | the scores describe the generated project's own code, not the template's | regenerate in the project with its own `crap-baseline` or `dry-baseline` recipe; never copy a baseline back |
| `Cargo.toml`, `src/`, `tests/`, `CHANGELOG.md`, `LICENSE-*`, `www/index.html` | (c) copied skeleton | rendered once with the project name, description, license and crate kind | owned by the project from its first commit; later template edits to the skeleton are not re-applied |
| `flake.nix`, `flake.lock` | (c) copied config that carries the one reference | pins qahq, nixpkgs, naersk and flake-utils; `just validate` requires the generated lock to match the template's byte for byte | re-copy on a template bump, or let the project update its own inputs; the qahq tools stay referenced either way |

## Why not reference more

- Justfile bodies have no mature from-Nix generator. The survey's
  "Recommendations" calls them the one artifact type with no strong prior art
  and points at the stalled `just-flake` (§4).
- The projen-style "generate everything, add escape hatches" model is overkill
  for a small, homogeneous Rust/Nix/`just` config surface (§2 and
  "Recommendations").
- Workflow YAML must stay readable in a PR diff. The survey recommends
  generating at most the matrix, as `nix-github-actions` does (§5).
- Prose is per-repo by nature; a reference would fight the edits every project
  makes to its README and CONTRIBUTING.
- Whole-tree patch merge (cruft/copier) is well-trodden for residual text (§1),
  but it inherits a per-repo update cadence and conflicts that must fail
  loudly ("What fails at scale", "Recommendations"). No such tool is adopted
  now. If copy drift becomes the dominant cost, that is the precedented next
  step, not a bespoke generator.

## Consequences

- A qahq tool upgrade reaches every project as an ordinary `flake.lock` bump.
  No tool source is copied and no template release is needed.
- A copied file upgrade is a review, not a merge: take the template version,
  replay the repo-specific edits and rerun `just check`.
- The template's validation gate is the quality boundary for copies. A file
  copied from a red template revision is unsupported.

## Revisit when

- A second template-owned tool set appears that cannot ride the qahq input.
- Copy drift dominates maintenance across sibling projects.
- `cargo-generate` grows an update path, or a partial re-sync tool is adopted.
  The survey expects neither soon.
