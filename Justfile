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
        # sccache). Catches a committed .cargo/config.toml — or any other
        # dev-only setting — leaking into `nix build` and breaking downstream
        # flake consumers. Stage first: flakes filter the source to git-tracked
        # files, and naersk needs the Cargo.lock that `just build` just wrote.
        echo "--- Verifying nix build (package) in a clean sandbox"
        git add -A
        nix build .#default

        # Prove sccache is actually wired in via the dev shell RUSTC_WRAPPER.
        # `just build` above populated the cache; zero the counters, wipe the
        # local target, and rebuild from scratch. sccache should serve those
        # compilations from its store, so cache hits must be > 0. A missing or
        # no-op rustc-wrapper would report zero hits and fail this gate.
        echo "--- Verifying sccache serves compilations"
        sccache --zero-stats >/dev/null
        cargo clean
        cargo build --workspace -q
        sccache --show-stats
        hits=$(sccache --show-stats | awk "/^Cache hits[[:space:]]+[0-9]/ {print \$3; exit}")
        if [ "${hits:-0}" -lt 1 ]; then
            echo "error: sccache reported no cache hits; rustc-wrapper not effective" >&2
            exit 1
        fi
        echo "sccache cache hits after clean rebuild: $hits"
    '

    echo ""
    echo "=== All checks passed ==="
