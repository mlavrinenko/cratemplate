# On-demand tooling: Nix formatting, secret scans and upstream workaround checks.

set quiet := true
set unstable := true
# Modules run from their own directory; every path below is repo-relative.
set working-directory := '..'
set script-interpreter := ["bash", "-eo", "pipefail"]

[doc("Format every Nix file in place")]
[group("dev")]
nix-fmt:
    find . \( -path ./.git -o -path ./target -o -path ./.direnv \) -prune -o -type f -name '*.nix' -exec nixfmt {} +

[doc("Fail when a Nix file is not formatted")]
[group("gate")]
nix-fmt-check:
    find . \( -path ./.git -o -path ./target -o -path ./.direnv \) -prune -o -type f -name '*.nix' -exec nixfmt --check {} +

[doc("Scan the working tree for secrets (on demand, not a gate)")]
[group("advisory")]
secrets:
    gitleaks dir . --redact --no-banner -v
