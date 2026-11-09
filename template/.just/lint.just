# Static gates: actionlint, shellcheck and rustdoc warnings.

set quiet := true
set unstable := true
# Modules run from their own directory; every path below is repo-relative.
set working-directory := '..'
set script-interpreter := ["bash", "-eo", "pipefail"]

[doc("Lint GitHub Actions workflows")]
[group("gate")]
workflows:
    actionlint .github/workflows/*.yml

[doc("Run shellcheck (warning+) on every tracked shebang script")]
[group("gate")]
shellcheck:
    git ls-files -z | xargs -0 awk 'FNR == 1 && /^#!.*[\/ ](ba)?sh( |$)/ { print FILENAME } { nextfile }' | xargs -r -d '\n' shellcheck -S warning

[doc("Fail on rustdoc warnings, private items included")]
[group("gate")]
doc:
    RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps --document-private-items --quiet
