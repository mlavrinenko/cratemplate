#!/usr/bin/env bash
# scripts/test-description.sh: a quote or line break in `description` corrupts
# Cargo.toml and main.rs, so the placeholder regex must reject it before
# cargo-generate writes a file. `just validate` calls this.
set -eo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESC_DIR="$(mktemp -d)"
trap 'rm -rf "$DESC_DIR"' EXIT

generate() {
    nix shell --inputs-from "$REPO" nixpkgs#cargo-generate nixpkgs#cargo --command \
        cargo generate --path "$REPO/template" --define "license=MIT" --define "gh-username=testuser" "$@"
}

reject_description() {
    local label="$1" expected="$2" value="$3" out
    if out=$(generate --destination "$DESC_DIR" --name desc-rejected --define "description=$value" --define "crate_kind=lib" < /dev/null 2>&1); then
        echo "error: cargo-generate accepted $label" >&2
        exit 1
    fi
    grep -qE "$expected" <<<"$out" || { echo "error: $label: $out" >&2; exit 1; }
    rm -rf "$DESC_DIR/desc-rejected"
}

reject_description 'double quote' 'not a valid value for description' 'A "quoted" project'
reject_description 'newline' 'Failed to parse value|not a valid value for description' $'line one\nline two'  # --define refuses LF first.
