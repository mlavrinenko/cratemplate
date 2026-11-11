#!/usr/bin/env bash
# .just/scripts/release.sh VERSION: bump, date, push main, wait for its CI,
# then tag. `just release VERSION --dry-run` runs every check and says what it
# would push.
#
# The tag push is the only publish path: never `cargo publish` by hand, since a
# version already on crates.io used to fail the tag's workflow and leave the
# release half-done. One command does the whole release, so the push of main
# can't be forgotten and no tag lands on a red commit. cargo-release bumps the
# version of the workspace's one publishable crate, which release-meta.sh
# selects, and commits; its pre-release-hook, .just/scripts/release-hook.sh,
# dates the entries under [Unreleased] and makes every refusal, printing
# `error:` plus a `hint:` with the way out. Then this script pushes main
# (fast-forward only), .just/scripts/release-ci.sh waits for the ci.yml run on
# that exact commit, and only a green run tags.
#
# A tag whose workflow failed is re-run on the same tag, never re-tagged:
# `gh workflow run <release workflow> -f tag=vX.Y.Z`.
set -euo pipefail

version=${1:?usage: release.sh VERSION}
crate=$(.just/scripts/release-meta.sh crate)
args=(--no-confirm)
[ -n "${DRY_RUN:-}" ] || args+=(--execute)
cargo release "$version" -p "$crate" "${args[@]}" --no-tag
if [ -n "${DRY_RUN:-}" ]; then
    echo "dry run: every check passed"
    echo "would push main, wait for ci.yml on it, then tag and push 'v$version'"
    exit 0
fi
.just/scripts/release-ci.sh "$version"
cargo release tag -p "$crate" "${args[@]}"
cargo release push -p "$crate" "${args[@]}" \
    || { git tag -d "v$version" >/dev/null; echo "error: origin rejected the push of 'v$version'" >&2; echo "hint: re-run just release $version" >&2; exit 1; }
# shellcheck disable=SC2012 # tracked workflow filenames are plain: no spaces or newlines
workflow=$(basename "$(ls .github/workflows/release*.yml | head -1)")
echo "pushed 'v$version'; follow it with: gh run list --workflow $workflow --limit 1"
