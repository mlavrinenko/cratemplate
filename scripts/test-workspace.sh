#!/usr/bin/env bash
# scripts/test-workspace.sh <bin|lib>: the workspace half of `just validate`,
# run by scripts/validate.sh in the copy of the generated project taken before
# any gate ran. The crate moves under crates/ and a second member joins it (see
# scripts/to-workspace.sh). The template must gate it with no edit. `nix build`
# and `nix run` are here because a virtual workspace has no root package for
# naersk to name the binary after.
set -eo pipefail

kind="${1:?usage: test-workspace.sh <bin|lib>}"
: "${TEMPLATE_DIR:?scripts/validate.sh must export TEMPLATE_DIR}"

bash "$TEMPLATE_DIR/scripts/to-workspace.sh" .
git add -A
KIND="$kind" nix develop --command bash -s <<'WORKSPACE'
set -eo pipefail
command -v cargo >/dev/null || { echo "not in the dev shell" >&2; exit 1; }
unset BASH_ENV

test -d crates && ! test -d src || { echo "the copy is not a workspace" >&2; exit 1; }
just check
just fix-check
just cover
just crap
just deny

# The doctest of the second member runs, and its summary shows.
out=$(just test) || { echo "$out" >&2; exit 1; }
grep -q '^test result: ok\. [1-9]' <<<"$out" || { echo "the doctest pass lost its summary: $out" >&2; exit 1; }

git add -A
nix build .#default
if [ "$KIND" = bin ]; then
    nix run .#default -- --help >/dev/null
fi
WORKSPACE
