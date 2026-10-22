set quiet := true

# Shell for every non-shebang recipe line. `-e` aborts the line at its first
# failing command, `-o pipefail` makes a failure anywhere in a pipeline count
# (neither holds in just's default `sh -cu`), so recipes need no per-recipe
# `set -eo pipefail` preamble. No `-u`: recipe bodies interpolate `{{ }}`
# values and read optional env overrides, where an unset name should expand
# empty, not abort. Note that just runs each recipe LINE in a fresh shell —
# a recipe needing one shell across several lines (a variable read back
# later, a `trap`) still carries its own `#!/usr/bin/env bash` shebang, and
# `set shell` does not apply to those.
set shell := ["bash", "-eo", "pipefail", "-c"]

# Keep `#` lines inside a plain recipe in the justfile instead of handing each
# one to its own throwaway shell. Shebang recipe bodies are untouched.
set ignore-comments := true

# Where the Rust sources live. A workspace keeps every member under `crates/`
# (one directory per crate, its `src` and `tests` inside), so the gates that scan
# sources scan that one directory; a single crate at the root has `src` and,
# for a bin, `tests`. Decided by whether `crates/` exists, so moving a crate
# there needs no edit here. `eject_root` is the one root ejectest takes.
rust_roots := if path_exists("crates") == "true" { "crates" } else { "src tests" }
eject_root := if path_exists("crates") == "true" { "crates" } else { "src" }

# List available recipes
default:
    @just --list

# clippy-fix before fmt: a clippy autofix can land unformatted, so format after
# it, and the `check` that follows (which re-runs fmt-check) stays green.
# Run fixes, then other checks
fix-check: eject clippy-fix fmt check

# Run all checks in parallel (fmt + clippy + tests + unused deps + file size +
# drift + copy-paste). Each arm is `just mmz <subgate>` — mmz wraps it, so a
# no-op `just check` re-run skips every arm whose declared inputs are unchanged,
# and `mmz --is-fresh --tag gate` asserts they all passed without running any.
# Per-rule scopes and the `gate` tag live in .mmz/config.yaml.
[parallel]
check: (mmz "fmt-check") (mmz "clippy") (mmz "test") (mmz "machete") (mmz "check-file-size") (mmz "check-dry") (mmz "outdatty-check")

# Wrap a just recipe in mmz: `just mmz fmt-check` runs `mmz just fmt-check`. The
# double hop makes mmz the cache identity (rule name `just <recipe>` in
# .mmz/config.yaml), uniform across every sub-gate of `just check`. `just test
# <filter>` (a developer query, no `mmz`) bypasses this recipe and runs the
# suite directly with ARGS passed to both passes — and the `just test` rule is
# `match: exact`, so even a stray `just mmz test <filter>` cannot record the
# full-suite identity off a filtered subset.
#
# `[no-exit-message]`: on a miss mmz prints its own reason, and just's
# `error: Recipe 'mmz' failed` line above the real output only buries it.
[no-exit-message]
mmz *ARGS:
    mmz just {{ ARGS }}

# Show each memoized rule's freshness — i.e. which arms of `just check` would
# actually re-run, and whether the pre-commit hook's `mmz --is-fresh --tag
# gate` would pass right now. Reads mmz's records; runs no gate.
status:
    mmz --status

# Fail if a source changed without its dependents being re-confirmed
outdatty-check:
    outdatty check

# Re-confirm dependency groups: record current hashes into outdatty.lock
outdatty-update:
    outdatty update

# Run tests only. The gate runs the suite through cargo-nextest — one process
# per test, so a panicking or hanging test is isolated. The output level is
# `.config/nextest.toml`'s `fail`: a green run prints only the run header and
# the summary line, a red one prints every failure's full output. nextest does
# not run doctests, so a second pass covers them. The doctest pass prints five
# lines per workspace member even with no doctests at all, so its output shows
# only when it fails and otherwise keeps just the summaries of members that ran
# a doctest. `--cargo-quiet` drops cargo's `Compiling` lines, which a first
# build prints by the hundred.
#
# `[positional-arguments]` + `"$@"`: ARGS still reach both passes (a plain
# substring filter works for both), but interpolating the variadic would
# re-split a filter containing spaces and re-glob a wildcard.
[positional-arguments]
test *ARGS:
    cargo nextest run --workspace --cargo-quiet "$@"
    out=$(cargo test --workspace --doc -q "$@" 2>&1) || { printf '%s\n' "$out"; exit 1; }; grep -E '^test result: ok\. [1-9]' <<<"$out" || true

