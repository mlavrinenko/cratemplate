#!/usr/bin/env bash
# The `pre-release-hook` of release.toml, which `just release VERSION` runs
# through cargo-release after the version bump, and also in a dry run
# (DRY_RUN=true), where the tree is still unbumped. It reads
# NEW_VERSION, DRY_RUN and WORKSPACE_ROOT, which cargo-release sets, and
# release-meta.sh for the one publishable crate. Each refusal guards a way a
# release has gone wrong: it prints one `error:` and its `hint:` lines, and
# cargo-release aborts before it commits.
set -euo pipefail
cd "$WORKSPACE_ROOT"
version="$NEW_VERSION"
tag="v$version"
dry_run="${DRY_RUN:-false}"
refuse() {
    echo "error: $1" >&2; shift
    for h in "$@"; do echo "hint: $h" >&2; done
    if [ "$dry_run" != true ] && [ -n "$(git status --porcelain)" ]; then
        echo "hint: git restore . drops the version bump; then re-run" >&2
    fi
    exit 1
}
for tool in git cargo curl gh; do
    command -v "$tool" >/dev/null \
        || refuse "'$tool' is not on PATH" "run inside the dev shell"
done
gh auth status >/dev/null 2>&1 || refuse "gh is not logged in" "gh auth login"
crate=$(.just/scripts/release-meta.sh crate)
repo_url=$(.just/scripts/release-meta.sh repository)
workflows=(.github/workflows/release*.yml)
workflow=$(basename "${workflows[0]}")
# A real run has only the bump (and a hand-dated CHANGELOG) uncommitted by now.
dirty=$(git status --porcelain | grep -Ev '^.. (Cargo\.toml|Cargo\.lock|CHANGELOG\.md)$' || true)
[ "$dry_run" != true ] || dirty=$(git status --porcelain)
[ -z "$dirty" ] \
    || refuse "the working tree has uncommitted changes" "commit or discard them, then re-run"
branch=$(git symbolic-ref --short -q HEAD || true)
[ "$branch" = main ] || refuse "HEAD is on '${branch:-a detached commit}', not main" "git switch main"
fetch_rc=0
git fetch --quiet origin main 2>/dev/null || fetch_rc=$?
if [ "$fetch_rc" -ne 0 ]; then
    ls_rc=0
    git ls-remote --exit-code --heads origin main >/dev/null 2>&1 || ls_rc=$?
    case "$ls_rc" in
        0) refuse "can't fetch 'origin main'" "check the network and the origin remote" ;;
        2) ;; # an empty remote has no main yet; the release pushes the first one
        *) refuse "can't reach 'origin'" "check the network and the origin remote" ;;
    esac
fi
if git rev-parse -q --verify refs/remotes/origin/main >/dev/null; then
    git merge-base --is-ancestor origin/main HEAD \
        || refuse "origin/main has commits that main lacks" "git pull --ff-only origin main, then re-run"
fi
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null \
    || git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null; then
    refuse "'$tag' already exists" "a pushed tag never moves; finish a failed release with: gh workflow run $workflow -f tag=$tag"
fi
status=$(curl -sS -o /dev/null -w '%{http_code}' -A "$repo_url" \
    "https://crates.io/api/v1/crates/$crate/$version" || true)
case "$status" in
    404) ;;
    200) refuse "'$crate $version' is already on crates.io" "a published version is never re-published; bump to the next version" ;;
    *) refuse "crates.io answered HTTP '${status:-nothing}' for '$crate $version'" "retry once crates.io is reachable" ;;
esac
# Dating [Unreleased] lives here, not in cargo-release's replacements: a
# workspace member resolves those against crates/<name>/, which holds no
# CHANGELOG. The match is the replacement that used to run, so it fires only
# while entries follow [Unreleased] and a re-run after a red CI dates nothing
# twice. A dry run, or a re-run after the bump, finds the entries under whichever
# heading holds them.
heading="Unreleased"
grep -Eq "^## \[${version//./\\.}\] - [0-9]{4}-[0-9]{2}-[0-9]{2}" CHANGELOG.md && heading="$version"
if [ "$dry_run" != true ] && [ "$heading" = Unreleased ]; then
    dated=$(mktemp)
    if awk -v version="$version" -v date="$(date -u +%F)" '
        { line[NR] = $0 }
        END {
            for (i = 1; i <= NR; i++) {
                if (!done && line[i] == "## [Unreleased]") {
                    j = i + 1
                    while (j <= NR && line[j] == "") j++
                    if (j <= NR && line[j] ~ /^### /) {
                        print "## [Unreleased]"
                        print ""
                        print "## [" version "] - " date
                        for (k = i + 1; k < j; k++) print ""
                        done = 1
                        i = j - 1
                        continue
                    }
                }
                print line[i]
            }
            exit(done ? 0 : 1)
        }
    ' CHANGELOG.md > "$dated"; then
        cp "$dated" CHANGELOG.md
        rm -f "$dated"
        heading="$version"
    else
        rm -f "$dated"
    fi
fi
[ "$dry_run" = true ] || [ "$heading" = "$version" ] \
    || refuse "CHANGELOG.md has no dated section for '$version'" "add the release's entries under '## [Unreleased]' and commit"
entries=$(sed -n "/^## \[${heading//./\\.}\]/,/^## \[/p" CHANGELOG.md | sed '1d;$d' | sed '/^[[:space:]]*$/d')
[ -n "$entries" ] \
    || refuse "CHANGELOG.md has nothing under [$heading] to release" "add the release's entries under '## [Unreleased]' and commit"
# The dated section is the review outdatty's release-notes group asks for.
[ "$dry_run" = true ] || outdatty update --group release-notes >/dev/null
just check || refuse "the gates have not passed on this tree" "fix what just check reports above, then commit"
# --allow-dirty: on a real run the bump is not committed yet.
cargo publish --dry-run --locked --allow-dirty -p "$crate" --quiet \
    || refuse "cargo publish --dry-run failed" "fix the packaging error above"
