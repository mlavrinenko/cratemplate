#!/usr/bin/env bash
# .just/scripts/wt-lock.sh refresh|amend <target>: the worktrunk `pre-merge`
# hooks that settle outdatty.lock after the rebase (.config/wt.toml).
#
# outdatty.lock holds one hash per coupled file, so two lanes that edit one
# file (every lane adds a CHANGELOG entry) edit one lock line. .gitattributes
# hands the lock to the `outdatty` merge driver, which keeps the target's copy
# (`just install-hooks` sets it), so the rebase never stops on it, but the
# lane's own lines are gone. The two modes put them back:
#
#   refresh  runs before the gate. When `outdatty check` is red, `outdatty
#            update` records the merged tree. Every lane commit passed the
#            pre-commit hook, which holds the check, so what is stale is the
#            merge's doing and not a review the lane skipped.
#   amend    runs after the gate has passed on that lock. It folds the lock
#            into the lane's last commit: a commit of its own would need a
#            `Refs:` footer, and pre-commit wants the lock staged.
#
# A crate without outdatty.lock or outdatty has nothing to settle.
set -euo pipefail

mode=${1:?usage: wt-lock.sh refresh|amend <target>}
target=${2:?usage: wt-lock.sh refresh|amend <target>}

[ -f outdatty.lock ] || exit 0
if ! command -v outdatty >/dev/null; then
    echo "wt-lock: outdatty.lock exists but outdatty is not on PATH, so the lock was left as rebased" >&2
    exit 0
fi

case $mode in
refresh)
    outdatty check --format quiet || outdatty update --format quiet
    ;;
amend)
    git diff --quiet -- outdatty.lock && exit 0
    # Nothing of the lane's own to fold the lock into.
    [ "$(git rev-list --count "$target"..HEAD)" -gt 0 ] || exit 0
    git add outdatty.lock
    git commit -q --amend --no-edit
    ;;
*)
    echo "usage: wt-lock.sh refresh|amend <target>" >&2
    exit 2
    ;;
esac