# Run clippy only
clippy:
    cargo clippy --workspace --all-targets -q -- -D warnings

# Auto-fix clippy warnings (allow-dirty/-staged: fix-check runs pre-commit, tree is dirty).
clippy-fix:
    cargo clippy --fix --workspace --all-targets --allow-dirty --allow-staged -- -D warnings

# Build the project
build *args:
    cargo build --workspace -q {{ args }}

# Paths kept out of the coverage report, shared by both report passes below.
# main.rs is excluded — keep it thin; `just crap` excludes it too. The
# /registry/src/ ignore keeps local and CI reporting the same set when
# CARGO_HOME is relocated. A file-scope variable, not a shell one: `cover` has
# no shebang, so each of its lines runs in a fresh shell.
cover_ignore := 'src/main\.rs|/registry/src/'

# Run coverage with cargo-llvm-cov, instrumenting the SAME runner as `just
# test` (`cargo llvm-cov nextest`). Process-per-test and shared-process are
# different execution models: a gate that tests one while coverage exercises
# the other can pass a test that fails under the other runner with nothing
# saying so. llvm-cov, unlike tarpaulin, merges the profraw of child
# processes, so subprocess-based CLI e2e tests actually attribute to the code
# they exercise. Instrument once (--no-report), then render both reports from
# that profdata.
#
# The output level is no flag here or in `test`: `.config/nextest.toml` sets it
# once for both runners.
#
# `clean --workspace` first, and it is not tidiness. The `--no-report` +
# separate `report` split does NOT discard earlier profraw, so a long-lived
# checkout merges coverage maps from binaries that no longer exist. Measured on
# a real project: a 106-line file scored as **357 instrumented lines at 21.65%**
# — the pre-split version, still counted weeks after it stopped existing — and a
# workspace headline of 87.58% where the tree was actually 93.45%. It fails
# toward pessimism, so a gate with a floor never complains; what it does instead
# is make every fresh worktree disagree with the main checkout.
cover:
    mkdir -p target/coverage
    cargo llvm-cov clean --workspace
    cargo llvm-cov nextest --workspace --no-report
    cargo llvm-cov report --ignore-filename-regex '{{ cover_ignore }}' \
        --lcov --output-path target/coverage/lcov.info
    cargo llvm-cov report --ignore-filename-regex '{{ cover_ignore }}' --fail-under-lines 70

# Gate complex, undertested functions via CRAP metric. Needs lcov from `just
# cover` first, and REFUSES a stale one rather than scoring it — see
# `_lcov-stale-reason` below. Threshold 30 is a sane greenfield default; tune
# per repo. `--exclude main.rs` is harmless for libs (where the file doesn't
# exist).
#
# Everything else here is one bug in three disguises. cargo-crap's default
# `--missing pessimistic` scores a function with NO coverage record as 0%, and
# three kinds of file have no record:
#
#   - Test code. llvm-cov instruments the code under test, not the suite, so
#     nothing under `tests/` and no ejected `*_tests.rs` has a record. Without
#     these excludes the gate grades your test helpers and can fail on a
#     branchy TEST — measured elsewhere at 101 files scored against a
#     measurement nobody took.
#   - Anything the report was never asked to cover. Keep `--workspace` and the
#     `-p`/exclude set here in step with what `cover` above renders: a member
#     built for another target (a wasm client, say) is uninstrumented, so
#     `--workspace` grades a whole crate at 0%.
#   - Every file newer than the lcov itself, which is what `_lcov-stale-reason`
#     catches.
#
# `--min 30` matched to `--threshold 30` is what makes a green run quiet: the
# table prints only what is at or above the cutoff, so there is nothing to say
# when nothing is wrong, and a red run still names every offender. Measured
# elsewhere at **3532 lines to report success** — every analyzed function,
# passing ones included — against 10 with the flag.
crap:
    #!/usr/bin/env bash
    set -eo pipefail
    reason=$(just _lcov-stale-reason)
    if [ -n "$reason" ]; then
        echo "just crap: $reason — run \`just cover\` first" >&2
        echo "  (a source the lcov never saw scores as 0% covered, not as unknown)" >&2
        exit 1
    fi
    cargo crap --lcov target/coverage/lcov.info --workspace \
        --exclude 'src/main.rs' --exclude 'tests/**' --exclude '**/*_tests.rs' \
        --min 30 --threshold 30 --fail-above

