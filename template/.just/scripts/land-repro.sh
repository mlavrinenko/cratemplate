#!/usr/bin/env bash
# .just/scripts/land-repro.sh: two lanes that both add a CHANGELOG entry and
# re-confirm outdatty.lock land one after the other with no conflict, the
# second ending on a commit that only files a task.
#
# Builds a scratch repo under /tmp (never this one) that carries this repo's
# land machinery as it stands in the working tree: the Justfile, .config/,
# .just/ and .gitattributes. Forks two lanes with `just fork`, lands them with
# `just land`, then checks main holds both entries and a lock that passes
# `outdatty check`. Silent on green; on red it prints the failing step's log.
#
# The scratch gate is `outdatty check` alone: the heavy gates read crates this
# scratch does not have, and a merge touches none of them. A stub `direnv`
# runs its command in the caller's PATH, which already holds the dev shell.
set -euo pipefail

root=$(git rev-parse --show-toplevel)
tmp=$(mktemp -d /tmp/land-repro.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
log="$tmp/step.log"
repo="$tmp/repo"

step() { # step <what> <command...>: run quietly, show the log when it fails
    local what=$1
    shift
    if ! "$@" >"$log" 2>&1; then
        echo "land-repro: $what failed" >&2
        tail -n 40 "$log" >&2
        exit 1
    fi
}

mkdir "$tmp/bin"
# shellcheck disable=SC2016 # a literal stub: $1/$@ expand in it, not here
printf '#!/bin/sh\n[ "$1" = exec ] && { shift 2; exec "$@"; }\nexit 0\n' >"$tmp/bin/direnv"
chmod +x "$tmp/bin/direnv"
export PATH="$tmp/bin:$PATH"
export GIT_AUTHOR_NAME=repro GIT_AUTHOR_EMAIL=repro@example.invalid
export GIT_COMMITTER_NAME=repro GIT_COMMITTER_EMAIL=repro@example.invalid

mkdir -p "$repo/src" "$repo/docs"
(cd "$root" && git ls-files -co --exclude-standard -z -- \
    Justfile .config .just .githooks .gitattributes | tar --null -T - -cf -) |
    tar -xf - -C "$repo"
cd "$repo"
# The gate of the real flow is `just check`; here it is the drift check.
sed -i 's/just check/outdatty check/' .config/wt.toml

printf 'a\n' >src/a.txt
printf 'b\n' >src/b.txt
printf 'c\n' >docs/c.md
cat >CHANGELOG.md <<'EOF'
# Changelog

## [Unreleased]

### Added

- the first entry

### Changed

- the first change
EOF
cat >outdatty.yaml <<'EOF'
require_tracked: ["src/**", "docs/**", "CHANGELOG.md"]
groups:
  - name: notes
    source: ["src/a.txt"]
    dependents: ["CHANGELOG.md"]
  - name: guide
    source: ["src/b.txt"]
    dependents: ["docs/c.md"]
EOF
git init -q -b main
step "the first outdatty update" outdatty update
git add -A
git commit -q -m "chore: start the scratch repo"
step "install-hooks" just install-hooks
# The pre-commit hook asserts a gate record the scratch has none of, so a
# stand-in commit-msg hook replaces the project's hooks and holds the one rule
# the lock fold must respect: a commit that changes anything but task files
# names its task in a `Refs:` footer. (A `fixup!` commit waits for its
# autosquash and is let through.)
mkdir "$tmp/hooks"
cat >"$tmp/hooks/commit-msg" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
grep -q '^fixup! ' "$1" && exit 0
grep -q '^Refs: ' "$1" && exit 0
base=HEAD
# `git commit --amend` is this hook's parent: the commit is then measured
# against HEAD's parent, since HEAD itself is being rewritten.
ps -o args= -p "$PPID" | grep -q -- '--amend' && base=HEAD~
if git diff --cached --name-only "$base" | grep -qv '^tasks/'; then
    echo "commit-msg: a commit outside tasks/ needs a Refs: footer" >&2
    exit 1
fi
HOOK
chmod +x "$tmp/hooks/commit-msg"
git config core.hooksPath "$tmp/hooks"

# The worktree `just fork <slug>` made, wherever worktrunk puts it.
lane_dir() {
    git -C "$repo" worktree list --porcelain | sed -n "s/^worktree //p" | grep -- "$1\$"
}

lane() { # lane <slug> <file>: a lane that adds a CHANGELOG entry
    step "fork $1" just fork "$1"
    (
        cd "$(lane_dir "$1")"
        printf 'edited by %s\n' "$1" >>"$2"
        sed -i "/^- the first entry/a - an entry from $1" CHANGELOG.md
        step "outdatty update in $1" outdatty update
        git add -A
        git commit -q -m "chore($1): add an entry and re-confirm the lock" -m "Refs: $1"
        [ -z "${3:-}" ] || {
            mkdir -p tasks
            printf 'a finding from %s\n' "$1" >"tasks/$1.txt"
            git add -A
            git commit -q -m "chore(tasks): file a finding from $1"
        }
    )
}
lane one src/a.txt
lane two src/b.txt finding

step "landing lane one" bash -c "cd '$(lane_dir one)' && just land"
step "landing lane two after lane one" bash -c "cd '$(lane_dir two)' && just land"

cd "$repo"
step "outdatty check on main" outdatty check
for entry in "an entry from one" "an entry from two"; do
    [ "$(grep -c "^- $entry\$" CHANGELOG.md)" = 1 ] || {
        echo "land-repro: CHANGELOG.md does not hold '$entry' exactly once" >&2
        exit 1
    }
done
if grep -q '^[<=>]\{7\}' CHANGELOG.md outdatty.lock; then
    echo "land-repro: a conflict marker reached main" >&2
    exit 1
fi
# The lock rides with the work commit, so the commit that only files a task
# stays a tasks-only commit.
finding=$(git log -1 --format=%H --grep='file a finding from two')
if git show --name-only --format= "$finding" | grep -qv '^tasks/'; then
    echo "land-repro: the task-filing commit of lane two holds more than task files" >&2
    exit 1
fi
