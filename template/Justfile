set quiet := true

# List available recipes
default:
    @just --list

# Run fixes, then other checks
fix-check: fmt clippy-fix check

# Run all checks in parallel (fmt + clippy + tests + unused deps + file size)
check:
    parallel -j 0 -- \
        "chronic just fmt-check" \
        "chronic cargo clippy --workspace --all-targets -q -- -D warnings" \
        "chronic cargo test --workspace -q" \
        "chronic just machete" \
        "chronic just check-file-size"

# Run tests only
test *ARGS:
    cargo test --workspace {{ ARGS }}

# Run clippy only
clippy:
    cargo clippy --workspace --all-targets -q -- -D warnings

# Auto-fix clippy warnings
clippy-fix:
    cargo clippy --fix --workspace --all-targets -- -D warnings

# Build the project
build:
    cargo build --workspace -q

# Run coverage with tarpaulin
cover:
    cargo tarpaulin --workspace --skip-clean

# Format code
fmt:
    cargo fmt --all

# Format check (CI-friendly)
fmt-check:
    cargo fmt --all -- --check

# Check for unused dependencies
machete:
    cargo machete

# Count tests across workspace
count-tests:
    #!/usr/bin/env bash
    cargo test --workspace 2>&1 | grep "test result:" | awk '{sum += $4} END {print sum " tests"}'

# Show top 20 files by line count
file-sizes:
    #!/usr/bin/env bash
    find . -type f \( -name '*.rs' -o -name '*.md' \) ! -path './target/*' -exec wc -l {} + | sort -rn | head -20

# Check for oversized files (fails if any exceed limits)
check-file-size:
    linecop

# Tag a release and push (usage: just release 0.1.0)
release VERSION:
    #!/usr/bin/env bash
    set -euo pipefail
    just check
    git tag -a "v{{ VERSION }}" -m "v{{ VERSION }}"
    git push origin "v{{ VERSION }}"