# Is target/coverage/lcov.info usable against the tree in front of it? Empty
# stdout means yes; any other line names why not. It ALWAYS exits 0 — the exit
# status is not the channel, so a caller that treats a reason as ordinary does
# not also get just's own `error: Recipe ... failed` line. One recipe rather
# than a copied `find`, because two staleness tests that could disagree are
# worse than none.
#
# The set is what `cover` measures plus what exercises it: `src` is rendered,
# `tests` is the instrument, so a changed test moves the coverage of files it
# never edited. `rust_roots` names them (`crates/` in a workspace, which holds
# every member's `src` and `tests`). A lib starts with no `tests/` and a clone
# drops empty directories, so the set is searched only where it exists.
#
# Why a refusal and not a `cover` dependency: that recipe is minutes of
# instrumented CPU and this gate is seconds, so someone iterating on one
# function's tests must be able to re-read the existing report. The refusal says
# the number would be a lie and leaves paying for a true one to the caller.
_lcov-stale-reason:
    #!/usr/bin/env bash
    set -eo pipefail
    lcov=target/coverage/lcov.info
    if [ ! -f "$lcov" ]; then
        echo "$lcov is missing"
        exit 0
    fi
    dirs=()
    for d in {{ rust_roots }}; do [ ! -d "$d" ] || dirs+=("$d"); done
    newer=$(find "${dirs[@]}" -name '*.rs' -newer "$lcov" -print -quit)
    if [ -n "$newer" ]; then
        echo "$lcov predates $newer"
    fi

# Format code
fmt:
    cargo fmt --all

# Format check (CI-friendly)
fmt-check:
    cargo fmt --all -- --check

# Check for unused dependencies. cargo-machete has no quiet flag and prints a
# three-line banner to say it found nothing, so its output shows only when it
# fails.
machete:
    out=$(cargo machete 2>&1) || { printf '%s\n' "$out"; exit 1; }

# Count tests across the workspace. `cargo nextest list` reads the suite
# without running it, so the count no longer depends on the runner's output
# format — the old summary scrape ran the whole suite just to count it.
# Ignored tests are excluded, like nextest's own summary. Doctests are not
# counted: only `--json` would report them, and a count is a dev aid, not a
# gate.
count-tests:
    cargo nextest list --workspace --message-format json \
        | jq -r '[.["rust-suites"][].testcases[] | select(.ignored == false)] | "\(length) tests"'

# Show top 20 files by line count. `awk NR<=20` and not `head -20`: head exits
# after its 20th line, which SIGPIPEs sort once the listing outgrows the pipe
# buffer, and pipefail would report that 141 as a recipe failure.
file-sizes:
    find . -type f \( -name '*.rs' -o -name '*.md' \) ! -path './target/*' -exec wc -l {} + | sort -rn | awk 'NR <= 20'

# Eject inline tests from Rust files nearing the linecop limit, so they stay
# under it without losing the inline-test workflow. Runs as part of `fix-check`.
# linecop's `--baseline` exit is informational: it exits 1 merely to FLAG files
# at/over the threshold, not because it failed to run — so the recipe must not
# die on the very finding it exists to fix (masked below). The scan is also
# narrowed to Rust: ejectest moves inline RUST test modules, and a near-limit
# Markdown file has nothing to move.
eject PCT='90':
    #!/usr/bin/env bash
    set -eo pipefail

    # Mask linecop's finding-exit, and only that. `--baseline` is advisory by
    # design — the hard over-limit gate is `just check-file-size`, which runs
    # bare linecop — so exit 1 here means "found files to act on", and must not
    # abort the pipeline before ejectest sees them. Since linecop 0.5, exit 2
    # means a broken run (bad config, missing path), which must still fail.
    rc=0
    paths="$(linecop --baseline {{ PCT }} --format paths)" || rc=$?
    [ "$rc" -le 1 ] || exit "$rc"

    # Rust only: paths outside `{{ eject_root }}` and non-`.rs` files are dropped by
    # ejectest's own --lenient root check anyway, but a Markdown path must not
    # reach a tool that moves inline Rust test modules at all.
    rust_paths="$(printf '%s\n' "$paths" | grep '\.rs$' || true)"

    if [ -n "$rust_paths" ]; then
        printf '%s\n' "$rust_paths" | ejectest apply {{ eject_root }} --files-from - --lenient
    fi

