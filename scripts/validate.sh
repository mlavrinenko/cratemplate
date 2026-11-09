#!/usr/bin/env bash
# scripts/validate.sh <bin|lib>: generate a project from template/, gate it in
# its dev shell, run the release path, then gate a copy converted to a
# workspace. `just validate [KIND]` calls this.
set -eo pipefail

kind="${1:-}"
case "$kind" in
  bin|lib) ;;
  *) echo "usage: just validate <bin|lib>" >&2; exit 1 ;;
esac

TEMPLATE_DIR="$(pwd)"
export TEMPLATE_DIR
WORK_DIR="$(mktemp -d)"
PROJECT_NAME="validate-test-crate"

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

step() { echo "--- $1"; }

# The committed Markdown is generated from template/docs/src/*.typ; a hand-edit
# or a stale render fails before any project is generated.
step "Synchronising generated template docs"
just docs-check

# Root and template docs are gated before any project is generated: a docs
# regression should fail fast, not after a full template build.
step "Checking repository and template docs (linecop)"
just check-docs

# A quote or line break in `description` corrupts Cargo.toml and main.rs, so
# the placeholder regex must reject it before generation.
step "Regression: description placeholder rejects unsafe input"
bash scripts/test-description.sh

step "Generating $kind project from template"
# `--inputs-from` pins cargo-generate through this repo's flake.lock, so CI
# and local runs match; unpinned, CI drifted to 0.25 while local stayed on 0.23.
nix shell --inputs-from "$TEMPLATE_DIR" nixpkgs#cargo-generate nixpkgs#cargo --command \
    cargo generate --path "$TEMPLATE_DIR/template" \
        --destination "$WORK_DIR" \
        --name "$PROJECT_NAME" \
        --define "description=Validation test project" \
        --define "license=MIT" \
        --define "gh-username=testuser" \
        --define "crate_kind=$kind"

cd "$WORK_DIR/$PROJECT_NAME"

# nixpkgs builds cargo-generate 0.25 without its `git` feature, so it no
# longer runs `git init` (and ignores `--vcs git`); 0.23 still does. Init
# here so a flake.lock bump past 0.25 doesn't break validate.
[ -d .git ] || git init -q

# Git tracks files, so a clone holds no empty directory, while cargo-generate
# leaves a lib an empty `tests/`. Gate the tree a clone gets.
find . -type d -empty -not -path "./.git/*" -delete

# The shipped lock must reach the generated project: free-resolving upstream
# HEAD would stop testing the template's pins, and a stale lock would rot
# (qahq's outdatty 0.3.0 pin predates require_tracked, which outdatty.yaml needs).
test -f flake.lock || { echo "error: cargo-generate did not ship flake.lock (ignore list regressed?)" >&2; exit 1; }
cmp -s flake.lock "$TEMPLATE_DIR/template/flake.lock" || { echo "error: generated flake.lock differs from template/flake.lock" >&2; exit 1; }

git add -A

# A copy for the workspace stage below, taken before anything builds.
cp -r . "$WORK_DIR/workspace"

# Fed to `bash -s` over a QUOTED heredoc: an apostrophe stays inert, whereas
# in `bash -c '...'` it would close the quote and run the rest in the OUTER
# shell, where the generated project has no toolchain and gates lie.
nix develop --command bash -s <<'INNER'
set -eo pipefail

# The gates below are only meaningful inside the dev shell. If this
# block ever escapes it, fail loudly instead of misreporting.
command -v cargo >/dev/null || { echo "not in the dev shell" >&2; exit 1; }

# A host BASH_ENV that re-runs direnv (NixOS ships one) leaves non-interactive
# `bash -c` shells without the dev shell's PATH: recipes then die with
# `outdatty: command not found`. The gates need the dev shell, not the host's
# shell startup.
unset BASH_ENV

just check

echo "--- Verifying memoized gates (mmz)"
just check
mmz --is-fresh --tag gate

