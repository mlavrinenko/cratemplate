# On-demand tooling: Nix formatting, secret scans and upstream workaround checks.

set quiet := true
set unstable := true
# Modules run from their own directory; every path below is repo-relative.
set working-directory := '..'
set script-interpreter := ["bash", "-eo", "pipefail"]

# The same roots `just check-dry` scans.
import 'roots.just'

[doc("Format every Nix file in place")]
[group("dev")]
nix-fmt:
    find . \( -path ./.git -o -path ./target -o -path ./.direnv \) -prune -o -type f -name '*.nix' -exec nixfmt {} +

[doc("Fail when a Nix file is not formatted")]
[group("gate")]
nix-fmt-check:
    find . \( -path ./.git -o -path ./target -o -path ./.direnv \) -prune -o -type f -name '*.nix' -exec nixfmt --check {} +

[doc("Check task files and that mt fix would change nothing")]
[group("gate")]
check-tasks:
    bash .just/scripts/check-tasks.sh

[doc("Scan the working tree for secrets (on demand, not a gate)")]
[group("advisory")]
secrets:
    gitleaks dir . --redact --no-banner -v

[doc("Rewrite the committed CRAP ratchet baseline from the current lcov")]
[group("dev")]
crap-baseline:
    bash .just/scripts/crap-baseline.sh

[doc("Rewrite the committed jscpd baseline from the current tree")]
[group("dev")]
dry-baseline:
    jscpd --no-tips -k 70 -f rust --ignore-identifiers --ignore-literals --similarity=0.8 --baseline .config/jscpd-baseline.json --update-baseline -r ai {{ rust_roots }}

[doc("Report workarounds upstream has fixed (needs network)")]
[group("advisory")]
[no-exit-message]
[positional-arguments]
canibump *ARGS:
    canibump --manifest .config/canibump.toml "$@"