# Check for oversized files (fails if any exceed limits)
check-file-size:
    linecop

# Copy-paste gate: fail on any duplicated Rust block across the crate or workspace.
check-dry:
    # jscpd (the Rust port, packaged via qahq in flake.nix) fails on any
    # duplicated block of >=70 tokens, naming both spans. Fix a finding by
    # extracting a shared helper — never by shuffling tokens until the
    # detector loses the scent.
    #
    # `--exit-code 1` is spelled with its value: bare `--exit-code` would
    # swallow the following path argument as its optional code.
    #
    # `-r ai` because the default console reporter draws a 10-line table to
    # say `0 clones`; the ai reporter says it in 4 and still prints one
    # `a.rs:1-14 ~ b.rs:1-14` line per clone when it fails.
    jscpd --no-tips -k 70 -f rust --exit-code 1 -r ai {{ rust_roots }}

# Dependency audit: advisories, license policy, and dependency bans. Kept out
# of `just check` on purpose — it fetches the advisory database, so it needs
# network and has no business blocking an offline commit. CI runs it in its own
# job, and `just validate` (in the template repo) runs it against a freshly
# generated project, so deny.toml can't silently rot out of schema.
#
# `--hide-inclusion-graph` because the default prints the FULL inclusion tree
# for every crate it has anything to say about, and a `bans` policy warns once
# per duplicate version in the lock. Measured on a real project: **1411 lines
# to say `advisories ok, bans ok, licenses ok`**, against 145 with the flag and
# the identical verdict. The graph is what you want when you are chasing one
# finding, not what you want on every green run — re-run without the flag then,
# which is one word and a fresh answer.
#
# `-L error` because `bans` warns once per duplicate version in the lock, six
# lines each, and the list grows with the tree. Measured in corpuspeak, at six:
# **43 lines to say all three are ok**, against 1. Errors still print in full;
# drop the flag to see the duplicates.
deny:
    cargo deny -L error check --hide-inclusion-graph advisories licenses bans

# List dependencies with newer versions available. Needs network, and is a dev
# aid rather than a gate: an upstream release is not a reason for CI to go red.
# Unrelated to `just outdatty-check`, which is about doc drift inside this repo,
# not dependency versions.
outdated:
    cargo outdated --workspace

# `wt` places the worktree at `../<repo>.<slug>` unless the user configures
# otherwise. Extra flags go to `wt switch`, e.g. `--base=@` to branch from HEAD
# instead of main. The `pre-start` hook in .config/wt.toml allows its `.envrc`.
# Fork a sibling worktree on a new branch (usage: just fork my-slug)
[positional-arguments]
fork SLUG *ARGS:
    wt switch --create --yes "$@"

# Run in the worktree. `--no-squash --no-commit` keeps every branch commit as it
# is and refuses a dirty tree instead of committing it. The rebase merges
# CHANGELOG.md as a union and keeps the target's outdatty.lock (.gitattributes),
# so two lanes that each add an entry land without a conflict. The `pre-merge`
# hooks in .config/wt.toml then record the merged tree in the lock, run the gate
# and the task check before the fast-forward, and `pre-remove` carries the gate
# records and coverage over.
# Gate, fast-forward the branch onto main and remove its worktree
[positional-arguments]
land *ARGS:
    wt merge --no-squash --no-commit --yes "$@"

# Two scratch lanes that both add a CHANGELOG entry and re-confirm
# outdatty.lock, landed one after the other with `just fork` and `just land`
# in a repo under /tmp. Silent on green. Run it after touching .gitattributes,
# the land recipe, .config/wt.toml or .just/scripts/wt-lock.sh.
land-repro:
    bash .just/scripts/land-repro.sh

