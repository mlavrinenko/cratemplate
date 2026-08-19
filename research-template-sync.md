# Prior art survey: keeping many downstream projects in sync with an upstream template

Scope: for a scaffolder like `cargo-generate`/`cookiecutter`, generation is one-shot — the
generated repo never hears about later improvements to the template (CI config, `Justfile`
recipes, lint config, git hooks). This is usually called "template drift" or "scaffolding
drift". This report surveys prior art for closing that loop, across five areas, with an
honest account of what breaks in practice.

Research method: WebSearch/WebFetch against primary docs, GitHub issues/repos, and a small
number of practitioner blog posts. Two sources (an Astronomer.io blog post and a
Brownian-Tech blog post) 403'd on fetch and are cited by title/URL only, not by fetched
content — flagged inline.

---

## TL;DR

**Not solved, and not going to be.** There is no single dominant 2026 answer; instead there
are three genuinely different strategies, each with a real ecosystem behind it, and the
mature projects in this space have converged on the same conclusion: **pick the strategy per
artifact-type, not per project.**

1. **Patch-merge (copy once, then re-diff-and-merge later).** Cookiecutter/cruft, Copier.
   Mechanically the most "generic" — works for any generated tree — but it is literally a
   3-way `git merge` in a costume, so it inherits all of git merge's failure modes
   (silent semantic conflicts, `.rej` files nobody looks at, conflict markers landing on
   `main` via bot PRs). Confirmed to degrade specifically at scale: someone has to actually
   run the update on every repo, and organizations report update fatigue at as few as "hundreds
   of customers" ([Medium/bctello8](https://medium.com/@bctello8/standardizing-dbt-projects-at-scale-with-cookiecutter-and-cruft-20acc4dc3f74)).

2. **Regenerate-from-source-of-truth ("config files are build artifacts, not source").**
   projen is the reference implementation: you write `.projenrc.ts`, projen synthesizes
   every config file, marks them read-only, and CI fails if `npx projen` produces a diff.
   This *structurally* eliminates drift for anything projen owns, at the cost of needing an
   "escape hatch" API (`addOverride`, JSON-Patch) for anything it doesn't yet model, and a
   hard requirement that the generator itself run in every downstream repo forever.

3. **Composable reference, not copy.** Don't scaffold a monolith at all — ship shared
   logic as a *versioned, referenced* unit (a package, a plugin, a Nix flake input, a
   `uses:` reference, an `extends:` URL) that downstream repos pin a version of and pull in
   deliberately. This sidesteps drift by construction (nothing is ever copied to go stale)
   but only ever covers the part of the config that was designed to be a module — Justfile
   *bodies*, arbitrary README prose, and one-off CI steps still don't fit.

None of the regeneration/patch tools have a serious answer for **partial, in-place adoption**
into an existing project (see cargo-generate §1) — everyone reaches for ad hoc scripting or a
one-off cherry-pick there. And there is essentially **no prior art for generating a Justfile's
recipe *bodies* from Nix** beyond one small (54-star, stalled since mid-2024) project,
`juspay/just-flake` — see §4. That is a real gap, not a search failure.

---

## Table: tools / approaches

