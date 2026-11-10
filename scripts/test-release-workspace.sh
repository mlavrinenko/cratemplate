#!/usr/bin/env bash
# scripts/test-release-workspace.sh: the release half of the workspace stage,
# run by scripts/test-workspace.sh inside the generated project's dev shell.
# to-workspace.sh has moved the crate under crates/ and marked the second member
# `publish = false`, so `just release` must resolve the one publishable crate
# with cargo metadata, keep the root CHANGELOG, push nothing on --dry-run and
# leave no tag. The tag and publish path is covered by scripts/test-release.sh
# on the single crate.
set -eo pipefail

echo "--- Verifying just release selects the one publishable workspace crate"
stub="$(mktemp -d)"
origin="$stub/origin.git"
# shellcheck disable=SC2016 # the stub is literal: its $1/$2 and $GH_STUB_CI expand when it runs
printf '%s\n' '#!/usr/bin/env bash' \
    'case "$1 $2" in' \
    '  "auth status") ;;' \
    '  "run list") echo 42 ;;' \
    '  "run watch") [ "$GH_STUB_CI" = success ] ;;' \
    '  "run view") echo "$GH_STUB_CI" ;;' \
    '  *) echo "gh stub: unexpected $*" >&2; exit 2 ;;' \
    'esac' > "$stub/gh"
chmod +x "$stub/gh"
export PATH="$stub:$PATH"
git config user.name validate
git config user.email validate@example.invalid
rm -f result
git add -A
git diff --cached --quiet || git commit -qm scaffold --no-verify
git branch -M main
git init -q --bare "$origin"
git remote add origin "$origin"

# The release's entries sit under [Unreleased], as an author leaves them.
sed -i "s/^## \[Unreleased\]/&\n\n### Added\n\n- the first release/" CHANGELOG.md
git commit -qam "add the first release's entry" --no-verify

out=$(GH_STUB_CI=success just release 0.1.0 --dry-run 2>&1) \
    || { echo "$out" >&2; echo "the workspace release refused a dry run" >&2; exit 1; }
grep -q "^dry run: every check passed\$" <<<"$out" || { echo "$out" >&2; exit 1; }
grep -q "^would push main, wait for ci.yml on it, then tag and push 'v0.1.0'\$" <<<"$out" \
    || { echo "$out" >&2; exit 1; }
test -z "$(git tag -l)" || { echo "the workspace dry run left a tag" >&2; exit 1; }
test -z "$(git ls-remote origin)" || { echo "the workspace dry run pushed" >&2; exit 1; }
test -z "$(git status --porcelain)" || { echo "the workspace dry run changed the tree" >&2; exit 1; }
