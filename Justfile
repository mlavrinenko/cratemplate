# cratemplate maintenance recipes

# Memoize a just recipe in mmz. `just mmz validate bin` skips if
# template/ is unchanged since the last passing run.
mmz *ARGS:
    mmz just {{ ARGS }}

# Validate template by generating a project and running all checks.
# KIND must be "bin" or "lib" (defaults to "bin").
validate KIND='bin':
    #!/usr/bin/env bash
    set -eo pipefail

    kind="{{ KIND }}"
    case "$kind" in
      bin|lib) ;;
      *) echo "usage: just validate <bin|lib>" >&2; exit 1 ;;
    esac

    TEMPLATE_DIR="$(pwd)"
    WORK_DIR="$(mktemp -d)"
    PROJECT_NAME="validate-test-crate"

    cleanup() { rm -rf "$WORK_DIR"; }
    trap cleanup EXIT

    step() { echo "--- $1"; }

    step "Generating $kind project from template"
    nix shell nixpkgs#cargo-generate nixpkgs#cargo --command \
        cargo generate --path "$TEMPLATE_DIR/template" \
            --destination "$WORK_DIR" \
            --name "$PROJECT_NAME" \
            --define "description=Validation test project" \
            --define "license=MIT" \
            --define "gh-username=testuser" \
            --define "crate_kind=$kind"

    cd "$WORK_DIR/$PROJECT_NAME"
    git add -A

    nix develop --command bash -c '
        set -eo pipefail
        just outdatty-update
        just check

        echo "--- Verifying memoized gates (mmz)"
        just check
        mmz --is-fresh --tag gate

        just install-hooks
        test -x "$(git rev-parse --git-path hooks/pre-commit)"

        just build
        just cover
        just crap

        echo "--- Verifying nix build (package) in a clean sandbox"
        git add -A
        nix build .#default
    '

    echo ""
    echo "=== All checks passed ==="
