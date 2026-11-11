#!/usr/bin/env bash
# .just/scripts/release-meta.sh FIELD: print FIELD of the one publishable
# package in the workspace: `crate`, `version`, `repository` or `binary` (empty
# for a lib). A package publishes when `cargo publish` would: `publish` is
# absent or names a registry; `publish = false` reads as an empty list. The
# release model is one publishable crate under a virtual workspace root, so
# zero or several publishable packages refuse rather than guess.
set -euo pipefail

field=${1:?usage: release-meta.sh crate|version|repository|binary}
refuse() {
    echo "error: $1" >&2; shift
    for h in "$@"; do echo "hint: $h" >&2; done
    exit 1
}
case "$field" in
    crate|version|repository|binary) ;;
    *)
        refuse "unknown field '$field'" \
            "usage: release-meta.sh crate|version|repository|binary"
        ;;
esac
command -v cargo >/dev/null || refuse "'cargo' is not on PATH" "run inside the dev shell"
command -v jq >/dev/null || refuse "'jq' is not on PATH" "run inside the dev shell"

metadata=$(cargo metadata --no-deps --format-version 1) \
    || refuse "cargo metadata failed" "fix the workspace error printed above"
# `cargo metadata` renders `publish = false` as `[]` and an unset field as
# `null`; a package publishes when the field is null or names a registry.
packages=$(jq -c '[.packages[] | select(.publish == null or (.publish | length) > 0)]' \
    <<<"$metadata") \
    || refuse "jq could not read cargo metadata" "check 'jq --version'"
count=$(jq 'length' <<<"$packages")
case "$count" in
    0)
        refuse "the workspace has no publishable package" \
            "remove 'publish = false' from the crate that ships"
        ;;
    1) ;;
    *)
        names=$(jq -r 'map(.name) | join(", ")' <<<"$packages")
        refuse "$count packages are publishable: $names" \
            "keep one crate publishable and set 'publish = false' on every support member"
        ;;
esac

case "$field" in
    crate) jq -r '.[0].name' <<<"$packages" ;;
    version) jq -r '.[0].version' <<<"$packages" ;;
    repository) jq -r '.[0].repository // ""' <<<"$packages" ;;
    binary) jq -r 'first(.[0].targets[] | select(.kind | index("bin")) | .name) // ""' \
        <<<"$packages" ;;
esac
