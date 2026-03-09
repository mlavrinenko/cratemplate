# cratemplate maintenance recipes

# Validate template by generating a project and running all checks
validate:
    #!/usr/bin/env bash
    set -euo pipefail

    TEMPLATE_DIR="$(pwd)"
    WORK_DIR="$(mktemp -d)"
    PROJECT_NAME="validate-test-crate"

    cleanup() { rm -rf "$WORK_DIR"; }
    trap cleanup EXIT

    step() { echo "--- $1"; }

    step "Generating project from template"
    nix shell nixpkgs#cargo-generate --command \
        cargo generate --path "$TEMPLATE_DIR/template" \
            --destination "$WORK_DIR" \
            --name "$PROJECT_NAME" \
            --define "description=Validation test project" \
            --define "license=MIT" \
            --define "gh-username=testuser"

    cd "$WORK_DIR/$PROJECT_NAME"
    git add -A

    # Run all checks inside the generated project's own devShell
    nix develop --command bash -c '
        set -euo pipefail
        step() { echo "--- $1"; }

        step "Checking format"
        cargo fmt --all -- --check

        step "Running clippy"
        cargo clippy --workspace --all-targets -q -- -D warnings

        step "Running tests"
        cargo test --workspace -q

        step "Building"
        cargo build --workspace -q

        step "Checking file sizes"
        just check-file-size

        step "Checking coverage"
        just cover
    '

    echo ""
    echo "=== All checks passed ==="
