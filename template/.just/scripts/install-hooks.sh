#!/usr/bin/env bash
# .just/scripts/install-hooks.sh: point git at the tracked pre-commit hook and
# define the outdatty and jscpd merge drivers.
#
# .githooks/pre-commit asserts `mmz --is-fresh --tag gate` against the worktree
# and runs nothing of its own. The dev shell's shellHook runs this recipe on
# entry, so a fresh clone's first `nix develop` wires the hook and edits to the
# tracked file take effect live (no copy to refresh). Bypass a single commit
# with `git commit --no-verify`. The merge driver is `true`: it leaves the
# target's outdatty.lock in place for .just/scripts/wt-lock.sh to refresh (see
# .gitattributes). The jscpd driver unions the clone baseline's fingerprints
# through jscpd's built-in `--merge-baseline`; the wrapper falls back to direnv
# when jscpd is not already on PATH.
set -eo pipefail

git config core.hooksPath .githooks
git config merge.outdatty.name "keep the target's outdatty.lock"
git config merge.outdatty.driver true
git config merge.jscpd.name "union the jscpd clone baseline"
git config merge.jscpd.driver '.just/scripts/jscpd-merge-baseline.sh %O %A %B'
rm -f .git/hooks/pre-commit
chmod +x .githooks/pre-commit .githooks/local-paths
echo "installed .githooks"
