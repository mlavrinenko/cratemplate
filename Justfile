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
    nix shell nixpkgs#cargo-generate nixpkgs#cargo --command \
        cargo generate --path "$TEMPLATE_DIR/template" \
            --destination "$WORK_DIR" \
            --name "$PROJECT_NAME" \
            --define "description=Validation test project" \
            --define "license=MIT" \
            --define "gh-username=testuser"

    cd "$WORK_DIR/$PROJECT_NAME"
    git add -A

    # Run all checks inside the generated project's own devShell. The one-time
    # `outdatty-update` mirrors the post-generation bootstrap: it writes the
    # initial outdatty.lock so the drift check in `just check` has a baseline.
    nix develop --command bash -c '
        set -euo pipefail
        just outdatty-update
        just check
        just build
        just cover
        just crap

        # Package build must succeed in a clean sandbox (no dev shell, no
        # rustc-wrapper). Catches a committed .cargo/config.toml — or any other
        # dev-only setting — leaking into `nix build` and breaking downstream
        # flake consumers. Stage first: flakes filter the source to git-tracked
        # files, and naersk needs the Cargo.lock that `just build` just wrote.
        echo "--- Verifying nix build (package) in a clean sandbox"
        git add -A
        nix build .#default
    '

    echo ""
    echo "=== All checks passed ==="