# Point git at the tracked pre-commit hook (`.githooks/pre-commit` asserts
# `mmz --is-fresh --tag gate` against the worktree, running nothing of its
# own). The dev shell runs this recipe from shellHook on entry, so a fresh
# clone's first `nix develop` wires the hook and edits to the tracked file
# take effect live (no copy to refresh). Bypass a single commit with
# `git commit --no-verify`. It also defines the `outdatty` merge driver that
# .gitattributes names for outdatty.lock: `true`, which leaves the target's copy
# in place for .just/scripts/wt-lock.sh to refresh.
install-hooks:
    git config core.hooksPath .githooks
    git config merge.outdatty.name "keep the target's outdatty.lock"
    git config merge.outdatty.driver true
    rm -f .git/hooks/pre-commit
    chmod +x .githooks/pre-commit
    echo "installed .githooks"

# The tag push is the only publish path: never `cargo publish` by hand, since a
# version already on crates.io used to fail the tag's workflow and leave the
# release half-done. One command does the whole release, so the push of main
# can't be forgotten and no tag lands on a red commit. cargo-release (release.toml)
# bumps the version, dates the entries under [Unreleased] and commits; its
# pre-release-hook, .just/scripts/release-hook.sh, makes every refusal, printing
# `error:` plus a `hint:` with the way out. Then the recipe pushes main
# (fast-forward only), .just/scripts/release-ci.sh waits for the `ci.yml` run on
# that exact commit, and only a green run tags. `--dry-run` runs the checks and
# says what it would push. A tag whose workflow failed is re-run on the same
# tag, never re-tagged: `gh workflow run <release workflow> -f tag=vX.Y.Z`.
# Bump, date, push main, wait for its CI, then tag (usage: just release 0.1.0 [--dry-run])
[arg('DRY_RUN', long='dry-run', value='true')]
[arg('VERSION', pattern='\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?')]
[no-exit-message]
release VERSION $DRY_RUN='':
    #!/usr/bin/env bash
    set -euo pipefail
    args=(--no-confirm)
    [ -n "$DRY_RUN" ] || args+=(--execute)
    cargo release {{ VERSION }} "${args[@]}" --no-tag
    if [ -n "$DRY_RUN" ]; then
        echo "dry run: every check passed"
        echo "would push main, wait for ci.yml on it, then tag and push 'v{{ VERSION }}'"
        exit 0
    fi
    .just/scripts/release-ci.sh {{ VERSION }}
    cargo release tag "${args[@]}"
    cargo release push "${args[@]}" \
        || { git tag -d "v{{ VERSION }}" >/dev/null; echo "error: origin rejected the push of 'v{{ VERSION }}'" >&2; echo "hint: re-run just release {{ VERSION }}" >&2; exit 1; }
    workflow=$(basename "$(ls .github/workflows/release*.yml | head -1)")
    echo "pushed 'v{{ VERSION }}'; follow it with: gh run list --workflow $workflow --limit 1"

# Pre-PR mutation check — the daily driver. Sweeps only mutants touched by
# this branch's diff against main, so it needs no state file and covers new
# files for free (every line of a new file is "touched"). A surviving MISSED
# mutant is a real assertion gap: a line covered but not pinned.
#
# Parallelism defaults to 3 and is overridden from the environment
# (`CARGO_MUTANTS_JOBS=8 just mutants-diff`). The default is resolved by just's
# `env()` rather than a shell `export`, so it is attached to the one command
# that reads it instead of living in the recipe's whole shell.
mutants-diff *ARGS:
    #!/usr/bin/env bash
    set -eo pipefail
    diff_file=$(mktemp)
    trap 'rm -f "$diff_file"' EXIT
    git diff "$(git merge-base main HEAD)" > "$diff_file"
    CARGO_MUTANTS_JOBS='{{ env("CARGO_MUTANTS_JOBS", "3") }}' \
        cargo mutants --in-diff "$diff_file" {{ ARGS }}

# Full-file mutation sweep — a dev aid, never a gate. Extra args pass through
# to cargo-mutants. File set and excludes come from .cargo/mutants.toml.
mutants *ARGS:
    cargo mutants {{ ARGS }}