| Name | Ecosystem | Mechanism | Provenance record | Handles local edits? | Maturity (Aug 2026) |
|---|---|---|---|---|---|
| [cruft](https://github.com/cruft/cruft) | Python/cookiecutter | Regenerate + 3-way merge (`cruft update`) | `.cruft.json` (template repo + commit hash) | Yes, via git 3-way merge; conflicts left as merge markers | 1.6k★, last push Dec 2024, 94 open issues — stalling |
| [Copier](https://copier.readthedocs.io/en/latest/updating/) | Python, language-agnostic output | Regenerate + smart 3-way diff/merge (`copier update`) | `.copier-answers.yml` (`_src_path`, `_commit`) | Yes — `--conflict inline` (markers) or `rej` (`.rej` files); `copier recopy` discards local diffs entirely | 3.5k★, actively pushed, 146 open issues — most active tool in this class |
| [cookiecutter](https://github.com/cookiecutter/cookiecutter) itself | Python | One-shot generate only | none | No update mechanism at all (by design; see [issue #784](https://github.com/cookiecutter/cookiecutter/issues/784), [#2119](https://github.com/cookiecutter/cookiecutter/issues/2119)) | mature, huge install base, feature frozen re: updates |
| [retrocookie](https://github.com/cjolowicz/retrocookie) | Python/cookiecutter | **Reverse** sync: cherry-picks commits from a generated instance back into the template (via `git-filter-repo`) | n/a (operates on the template repo's git history) | N/A — it's for template authors, not consumers | niche, small, last-resort tool for template maintainers |
| [cookiecutter-project-upgrader](https://pypi.org/project/cookiecutter-project-upgrader/) | Python/cookiecutter | Regenerate + rely on `git merge` of the two generated trees | none beyond git history | Yes, via ordinary git merge | small utility, pre-dates cruft's dominance |
| Yeoman | Node | One-shot generate; no first-party update | none | No — [issue #474](https://github.com/yeoman/yo/issues/474) is an 8+ year open feature request; users hand-roll "regenerate old + regenerate new + diff + apply" | de facto abandoned for this use case |
| scaffdog | Node | One-shot **snippet**/file generation per invocation, not whole-project | none | N/A — designed for repeated small-file generation (e.g. new component), not project sync | active but different problem class |
| cargo-generate | Rust | One-shot generate only; `--init` writes into an existing dir but does not re-diff | none | No re-sync at all. Partial/incremental apply into an existing project is an **open RFC since 2021** ([#291](https://github.com/cargo-generate/cargo-generate/issues/291)), never implemented | no update story, confirmed |
| Backstage Scaffolder (Software Templates) | Any (org-wide IDP) | One-shot generate via `template.yaml` actions; "Start Over" only *re-runs from scratch*, does not diff | task history, not file-level | No | mature, widely deployed, but same one-shot limit as cookiecutter |
| **projen** | Node (any output language) | Regenerate-from-source (`.projenrc.ts` → synth); generated files marked read-only, CI diff-checks them | the `.projenrc.ts`/`.projenrc.js` itself *is* the provenance | Only via typed "escape hatches" (`addOverride`, JSON-Patch `patch()`, `addDeletionOverride`) — never direct file edits | 2.9k★, very active, 245 open issues — the most-cited "regenerate" model |
| Nx (`nx migrate`) | JS/TS monorepo | Two-phase: bump packages → generate `migrations.json` → run codemods against source | `migrations.json` (ephemeral, consumed then discarded) | Codemods are best-effort; users report broken builds and "missing migrations" jumping major versions ([#9719](https://github.com/nrwl/nx/issues/9719), [#20407](https://github.com/nrwl/nx/issues/20407)) | mature, actively maintained, known to be fragile across >1 major version jump |
| Angular schematics (`ng update`) | Angular | Same codemod-migration model as Nx, first mover for this pattern | `migrations.json` manifest per package | Applies rule-based AST transforms; reviewed as a diff before commit | mature, stable, Angular's own upgrade path since ~2018 |
| Rush (rig packages) | JS/TS monorepo | **Reference, not copy**: config `"extends"`s an npm package | npm package version (semver) | N/A — nothing to merge, config is inherited live | mature (Microsoft-maintained) |
| moon | Rust-built, polyglot monorepo tool | **Reference**: `.moon/toolchain.yaml` `extends:` an HTTPS URL/path, docs explicitly recommend versioning the URL itself | the extended URL (author must version it manually) | N/A | active, smaller ecosystem |
| Gradle convention plugins | JVM | **Reference**: shared build logic packaged as a precompiled script plugin, applied via `plugins {}` | the plugin's published version | N/A | mature, official Gradle-recommended pattern |
| Terraform modules | HCL | **Reference**: registry module + semver constraint (`~>`) | the pinned version constraint in the `module` block | N/A (state can still drift from config, a related but different problem) | mature, ecosystem standard |
| Ansible collections/roles | Ansible | **Reference**: Galaxy collection/role pinned in `requirements.yml`, resolved at CI/install time | `requirements.yml` pins | N/A | mature, ecosystem standard |
| Bazel (bzlmod) | Bazel | **Reference**: `MODULE.bazel` declares versioned module deps, compatibility levels catch breaking changes | `MODULE.bazel` + lockfile | N/A | mature, actively displacing WORKSPACE |
| pre-commit (pre-commit.com) | polyglot (git hooks) | **Reference**: `.pre-commit-config.yaml` pins `repo` + `rev` (tag/SHA) per hook source | `rev:` per hook repo | N/A (hooks are invoked, not copied — `pre-commit autoupdate` bumps `rev` mechanically) | mature, ecosystem standard for this one artifact type |
| GitHub reusable workflows (`workflow_call`) | GitHub Actions | **Reference**: caller `uses:` a workflow ref (branch/tag/SHA), passes `inputs`/`secrets` | the `uses:` ref | Caller can only customize what the callee explicitly exposed as `inputs`/`outputs`; composite actions allow steps before/after | mature, actively evolving limits (nesting 4→10 levels, 20→50 workflow cap over the past few years) |
| GitHub composite actions | GitHub Actions | **Reference**, but collapses to a single step in the caller's job — steps can be added before/after | the `uses:` ref | Better than reusable workflows for "one extra step" since caller controls step ordering around it | mature |
| `cachix/git-hooks.nix` (nee pre-commit-hooks.nix) | Nix | **Regenerate**: Nix config → generates `.pre-commit-config.yaml` (or a symlink to a Nix-store one) + a `pre-commit-check` derivation | the flake input pin | N/A — file is generated fresh each `nix develop`, not diffed against a committed copy | 854★, very active |
| `numtide/treefmt-nix` | Nix | **Regenerate/avoid**: for the flake-parts path it doesn't even materialize `treefmt.toml` — it wraps the `treefmt` binary with a config closure | the flake input pin | N/A | 638★, very active |
| `nix-community/nix-github-actions` | Nix | **Library, not generator**: turns a flake's `packages`/`checks` attrs into a JSON *matrix value* your hand-written workflow YAML splices in — does **not** emit a whole `.yml` | the flake input pin | N/A — workflow YAML itself is still hand-maintained | 154★, moderately active |
| `nialov/actions.nix` | Nix/Gitea+GitHub | **Regenerate**: nix module → full workflow YAML file | the flake input pin | N/A | small, niche |
| `juspay/just-flake` | Nix | **Regenerate**: flake-parts module → `just-flake.just` symlink, imported by a hand-written root `justfile` | the flake input pin (module API itself marked unstable) | N/A — recipe *bodies* still come from Nix options, `justfile` string literals inside `.nix` | 54★, stalled since Jun 2024 — the only hit for "generate Justfile from Nix" |
| `nix-community/nixago` | Nix | **Regenerate, general-purpose**: arbitrary Nix data → any `pkgs.formats`-supported config file, linked via shellHook | the flake input pin | N/A | 152★, not archived but stale (last push May 2025), 10 open issues |
| snowfall-lib / haumea / `vic/import-tree` | Nix | **Composable file-tree convention**, not sync: auto-imports a directory tree into flake outputs so *new* modules "just appear" — doesn't address existing generated files drifting | n/a (organizational pattern, not a sync mechanism) | N/A | active, moderate adoption |
| srvos, clan, divnix/std, dream2nix | Nix | Shared, referenced NixOS/module or packaging frameworks (fleet configs, DevOps "cells", polyglot packaging) — same reference-not-copy model as flake inputs generally | flake input pin | N/A | active OSS projects, real production users, but orthogonal to "sync a scaffolded repo" |

---

## 1. Re-generation / patch-based sync tools

**Cruft** (built on cookiecutter) stores `.cruft.json` at the project root with the template
repo URL and the commit hash used to generate the project
([cruft.github.io](https://cruft.github.io/cruft/), [github.com/cruft/cruft](https://github.com/cruft/cruft)).
`cruft check`/`cruft diff` compare against the template at HEAD; `cruft update` regenerates the
project from the new template commit and applies the diff via `git apply`, falling back to a
3-way merge when the direct patch doesn't apply cleanly. That fallback is exactly where things
get messy in practice: cruft issue [#287](https://github.com/cruft/cruft/issues/287) ("Cruft
update sometimes fails and does a fallback to 3-way merge") and
[#47](https://github.com/cruft/cruft/issues/47) ("cruft now fails to apply, without providing
conflict to manually resolve") both describe updates that silently apply with unresolved
conflict content, or fail with "repository lacks the necessary blob to fall back on 3-way
merge" — a genuinely confusing git-internals error to hand a template consumer. Someone also
asked directly whether cruft can *force* a full re-sync, discarding local drift
([#120](https://github.com/cruft/cruft/issues/120)) — as of this survey that issue is still
open with no resolution, i.e. there's no "just make it match the template" escape hatch.

A Medium post on standardizing DBT projects at an analytics company running "ELT pipelines for
hundreds of customers" is a rare concrete at-scale account: cookiecutter+cruft worked as an
initial standardization mechanism, but the author's stated failure mode is organizational, not
technical — *"[cruft] relies on people actually doing the cruft update, and their engineers
simply have too much going on to go and run a cruft update on all their projects every week"*
([Medium/bctello8](https://medium.com/@bctello8/standardizing-dbt-projects-at-scale-with-cookiecutter-and-cruft-20acc4dc3f74)).
This mirrors what the composable-reference tools (§3) are built to avoid entirely: if nothing
is copied, there's nothing that requires a human to remember to re-run a sync.

**Copier** is the more actively developed sibling: `.copier-answers.yml` records `_src_path`
and `_commit`, and `copier update` performs what its docs call a three-way merge — regenerate
from the old `_commit`, regenerate from the new template ref, diff the two, then apply that
diff against the current (possibly hand-edited) project tree
([copier.readthedocs.io/updating](https://copier.readthedocs.io/en/latest/updating/)). Conflict
handling is explicit and dual-mode: `--conflict inline` (default) leaves `<<<<<<<` markers like
a normal git merge; `--conflict rej` writes separate `.rej` files instead. There is also
`copier recopy`, which explicitly throws away the smart-diff algorithm and local
customizations — the "force sync" cruft doesn't have. The docs' single loudest warning is:
never hand-edit `.copier-answers.yml`, because it is the ground truth the diff algorithm trusts
— corrupt it and "smart diff" silently produces garbage merges.

Copier's problem at scale shows up in **automation**, not manual use: a Renovate issue
([renovatebot/renovate#31600](https://github.com/renovatebot/renovate/issues/31600)) reports
that when Renovate runs `copier update` as part of an automated PR and the merge produces
conflict markers, Renovate still reports the update as *successful* and just leaves a comment —
meaning a bot can open (and a reviewer can miss) a PR with literal `<<<<<<< HEAD` markers
committed into a config file. The fix requested is to make Renovate treat any conflict as a
hard failure instead of a soft comment.

**cookiecutter** itself has no update story and never intends to: issues
[#784](https://github.com/cookiecutter/cookiecutter/issues/784) and
[#2119](https://github.com/cookiecutter/cookiecutter/issues/2119) are the "please add
update support" threads, both answered by pointing at cruft/copier as the tools that solve
this, not cookiecutter core. Worth noting there's also a *reverse* tool,
[retrocookie](https://github.com/cjolowicz/retrocookie): it does the opposite direction — you
develop inside a generated instance (easier: real files, no `{{ jinja }}` noise), then
retrocookie uses `git-filter-repo` to rewrite selected commits, re-inserting Jinja variables in
place of their expanded values, and cherry-picks them back into the template repo. This is a
neat trick but only useful to *template authors*, not to the fleet of consumers.

**Yeoman** never built a first-party update mechanism at all.
[yeoman/yo#474](https://github.com/yeoman/yo/issues/474) (open since ~2016) is the tracking
issue; the reporter's own words are blunt: *"The diff of any generated file which has been
changed is quite unusable."* A workaround folk-remedy is described in the thread — regenerate
with the old generator version, commit; regenerate with the new version, commit; diff the two
commits; drop both commits and apply the diff as a patch to the real project — which is
literally cruft/copier's algorithm, reinvented by hand, with git as a dependency the maintainer
was reluctant to require. No maintainer response is recorded.

**scaffdog** ([scaff.dog](https://scaff.dog/), [github.com/scaffdog/scaffdog](https://github.com/scaffdog/scaffdog))
is a different animal: Markdown-driven templates you invoke repeatedly to stamp out one new
file/component at a time (`scaffdog generate`), not a whole-project generator with a
once-per-project identity to track. There is no update/sync concept because there is no
persistent "this project was generated from template X at commit Y" relationship to begin
with — each invocation is independent. Worth naming explicitly as **prior art that does not
apply** to the drift problem, since it's easy to mistake for a competitor to cruft/copier.

**cargo-generate** has genuinely no update story. The RFC to support generating a *partial*
template into an already-existing project
([cargo-generate/cargo-generate#291](https://github.com/cargo-generate/cargo-generate/issues/291),
filed Feb 2021) is exactly the feature this survey's target project (`cratemplate`, a
cargo-generate template) would need for post-generation sync, and it never shipped — the
thread's own maintainer commentary is telling: one collaborator says *"I am a bit conflicted as
to what I think of the feature as a whole — somehow it is as if it is a simple job for a
script, not really a feature?"* and sketches the workaround as `cargo generate --git … --name
$tmp && cp $tmp/pattern .` — i.e., "roll your own with a temp directory and `cp`." No later
maintainer follow-through is visible in the (still-open, unimplemented) thread.

**Backstage Software Templates** (Spotify's Backstage; the `Scaffolder` plugin,
[backstage.io/docs/features/software-templates](https://backstage.io/docs/features/software-templates/writing-templates/))
is the org-wide "golden path" version of the same one-shot problem: a `template.yaml`
describes parameters and `fetch:template`/`publish:github`/`catalog:register` actions; a
generated repo gets a `catalog-info.yaml` for auto-discovery in the software catalog. The one
extra feature over cookiecutter is "Start Over" in the task-history UI, which simply re-runs
the whole template from scratch with the same parameters — it is not a diff/merge against the
already-generated repo, so it offers no real update path either. Backstage's own golden-path
narrative implicitly names the problem it's trying to prevent — ad hoc copy-paste of an
existing service — without actually solving re-sync once drift has already happened.

---

## 2. Generation-from-source-of-truth ("projen model")

**projen** ([github.com/projen/projen](https://github.com/projen/projen),
[projen.io](https://projen.io/)) inverts the whole framing: config files are not source, they
are *build output*. You write `.projenrc.ts` (or `.js`/`.py`/`.java`), instantiate a typed
`Project` subclass (e.g. `TypeScriptProject`, `AwsCdkTypeScriptApp`), and running `npx projen`
synthesizes `package.json`, `tsconfig.json`, `.github/workflows/*.yml`, `.eslintrc`, etc. Every
generated file gets marked read-only on the filesystem and stamped with a header saying it's
managed by projen; CI is expected to run `projen` and fail the build if the synth output
differs from what's committed (a drift gate baked into the model itself, not bolted on).
Because dozens/hundreds of repos can all point their `.projenrc` at the same custom project
type, a single change to that shared base class propagates everywhere the next time each repo
runs `projen` — this is projen's actual answer to fleet-wide drift, and it's structural rather
than diff-based.

The **escape hatch** system is the load-bearing complexity here
([projen.io/docs/concepts/escape-hatches](https://projen.io/docs/concepts/escape-hatches/)):
when projen's typed API doesn't yet model a setting you need, you drop to `addOverride()`
(dot-notation path into the synthesized object), `patch()` (RFC 6902 JSON-Patch — `add`,
`remove`, `replace`, `move`, `copy`, `test`), or `addDeletionOverride()`. These operate on the
*in-memory* object model before it's serialized, not on the final file text, so they survive
regeneration by construction — but the docs are candid that this is the fallback for when
projen "doesn't have the right high-level or low-level APIs," which is itself an admission that
the typed model can't and won't cover 100% of every ecosystem's config surface. AWS's own PDK
mirrors this same escape-hatch pattern for monorepo configs
([aws.github.io/aws-pdk .../escape_hatches.html](https://aws.github.io/aws-pdk/developer_guides/monorepo/escape_hatches.html)).
Practically, this means: adopting projen is an all-in bet — the moment you need something
projen hasn't modeled, you're writing JSON-Patch against projen's internal object shape
instead of editing YAML directly, which is a real cognitive tax relative to "just edit the
file." (I could not find sustained public "projen is painful because X" discussion threads on
HN or Reddit — searches came back empty or off-topic; this appears to be a genuine gap in
public discourse rather than a sign projen is friction-free. Its own repo has 245 open issues
against 2.9k stars, roughly proportionate to an actively-used, actively-complained-about tool.)

**Nx** (`nx migrate`) solves a narrower but related problem: not "keep config files generated"
but "codemod source *and* config forward when the framework itself changes." The docs describe
a two-phase flow — `nx migrate <version>` first bumps `package.json` and produces
`migrations.json` (a list of pending code transformations), then a second `nx migrate --run-migrations`
step actually executes each generator-shaped codemod against your files
([nx.dev/docs/reference/nx/migrations](https://nx.dev/docs/reference/nx/migrations),
[nx.dev/docs/extending-nx/migration-generators](https://nx.dev/docs/extending-nx/migration-generators)).
This is real prior art for "ship an automated codemod alongside a breaking change," and it's
proven fragile exactly where you'd expect: issue
[nrwl/nx#9719](https://github.com/nrwl/nx/issues/9719) ("Nx Migrate broke my build") and
[#20407](https://github.com/nrwl/nx/issues/20407) ("migrating from nx 15.8.5 to 17.1.3 has
missing migrations") both describe multi-major-version jumps silently skipping migrations that
were only ever written to run sequentially. The documented workaround is the same one every
codemod-based migration system converges on: never skip versions, migrate one major release at
a time.

**Angular schematics / `ng update`** is the pattern Nx's migration system is visibly modeled
on, and predates it: a package ships a `migrations.json` manifest mapping semver ranges to
schematic factory functions; `ng update @angular/core` runs whichever migrations apply between
your installed version and the target, each schematic manipulating the project's "virtual file
tree" via `Rule`/`Tree` APIs before writing to disk
([angular.dev/tools/cli/schematics](https://angular.dev/tools/cli/schematics),
[angular.love — writing migration schematics](https://angular.love/angular-schematics-deep-dive-part-4-writing-migration-schematics-with-ng-update)).
This is genuinely a *different* category from cruft/copier/projen: it doesn't try to keep a
config file's entire content in lockstep with a template — it ships a one-time, version-scoped
*transform* alongside each breaking release. It composes well with reference-based sharing
(§3) but does nothing for drift in content that was never a "migration," e.g. arbitrary
Justfile recipes a template author adds later without bumping anything.

**Rush**, **moon**, **Dagger**, and **Earthly** don't really belong in the "regenerate" bucket
at all — investigating them surfaced that they're closer to §3's reference model:
- **Rush** rig packages let many projects extend a single versioned npm package for shared
  tool config (ESLint/TS/Jest settings), via each config file's own `extends` field pointing at
  the rig — nothing is copied, so nothing drifts; you bump the rig's semver instead
  ([rushstack.io](https://rushstack.io/)).
- **moon** has an explicit `extends:` key in `.moon/toolchains.yaml` pointing at an HTTPS URL
  or local path; the docs are unusually candid that "inheriting an upstream configuration can
  be dangerous as the settings may change at any point," and recommend the *template author*
  version the URL itself (e.g. `toolchain-v2.yml`) so consumers control their own upgrade
  timing — a hand-rolled semver-less analogue of Rush's npm-version pinning
  ([moonrepo.dev/docs/guides/sharing-config](https://moonrepo.dev/docs/guides/sharing-config)).
- **Dagger** reframes the problem instead of solving template drift directly: pipelines are
  written as real code (Go/Python/TS/CUE) and run in containers, so the "config file drift"
  category mostly disappears because there's much less declarative YAML to drift in the first
  place — but that pushes the sync problem onto ordinary package-manager versioning for
  whatever language the pipeline is written in.
- **Earthly** targets/functions can reference targets in *other repositories* directly
  (`BUILD github.com/org/repo+target`), which is reference-not-copy at the build-graph level,
  not a scaffolding-sync mechanism.

None of these four offer anything resembling cruft/copier/projen's answer to "the template
changed, please update my already-generated files" — they were the wrong lead for that
specific problem, but right for the adjacent "share a pipeline definition across repos without
copying it" problem.

---

## 3. Composable / modular sharing instead of whole-template sync

The throughline across every mature example here is the same: **stop copying, start
referencing a versioned artifact.** Once nothing is copied there is no fork to keep in sync —
by construction, not by discipline.

- **pre-commit** (the framework, [pre-commit.com](https://pre-commit.com/)) — `.pre-commit-config.yaml`
  lists `repo:`/`rev:` pairs; each hook repo ships a `.pre-commit-hooks.yaml` manifest
  describing its own entry points. `pre-commit autoupdate` mechanically bumps every pinned
  `rev` to latest, producing an ordinary reviewable diff. This is arguably the single
  best-solved artifact type in this whole survey, precisely because the unit of sharing (one
  hook) is small and the interface (stdin/stdout/exit code + a manifest) is trivially stable.
- **GitHub reusable workflows** (`workflow_call`) and **composite actions** — covered in depth
  in §5 below.
- **Nix flake modules** (flake-parts, and the file-tree-convention libraries **haumea**,
  `vic/import-tree`, **snowfall-lib**) — these solve a different but related problem:
  *organizing* a growing set of Nix modules inside one repo/flake so new files "just appear" in
  the right output attribute, not syncing already-generated files across repos. `import-tree`
  in particular recursively imports a directory tree of `.nix` files into any module system
  (NixOS/darwin/home-manager/flake-parts/Nixvim), and underscore-prefixed paths (`/_helpers`)
  are conventionally excluded — useful plumbing, but orthogonal to drift.
- **devenv.sh** supports composing environments via `--from path:../shared-devenv` (reads a
  sibling repo's `devenv.yaml`/imports live, no fetch/copy step) and first-class monorepo
  composition (merge per-folder environments into one)
  ([devenv.sh/guides/monorepo](https://devenv.sh/guides/monorepo/)). **devbox** has an
  equivalent `include`-based plugin mechanism referencing a GitHub URL with a `ref`, i.e. the
  same reference-with-pinned-version shape as everything else in this section.
- **Terraform modules** — registry module + version constraint (`~>`) in the `module` block;
  `terraform init -upgrade` re-resolves. Best-practice guidance explicitly frames unconstrained
  versions as a foot-gun and recommends exact pins for production
  ([spacelift.io/terraform-module-versioning](https://spacelift.io/blog/terraform-module-versioning)).
- **Ansible collections/roles** — `requirements.yml` pins collection/role versions from Galaxy
  or a private index; CI regenerates the installed roles from that file rather than committing
  them.
- **Gradle convention plugins** — a `build-logic` included build (or `buildSrc`, now
  discouraged in favor of composite builds) publishes precompiled script plugins that consumer
  modules `apply` by ID; Gradle's own docs recommend this over copy-pasted `build.gradle.kts`
  boilerplate
  ([docs.gradle.org — sharing convention plugins](https://docs.gradle.org/current/samples/sample_sharing_convention_plugins_with_build_logic.html)).
- **Bazel bzlmod** — `MODULE.bazel` declares versioned module dependencies with an explicit
  `compatibility_level`, so a resolved dependency graph containing two incompatible major
  versions of the same module is a hard error rather than silent breakage
  ([bazel.build/external/migration](https://bazel.build/external/migration)).

**What makes a module system succeed vs. become leaky**, synthesized across all of the above:

- *Small, single-purpose units* succeed (a pre-commit hook, a Gradle convention plugin, one
  Terraform module). *Monolithic* units (a whole cookiecutter template, a whole `.projenrc`
  base class) are exactly where escape hatches proliferate, because "the one thing I need to
  change" is never at a natural seam.
- *An explicit customization surface* (Terraform module variables, `workflow_call` inputs,
  Gradle plugin extension DSLs) beats *implicit* customization (editing the generated output
  and hoping the next sync doesn't clobber it). Every tool that had no explicit surface (cruft,
  copier, cargo-generate) ended up needing a merge algorithm instead; every tool that had one
  (pre-commit, Terraform, Bazel, Gradle) needed no merge algorithm at all.
- *"I want the module but with one thing different"* is handled three ways in practice, in
  ascending order of how well it's held up: (a) parameters/inputs on the module itself
  (Terraform variables, `workflow_call` inputs, Gradle plugin config) — works as long as the
  author anticipated the axis of variation; (b) an escape hatch into the generated artifact
  (projen `addOverride`, GitHub composite-action steps-before/after) — works but is a leaky,
  second-class API; (c) fork-and-diverge (copy the module, edit it, lose the update path) —
  always available, always the failure mode everyone is trying to avoid, and always what
  happens when (a) and (b) both fall short.

---

## 4. Nix-specific prior art

This is the area the task flagged as most important, and it turns out to split cleanly along
the same three-strategy line as everything else — with one confirmed gap.

- **`cachix/git-hooks.nix`** (formerly `pre-commit-hooks.nix`; renamed, 854★, actively pushed)
  is the strongest "regenerate" example: you declare hooks in Nix (`hooks.<name>.enable = true`),
  and the flake produces both a `pre-commit-check` derivation (usable as a `nix flake check`
  gate) and a devShell `shellHook` that symlinks a generated `.pre-commit-config.yaml` into the
  working tree, with guidance to `.gitignore` that file since it's fully derived from the Nix
  config ([github.com/cachix/git-hooks.nix](https://github.com/cachix/git-hooks.nix)). This is
  exactly the "config files are build artifacts" model from §2, applied to a single artifact
  type, and it works cleanly because pre-commit's own hook manifest format (`repo`+`rev`) was
  already designed for exactly this kind of external generation.
- **`numtide/treefmt-nix`** (638★, actively pushed) goes a step further and, on the flake-parts
  integration path, doesn't even materialize a `treefmt.toml` on disk — it wraps the `treefmt`
  binary with a config closure baked in at build time, so there's no file to drift because
  there's no file at all
  ([github.com/numtide/treefmt-nix](https://github.com/numtide/treefmt-nix)).
- **GitHub Actions from Nix — confirmed prior art, but partial.**
  `nix-community/nix-github-actions` (154★) is explicitly a *library*, not a generator: it
  turns a flake's `packages`/`checks` attribute set into a GitHub Actions **matrix JSON
  value** (which systems/jobs to run) that you splice into a workflow YAML file you still
  write and commit by hand
  ([github.com/nix-community/nix-github-actions](https://github.com/nix-community/nix-github-actions)).
  It deliberately doesn't try to own the whole workflow. A less mainstream sibling,
  `nialov/actions.nix`, does go further and emits a complete GitHub/Gitea workflow YAML from a
  Nix module, but it's a small, niche project. So: **yes, there is prior art for
  "generate GitHub Actions from Nix,"** but the ecosystem's actual center of gravity
  (`nix-github-actions`) deliberately generates only the *matrix fragment*, not the workflow,
  and expects the rest to be hand-authored and drift-checked the ordinary way (i.e., committed
  YAML, reviewed in PRs like any other source file).
- **Generating a Justfile from Nix — confirmed, but thin, and this is a real finding, not a
  search miss.** `juspay/just-flake` is the one hit: a flake-parts module where you toggle
  `just-flake.features.<name>.enable` (with built-ins for `treefmt`, `rust`, `convco`,
  `changelog`) and optionally supply a `justfile` string per custom feature; a `shellHook`
  writes a `just-flake.just` file that your hand-written root `justfile` then `import`s
  ([github.com/juspay/just-flake](https://github.com/juspay/just-flake)). Its own README flags
  the module option API as "subject to change," and GitHub metadata confirms it's small (54★, 5
  open issues) and hasn't been pushed to since June 2024 — i.e., stalled, not a thriving
  standard. There is no bigger/more-adopted alternative I could find. **This is a genuine gap
  in the ecosystem**: recipe *bodies* (shell script content) end up as string literals inside
  `.nix` files either way, which gives you provenance (the flake input pin) but none of Nix's
  actual type/eval safety over the shell content itself — you're back to stringly-typed shell,
  just now embedded in a language even less suited to editing it than a plain `Justfile`.
- **`nix-community/nixago`** (152★, not archived but stale — last push May 2025, 10 open
  issues) is the general-purpose version of the same idea as `git-hooks.nix`/`treefmt-nix`:
  arbitrary Nix data → any format `pkgs.formats` can render (JSON, YAML, TOML, INI, …) → a
  `shellHook`-managed symlink at `$PRJ_ROOT/{output}`
  ([github.com/nix-community/nixago](https://github.com/nix-community/nixago)). It's the
  closest thing to a generic "projen for Nix," and its relative staleness/small size — despite
  solving a real and named problem — is itself a data point: this pattern hasn't achieved the
  gravity that, say, `git-hooks.nix` (aimed at one specific artifact) has.
- **Organizational/file-tree tools** — `nix-community/haumea` (auto-imports a directory into an
  attrset, with `self`/`super`/`root` fixed-point support) and `vic/import-tree` (recursive
  `.nix` importer for any module system, `/_`-prefixed paths excluded by convention,
  [import-tree.denful.dev](https://import-tree.denful.dev/)) and **snowfall-lib**
  (`snowfall.org`, imposes an opinionated directory layout and auto-derives flake outputs,
  including a `templates` output specifically for scaffolding) — these make it easy to *add* a
  new shared module to a flake, but do nothing for repos that already forked off an earlier
  version of that flake's output. They're an organizational convenience layered on top of the
  reference model (§3), not a sync mechanism.
- **Fleet-of-machines analogues**: `nix-community/srvos` (opinionated, shared, referenced NixOS
  server profiles — literally "add this flake input, get these modules"), `clan.lol` (adds
  inventory/service management on top of an existing flake without requiring a rewrite,
  [docs.clan.lol](https://docs.clan.lol/guides/getting-started/convert-flake/)),
  `divnix/std` (organizes flake outputs into "cells"/"cell blocks" plus a CLI/TUI and its own
  GitHub Action, [std.divnix.com](https://std.divnix.com/)), and `nix-community/dream2nix`
  (module-system-based, composable language-ecosystem packaging,
  [dream2nix.dev/modules](https://dream2nix.dev/modules/)) — all of these are healthy,
  actively used examples of the reference-not-copy pattern applied to NixOS configs or package
  derivations. None of them are scaffolding-sync tools; they're evidence that "many downstream
  units share versioned Nix modules by reference" is an extremely well-trodden path in this
  ecosystem for *modules*, just not yet for *whole project scaffolds*.

**Net finding for this section**: Nix's ecosystem has fully solved "generate one specific
config artifact (pre-commit hooks, formatter config) from Nix and never let it drift" for the
artifact types someone cared enough to build a dedicated tool for. It has *not* produced a
mature, widely-adopted "regenerate a whole scaffolded project's Justfile/CI/lint-config bundle
from a shared Nix source of truth" tool — `nixago` is the closest attempt and it's stalled at
~150 stars. If `cratemplate` wanted to go the projen-for-Nix route, it would be pioneering,
not adopting.

---

## 5. Customization of shared CI

GitHub's own docs are the primary source here
([docs.github.com — reusing workflow configurations](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations)):

- **What a caller can pass into a reusable workflow**: `with:` (inputs), `secrets:` (either
  explicit named secrets or `secrets: inherit` to forward everything), and `strategy:` (a
  matrix wrapping the *call itself*, so the same reusable workflow runs once per matrix cell).
- **What a caller cannot do**: pass ambient `env:` context set at the workflow level in the
  caller down into the callee (only `inputs`/`outputs` cross that boundary); use GitHub-hosted
  runners belonging to the *called* workflow's repo from the caller's context; add steps
  *inside* a reusable workflow's job (the call **is** the job — no before/after within that
  job, unlike a composite action). Only a fixed, documented set of job-level keywords
  (`with`, `secrets`, `strategy`, plus a few more) are legal on a `uses:`-a-reusable-workflow
  job at all — everything else you'd normally put on a job is simply unsupported there.
- **Nesting/scale limits, and how they've moved**: GitHub.com currently allows chaining up to
  **10 levels** of reusable workflows and calling up to **50 unique** reusable workflows from
  one top-level file; both numbers were raised from earlier limits (4 levels / 20 workflows),
  and GitHub Enterprise Server versions lag behind GitHub.com on this — e.g. GHES 3.21 docs
  still show the older 4-level cap
  ([GHES 3.21 docs](https://docs.github.com/en/enterprise-server@3.21/actions/reference/workflows-and-actions/reusing-workflow-configurations),
  [community discussion #8488](https://github.com/orgs/community/discussions/8488)). Anyone
  citing "4 levels" as a hard GitHub Actions limit today is citing a stale number for
  GitHub.com, though it may still be accurate for their GHES version — worth checking which
  product you're actually on.
- GITHUB_TOKEN permissions can only get *more* restrictive going down the call chain (A→B→C: if
  A has `packages: read`, neither B nor C can escalate to `packages: write`) — a real,
  intentional limit, not a bug, that shows up as confusing failures for teams trying to
  centralize a publish step behind a reusable workflow.

**The "same pipeline, but this repo needs one extra step" problem in practice**: reusable
workflows are the wrong tool for this because the call occupies the entire job — you can't
splice a step before/after it in that job (you'd need a second job, with more inter-job
plumbing). **Composite actions are the right tool** for exactly this shape, because a composite
action collapses to a single *step*, and a caller's job can freely put ordinary steps before
and after it, using the composite action's outputs downstream
([chris48s.github.io — composite actions vs reusable workflows](https://chris48s.github.io/blogmarks/posts/2021/composite-actions-reusable-workflows/)).
The practical rule of thumb repeated across several practitioner write-ups: **reusable
workflow when the shared thing is shaped like a whole pipeline (checkout→build→test→publish);
composite action when the shared thing is shaped like one step** — and when a team needs both
("mostly the same pipeline, but one extra step in the middle"), the common real-world answer is
to expose that variation point as an explicit reusable-workflow `input` (a boolean flag, or a
list of extra commands to run) rather than trying to inject arbitrary steps — i.e., the same
"explicit customization surface beats implicit override" lesson from §3.

---

## What fails at scale — collected war stories

- **Update discipline collapses before the tooling does.** The DBT/cruft org's stated failure
  mode wasn't a merge conflict, it was that *nobody had time to run the update command* across
  hundreds of generated projects on a routine cadence
  ([Medium/bctello8](https://medium.com/@bctello8/standardizing-dbt-projects-at-scale-with-cookiecutter-and-cruft-20acc4dc3f74)).
  Any patch-merge tool inherits this: it requires an ongoing human action per repo, indefinitely.
- **3-way merge fallback is where cruft/copier actually hurt.** Multiple cruft issues
  ([#287](https://github.com/cruft/cruft/issues/287), [#47](https://github.com/cruft/cruft/issues/47))
  describe either silent partial application or opaque git-internals errors when the direct
  patch path fails and cruft drops to 3-way merge.
  Renovate's automated-PR integration with Copier makes the same failure mode worse by
  *degree*: a conflicted, marker-laden file can land in an opened PR reported as "success"
  ([renovatebot/renovate#31600](https://github.com/renovatebot/renovate/issues/31600)) — at
  scale (many repos, bot-driven), that's a much larger blast radius for a human to miss a
  conflict marker in a diff they weren't expecting to need close review.
  Automated regeneration diffing needs to fail loudly, not "succeed with a comment," precisely
  *because* scale means no human is reading every PR closely.
- **Codemod-based migration (Nx, and by design Angular before it) breaks on version-skipping.**
  Both [nrwl/nx#9719](https://github.com/nrwl/nx/issues/9719) and
  [nrwl/nx#20407](https://github.com/nrwl/nx/issues/20407) are jumping-multiple-majors
  failures; the documented mitigation is "don't skip," which is itself an admission that the
  migration chain is only tested/valid pairwise, not for arbitrary version deltas — a real
  constraint on any tool in this family, including a hypothetical Nix/Rust equivalent.
- **Partial/incremental application has no first-class support anywhere in the copy/regenerate
  family.** cargo-generate's own maintainers, discussing the still-open
  [#291](https://github.com/cargo-generate/cargo-generate/issues/291), converge on "just script
  it with a temp dir and `cp`" — five years and counting, unimplemented. Yeoman's community
  independently reinvented the same regenerate-old/regenerate-new/diff/apply pattern by hand in
  [yeoman/yo#474](https://github.com/yeoman/yo/issues/474), because there was no first-party
  tool for it either. This is a genuinely unsolved corner even in the tools that otherwise
  solve whole-project sync well.
- **Escape hatches are where the "generate everything" model leaks.** projen's own docs frame
  `addOverride`/JSON-Patch as the answer to "projen doesn't have the right API for this yet" —
  which is an admission, not a footnote: the moment a downstream repo needs one config knob the
  central model didn't anticipate, that repo's `.projenrc` starts accumulating brittle,
  object-shape-dependent patch calls that are *more* fragile to the generator's internal
  version bumps than the plain config file they replaced would have been.
- **A stopped-clock is common in the "generate from Nix" niche.** `just-flake` (54★, unpushed
  since mid-2024) and `nixago` (152★, unpushed since mid-2025, 10 open issues) are both small,
  real, working tools that never crossed into wide adoption — evidence that this specific
  sub-niche (regenerate arbitrary text config from Nix) hasn't found the "obvious default"
  status that `git-hooks.nix`/`treefmt-nix` achieved for their narrower, single-purpose slices.
- **General-purpose skepticism, independently arrived at**: the 2019 HN thread "Why is it so
  hard to write a scaffolding tool?" ([news.ycombinator.com/item?id=33079544](https://news.ycombinator.com/item?id=33079544))
  has a commenter naming the exact problem this report was commissioned to survey, unprompted:
  *"How do you retrofit any updates you've made to the scaffolding to an existing project that
  has probably diverged from the original vanilla scaffolding in non-trivial ways?"* — and the
  thread's converging answer is to keep scaffolding intentionally minimal (organizational
  structure + CI skeleton only) rather than trying to own every config surface, precisely
  because broader scope means broader, harder-to-resolve drift later.

---

## Recommendations for a Nix + Rust + `just` stack (this project: cratemplate)

`cratemplate` is a `cargo-generate` template (`template/cargo-generate.toml`) shipping a Rust
project skeleton — `flake.nix`, `Justfile`, `outdatty.yaml`, `clippy.toml`, `deny.toml`,
`rustfmt.toml`, CI-adjacent config — that gets copied once into every downstream repo. Given
everything above:

**What transfers cleanly:**

- **Reference-not-copy, wherever the artifact type supports it.** This is the one strategy
  with zero war stories in this whole survey, because there's nothing to keep in sync — you
  just bump a pin. Concretely: any downstream repo's `flake.nix` can pin `cratemplate` (or a
  split-out "shared Nix modules" flake) as an **input** and consume shared devShell
  packages/checks from it directly, the same way `srvos`/Rush-rigs/Terraform-modules do. This
  is almost certainly the highest-leverage single change available: it converts "shared Rust
  toolchain version, shared clippy/deny/rustfmt defaults, shared CI matrix logic" from
  copy-paste-and-drift into an ordinary `flake.lock` bump, reviewable in a normal PR, with
  `nix flake update` as the "sync" command instead of a bespoke merge tool.
- **`cachix/git-hooks.nix`-style regeneration for anything that's genuinely config, not prose.**
  If cratemplate ships git hooks or formatter config, generating them from the shared Nix
  module (as `git-hooks.nix`/`treefmt-nix` do) means those specific files never need a
  cruft/copier-style sync at all — they're rebuilt fresh in every `nix develop`.
- **`nix-github-actions`'s narrower scope is the right level of ambition for GH Actions from
  Nix**, if that's wanted: generate the *matrix*, keep the workflow YAML hand-written and
  reviewed. Going further (`actions.nix`-style full-workflow generation) is exactly the kind of
  monolithic, low-adoption approach §3's "small units succeed" lesson warns against — and
  concretely, GitHub Actions workflow files are exactly the kind of artifact a human reviewer
  needs to be able to read directly in a PR diff without mentally re-deriving it from Nix.

**What does not transfer, and why:**

- **A projen-style "everything regenerated, escape hatch for the rest" model is likely
  overkill for a `just`/Rust stack**, and there's no mature prior art to lean on if
  `cratemplate` tried to build one (§4's "genuine gap" finding). projen's model earns its
  complexity in a JS/TS monorepo with dozens of *heterogeneous* config file formats
  (`package.json`, `tsconfig`, ESLint, Jest, multiple CI providers) where a typed object model
  actually buys real safety. A Rust+Nix+just project has a much smaller, more homogeneous
  config surface (`Cargo.toml`, `clippy.toml`, `rustfmt.toml`, `flake.nix`, `Justfile`) where
  hand-editing text and reviewing a plain diff is already cheap — the ROI on building a typed
  generator + escape-hatch API is much lower here than it is for projen's actual use case.
- **`Justfile` recipe *bodies* are the one artifact type this survey found no strong prior art
  for generating from Nix at all** (`just-flake` is real but small and stalled). Don't build a
  from-scratch "generate Justfile from Nix" system expecting to find an ecosystem to lean on —
  you'd be extending the frontier, not following it. If Justfile drift specifically is the
  pain point, a cruft/copier-style *partial* re-sync (see next point) is better-trodden ground
  than a from-Nix generator.
- **cruft/copier-style whole-tree patch-merge is a real, well-trodden option for the parts of
  `cratemplate` that are genuinely per-repo text (README boilerplate, `CONTRIBUTING.md`,
  Justfile recipes with repo-specific bodies) that can't be turned into a reference.** It's
  worth being honest that adopting it inherits copier's real failure modes (§1, §"what fails at
  scale"): someone has to run `copier update` (or equivalent) per repo on a cadence, and any
  automation around it (a bot, a scheduled job) must be built to treat merge conflicts as a
  hard failure, not a soft comment — the Renovate/copier issue is a directly transferable
  lesson.
- **cargo-generate itself still has no update story, and none is coming soon** (§1) — so
  whatever sync mechanism `cratemplate` adopts, it cannot be "just re-run cargo-generate on the
  existing repo." It would need to be a separate tool (cruft/copier-style, operating on the
  generated tree directly) or the reference-based Nix-input approach above; cargo-generate's
  own maturity here (RFC open, unimplemented, since 2021) rules it out as the sync mechanism.

**Bottom line for this project:** split `cratemplate`'s surface into (a) what can become a
versioned Nix flake input consumed by reference (toolchain pins, shared clippy/deny/rustfmt
defaults, shared devShell/CI logic) — do this first, it's the highest-leverage, best-precedented
move — and (b) what's genuinely per-repo prose/structure that has to stay copied (README,
initial `Cargo.toml` metadata, project-specific Justfile bodies) — for that residual, a
cruft/copier-style opt-in re-sync tool is the better-precedented answer than inventing a
projen-for-Rust or a bigger `just-flake`.
