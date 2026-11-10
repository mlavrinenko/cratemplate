#!/usr/bin/env bash
# scripts/to-workspace.sh <generated-crate>: `just validate` runs this on a
# generated single-crate project to turn it into the workspace a project grows
# into: the crate moves under crates/<name> (its src, tests and package tables),
# the root keeps the workspace tables and the release profile as a virtual
# manifest, and a second member with a doctest joins it. The second member is
# `publish = false`, so `cargo metadata` selects the one publishable crate the
# release ships. The template must gate the result with no edit, so this touches
# nothing else.
set -euo pipefail

root=$(cd "${1:?usage: to-workspace.sh <generated-crate>}" && pwd)
cd "$root"
name=$(sed -n 's/^name = "\(.*\)"/\1/p' Cargo.toml | head -1)
license=$(sed -n 's/^license = "\(.*\)"/\1/p' Cargo.toml | head -1)
version=$(sed -n 's/^version = "\(.*\)"/\1/p' Cargo.toml | head -1)

mkdir -p "crates/$name"
git mv src "crates/$name/src"
[ ! -d tests ] || git mv tests "crates/$name/tests"

# Split the manifest by its top-level tables: the package's own go to the
# member, the rest (workspace tables, release profile) stays at the root, and
# the version moves to `[workspace.package]`.
awk -v dir="crates/$name" -v version="$version" '
    /^\[/ {
        member = ($0 ~ /^\[(package|lib|\[bin\]|dependencies|dev-dependencies|lints)\]/)
    }
    /^\[workspace\]/ { print "[workspace]\nmembers = [\"crates/*\"]\nresolver = \"3\"\n\n[workspace.package]\nversion = \"" version "\"\n" > "root.toml"; skip = 1; next }
    /^\[/ { skip = 0 }
    skip { next }
    member { print > (dir "/Cargo.toml"); next }
    { print > "root.toml" }
' Cargo.toml
sed -i 's/^version = .*/version.workspace = true/' "crates/$name/Cargo.toml"
mv root.toml Cargo.toml

extra="crates/$name-extra"
mkdir -p "$extra/src"
cat > "$extra/Cargo.toml" <<TOML
[package]
name = "$name-extra"
version.workspace = true
edition = "2024"
rust-version = "1.85"
description = "A second workspace member"
license = "$license"
publish = false

[lints]
workspace = true
TOML
cat > "$extra/src/lib.rs" <<'RS'
//! A second workspace member.

/// The answer.
///
/// ```
/// assert_eq!(extra::answer(), 42);
/// ```
#[must_use]
pub fn answer() -> u32 {
    42
}

#[cfg(test)]
mod tests {
    use super::answer;

    #[test]
    fn answers() {
        assert_eq!(answer(), 42);
    }
}
RS
sed -i "s/extra::answer/$(printf '%s' "$name-extra" | tr - _)::answer/" "$extra/src/lib.rs"
