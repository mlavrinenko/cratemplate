# cratemplate maintenance recipes

# Memoize a just recipe in mmz. `just mmz validate bin` skips if
# template/ is unchanged since the last passing run. `[no-exit-message]`: on a
# miss mmz prints its own reason, and just's `error: Recipe 'mmz' failed` line
# above the real output only buries it.
[no-exit-message]
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

    # nixpkgs builds cargo-generate 0.25 without its `git` feature, so it no
    # longer runs `git init` (and ignores `--vcs git`); 0.23 still did. Init
    # here so validate works on either side of that change.
    [ -d .git ] || git init -q

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

        # A host BASH_ENV that re-runs direnv (NixOS ships one at /etc/bash_env)
        # mishandles the scratch project's blocked `.envrc` in every
        # non-interactive `bash -c` that `just` spawns: the hook leaves the
        # shell without the dev shell's PATH, so a recipe dies with
        # `outdatty: command not found` while `sh -c 'command -v outdatty'` in
        # the same shell finds it. The gates need the dev shell, not the host's
        # shell startup.
        unset BASH_ENV

        just outdatty-update
        just check

        echo "--- Verifying memoized gates (mmz)"
        just check
        mmz --is-fresh --tag gate

        # `just release` must refuse before tagging, with an `error:` and a
        # `hint:` line: here on a version Cargo.toml does not carry, and on the
        # uncommitted scratch tree. Neither refusal may leave a tag behind.
        echo "--- Verifying just release refuses before tagging"
        if out=$(just release 9.9.9 --dry-run 2>&1); then echo "release 9.9.9 did not refuse" >&2; exit 1; fi
        grep -q "^error: requested 'v9.9.9' but Cargo.toml is '0.1.0'\$" <<<"$out" || { echo "$out" >&2; exit 1; }
        grep -q '^hint: ' <<<"$out" || { echo "$out" >&2; exit 1; }
        if out=$(just release 0.1.0 2>&1); then echo "release 0.1.0 tagged a dirty tree" >&2; exit 1; fi
        grep -q '^error: ' <<<"$out" || { echo "$out" >&2; exit 1; }
        test -z "$(git tag -l)" || { echo "a refused release left a tag" >&2; exit 1; }

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

        # The full release path, against a local bare origin and a `gh` stub
        # whose ci.yml run ends as $GH_STUB_CI. Release must refuse an origin
        # main that main lacks, push nothing on --dry-run, push main but leave
        # no tag when CI is red, and push the tag only when CI is green.
        echo "--- Verifying just release pushes main, waits for CI, tags only green"
        stub="$(mktemp -d)"
        origin="$stub/origin.git"
        printf '%s\n' '#!/usr/bin/env bash' \
            'case "$1 $2" in' \
            '  "auth status") ;;' \
            '  "run list") echo 42 ;;' \
            '  "run watch") [ "$GH_STUB_CI" = success ] ;;' \
            '  "run view") echo "$GH_STUB_CI" ;;' \
            '  *) echo "gh stub: unexpected $*" >&2; exit 2 ;;' \
            'esac' > "$stub/gh"
        chmod +x "$stub/gh"
        export PATH="$stub:$PATH"
        git config user.name validate
        git config user.email validate@example.invalid
        rm -f result
        git commit -qm scaffold --no-verify
        git branch -M main
        git init -q --bare "$origin"
        git remote add origin "$origin"
        git push -q origin main
        sed -i "s/^## \[Unreleased\]/&\n\n## [0.1.0] - $(date +%F)/" CHANGELOG.md
        just check
        git commit -qam "release 0.1.0" --no-verify
        remote_main() { git ls-remote origin refs/heads/main | cut -f1; }

        git push -q origin "$(git commit-tree 'HEAD~1^{tree}' -p HEAD~1 -m other):refs/heads/main"
        if out=$(just release 0.1.0 --dry-run 2>&1); then echo "release took an origin main that main lacks" >&2; exit 1; fi
        grep -q "^error: origin/main has commits that main lacks\$" <<<"$out" || { echo "$out" >&2; exit 1; }
        git push -qf origin HEAD~1:refs/heads/main

        out=$(GH_STUB_CI=success just release 0.1.0 --dry-run 2>&1) || { echo "$out" >&2; exit 1; }
        grep -q "^would push 1 commit(s) to origin main .*, wait for ci.yml on '$(git rev-parse --short HEAD)', then tag and push 'v0.1.0'\$" <<<"$out" || { echo "$out" >&2; exit 1; }
        test "$(remote_main)" = "$(git rev-parse HEAD~1)" || { echo "--dry-run pushed main" >&2; exit 1; }

        if out=$(GH_STUB_CI=failure just release 0.1.0 2>&1); then echo "release tagged a red CI run" >&2; exit 1; fi
        grep -q "^error: ci.yml ended 'failure' on '$(git rev-parse --short HEAD)', so 'v0.1.0' was not made\$" <<<"$out" || { echo "$out" >&2; exit 1; }
        test "$(grep -c '^hint: ' <<<"$out")" = 2 || { echo "$out" >&2; exit 1; }
        test "$(remote_main)" = "$(git rev-parse HEAD)" || { echo "release did not push main" >&2; exit 1; }
        test -z "$(git tag -l)$(git ls-remote --tags origin)" || { echo "a red CI run left a tag" >&2; exit 1; }

        GH_STUB_CI=success just release 0.1.0
        git ls-remote --exit-code --tags origin refs/tags/v0.1.0 >/dev/null || { echo "release did not push v0.1.0" >&2; exit 1; }
    INNER

    # `nix develop` silently re-resolves (and rewrites flake.lock in place) if
    # the shipped lock ever drifts from flake.nix's inputs. The pre-nix cmp
    # above proves only that the lock SHIPPED; this one proves nothing
    # re-resolved — a re-resolved lock would differ from the template's, and
    # the gate would have tested upstream HEAD instead of the shipped pins.
    cmp -s flake.lock "$TEMPLATE_DIR/template/flake.lock" || { echo "error: nix develop rewrote flake.lock (input drift?) — generated lock no longer matches template/flake.lock" >&2; exit 1; }

    echo ""
    echo "=== All checks passed ==="
