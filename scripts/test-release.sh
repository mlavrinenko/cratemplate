#!/usr/bin/env bash
# scripts/test-release.sh: the release half of `just validate`, run by
# scripts/validate.sh from inside the generated project's dev shell. The full
# release path runs against a local bare origin and a `gh` stub whose ci.yml
# run ends as $GH_STUB_CI. Release must refuse a dirty tree and an origin main
# that main lacks, push nothing on --dry-run, push main but leave no tag when
# CI is red, and push the tag only when CI is green. cargo-release bumps, dates
# the entries under [Unreleased] and commits; a re-run after the red CI must
# not date twice.
set -eo pipefail

echo "--- Verifying just release pushes main, waits for CI, tags only green"
stub="$(mktemp -d)"
origin="$stub/origin.git"
# shellcheck disable=SC2016 # the stub is literal: its $1/$2/$GH_STUB_CI expand when it runs
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
git commit -qm scaffold --no-verify
git branch -M main
git init -q --bare "$origin"
git remote add origin "$origin"
remote_main() { git ls-remote origin refs/heads/main | cut -f1; }

# The release's entries sit under [Unreleased], as an author leaves them.
sed -i "s/^## \[Unreleased\]/&\n\n### Added\n\n- the first release/" CHANGELOG.md
printf '%s\n' dirty > dirty.txt
if out=$(just release 0.1.0 --dry-run 2>&1); then echo "release took a dirty tree" >&2; exit 1; fi
grep -q '^error: ' <<<"$out" || { echo "$out" >&2; exit 1; }
rm dirty.txt
git commit -qam "add the first release's entry" --no-verify

# An empty origin has no main yet: the first release creates it.
out=$(GH_STUB_CI=success just release 0.1.0 --dry-run 2>&1) \
    || { echo "$out" >&2; echo "release refused an empty origin" >&2; exit 1; }
grep -q "^dry run: every check passed\$" <<<"$out" || { echo "$out" >&2; exit 1; }
test -z "$(remote_main)" || { echo "--dry-run created origin main" >&2; exit 1; }

git push -q origin HEAD~1:refs/heads/main
git push -q origin "$(git commit-tree 'HEAD~1^{tree}' -p HEAD~1 -m other):refs/heads/main"
if out=$(just release 0.1.0 --dry-run 2>&1); then echo "release took an origin main that main lacks" >&2; exit 1; fi
grep -q "^error: origin/main has commits that main lacks\$" <<<"$out" || { echo "$out" >&2; exit 1; }
git push -qf origin HEAD~1:refs/heads/main

head_before=$(git rev-parse HEAD)
out=$(GH_STUB_CI=success just release 0.1.0 --dry-run 2>&1) || { echo "$out" >&2; exit 1; }
grep -q "^dry run: every check passed\$" <<<"$out" || { echo "$out" >&2; exit 1; }
grep -q "^would push main, wait for ci.yml on it, then tag and push 'v0.1.0'\$" <<<"$out" || { echo "$out" >&2; exit 1; }
test "$(remote_main)" = "$(git rev-parse HEAD~1)" || { echo "--dry-run pushed main" >&2; exit 1; }
test "$(git rev-parse HEAD)" = "$head_before" -a -z "$(git status --porcelain)" \
    || { echo "--dry-run changed the tree" >&2; exit 1; }

if out=$(GH_STUB_CI=failure just release 0.1.0 2>&1); then echo "release tagged a red CI run" >&2; exit 1; fi
grep -q "^error: ci.yml ended 'failure' on '$(git rev-parse --short HEAD)', so 'v0.1.0' was not made\$" <<<"$out" || { echo "$out" >&2; exit 1; }
test "$(grep -c '^hint: ' <<<"$out")" = 2 || { echo "$out" >&2; exit 1; }
test "$(remote_main)" = "$(git rev-parse HEAD)" || { echo "release did not push main" >&2; exit 1; }
test -z "$(git tag -l)$(git ls-remote --tags origin)" || { echo "a red CI run left a tag" >&2; exit 1; }
test "$(git log -1 --format=%s)" = "chore(release): 0.1.0" || { echo "release did not commit the bump" >&2; exit 1; }

# The re-run after the red run finds the bump done: it dates nothing twice.
GH_STUB_CI=success just release 0.1.0
git ls-remote --exit-code --tags origin refs/tags/v0.1.0 >/dev/null || { echo "release did not push v0.1.0" >&2; exit 1; }
test "$(grep -c '^## \[0\.1\.0\] - ' CHANGELOG.md)" = 1 || { echo "the re-run dated the CHANGELOG twice" >&2; exit 1; }
