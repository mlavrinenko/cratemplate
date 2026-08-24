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

    # Assert the shipped lock actually reaches the generated project. cargo-generate
    # ships flake.lock today (see cargo-generate.toml), but if the ignore list ever
    # regresses, validate must fail loudly: a scratch project that free-resolves
    # upstream HEAD would silently stop testing the template's own pins, and a
    # stale flake.lock would rot (qahq pinned at outdatty 0.3.0 while outdatty.yaml
    # used require_tracked, which only 0.4.0 knows).
    test -f flake.lock || { echo "error: cargo-generate did not ship flake.lock (ignore list regressed?)" >&2; exit 1; }
    cmp -s flake.lock "$TEMPLATE_DIR/template/flake.lock" || { echo "error: generated flake.lock differs from template/flake.lock" >&2; exit 1; }

    git add -A

    # Fed to `bash -s` over a QUOTED heredoc, not `bash -c '...'`. Same
    # semantics (no expansion by the outer shell), but an apostrophe in the body
    # is inert: inside a single-quoted string one would close the quote early
    # and silently run the remainder in the OUTER shell, where the generated
    # project has no Rust toolchain and gates pass or fail for the wrong reason.
    nix develop --command bash -s <<'INNER'
        set -eo pipefail

        # The gates below are only meaningful inside the dev shell. If this
        # block ever escapes it, fail loudly instead of misreporting.
        command -v cargo >/dev/null || { echo "not in the dev shell" >&2; exit 1; }

        just outdatty-update
        just check

        echo "--- Verifying memoized gates (mmz)"
        just check
        mmz --is-fresh --tag gate

        # Regression for the eject recipe: a Markdown file at >= the eject
        # baseline (90% of the 200-line Markdown limit) must not red `just
        # fix-check`. linecop's `--baseline` exit-1 is informational (a finding,
        # not a failure to run), and the eject scan is Rust-only — it used to
        # die on the producer before ejectest even ran. Grow README.md past the
        # baseline, then run the real fix step; the gate must stay green.
        echo "--- Regression: near-limit Markdown must not red just fix-check"
        n=0
        while [ "$(wc -l < README.md)" -lt 180 ] && [ "$n" -lt 500 ]; do
            printf '%s\n' "<!-- near-limit regression filler -->" >> README.md
            n=$((n + 1))
        done
        just fix-check

        just install-hooks
        test -x "$(git rev-parse --git-path hooks/pre-commit)"

        just build
        just cover
        just crap

        # cargo-deny rejects a retired config key outright, so a deny.toml
        # that has drifted out of schema fails CI in every generated project.
        just deny

        echo "--- Verifying nix build (package) in a clean sandbox"
        git add -A
        nix build .#default
    INNER

    # `nix develop` silently re-resolves (and rewrites flake.lock in place) if
    # the shipped lock ever drifts from flake.nix's inputs. The pre-nix cmp
    # above proves only that the lock SHIPPED; this one proves nothing
    # re-resolved — a re-resolved lock would differ from the template's, and
    # the gate would have tested upstream HEAD instead of the shipped pins.
    cmp -s flake.lock "$TEMPLATE_DIR/template/flake.lock" || { echo "error: nix develop rewrote flake.lock (input drift?) — generated lock no longer matches template/flake.lock" >&2; exit 1; }

    echo ""
    echo "=== All checks passed ==="