# `just release` must refuse before tagging: a version that is not
# semver (just's own argument pattern), and the uncommitted scratch
# tree (cargo-release's dirty check, or the hook's). Neither refusal may
# leave a tag behind.
echo "--- Verifying just release refuses before tagging"
if out=$(just release v1 --dry-run 2>&1); then echo "release v1 did not refuse" >&2; exit 1; fi
if out=$(just release 0.1.0 2>&1); then echo "release 0.1.0 tagged a dirty tree" >&2; exit 1; fi
grep -q '^error: ' <<<"$out" || { echo "$out" >&2; exit 1; }
test -z "$(git tag -l)" || { echo "a refused release left a tag" >&2; exit 1; }

# A Markdown file at >= the eject baseline (90% of the 200-line limit) must
# not red `just fix-check`: linecop's `--baseline` exit-1 is informational,
# and the eject scan is Rust-only — it used to die on the producer before
# ejectest ran. Use an untracked fixture, never a real (or generated) doc, so
# the gate cannot rot as those files are converted, then run the real gate.
echo "--- Regression: near-limit Markdown must not red just fix-check"
awk 'BEGIN { for (i = 0; i < 180; i++) print "<!-- near-limit regression filler -->" }' > near-limit.md
just fix-check
rm -f near-limit.md

# linecop exits 2 on a broken run (bad config) and 1 on findings. The
# eject recipe masks only the findings: a broken linecop must red it
# rather than read as "nothing to eject".
echo "--- Regression: a broken linecop must red just eject"
bak="$(mktemp)"; cp .linecop.yaml "$bak"
echo "limits: [" > .linecop.yaml
if just eject >/dev/null 2>&1; then echo "just eject passed on a broken linecop config" >&2; exit 1; fi
cp "$bak" .linecop.yaml

just install-hooks
test -x "$(git rev-parse --git-path hooks/pre-commit)"

just build
just cover
just crap

# cargo-deny rejects a retired config key outright, so a deny.toml
# that has drifted out of schema fails CI in every generated project.
just deny

# Worktrunk ships in the repo: the hooks keep their template variables
# (the file is not rendered), wt parses them, and the pre-remove lcov
# carry does what its cases say. `fork` and `land` are one-line wraps.
echo "--- Verifying the worktrunk hooks"
grep -q '[{][{] target }}' .config/wt.toml || { echo ".config/wt.toml lost its target variable (rendered by cargo-generate?)" >&2; exit 1; }
wtconf="$(mktemp)"
WORKTRUNK_CONFIG_PATH="$wtconf" wt hook show 2>&1 | grep -q 'pre-remove lcov' \
    || { echo "wt does not read .config/wt.toml" >&2; exit 1; }
bash "$TEMPLATE_DIR/scripts/test-wt-carry-lcov.sh" .

# Two lanes that each add a CHANGELOG entry and re-confirm outdatty.lock
# land one after the other with no conflict, through the real recipes
# in a scratch repo.
echo "--- Verifying two parallel lanes land conflict-free"
just land-repro

echo "--- Verifying nix build (package) in a clean sandbox"
git add -A
nix build .#default

# The full release path lives in its own script to keep this one readable; it
# still runs here, inside the dev shell, in the generated project.
bash "$TEMPLATE_DIR/scripts/test-release.sh"
INNER

step "Converting a copy to a workspace and gating it"
cd "$WORK_DIR/workspace"
bash "$TEMPLATE_DIR/scripts/test-workspace.sh" "$kind"
cd "$WORK_DIR/$PROJECT_NAME"

# `nix develop` silently re-resolves (and rewrites) a drifted flake.lock; the
# cmp above proves only that the lock shipped, while this one proves nothing
# re-resolved, so the gate tested the shipped pins instead of upstream HEAD.
cmp -s flake.lock "$TEMPLATE_DIR/template/flake.lock" || { echo "error: nix develop rewrote flake.lock (input drift?) — generated lock no longer matches template/flake.lock" >&2; exit 1; }

echo ""
echo "=== All checks passed ==="
