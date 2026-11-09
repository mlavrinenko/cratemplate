set unstable := true

[doc('List available recipes')]
[group('workflow')]
default:
    @just --list

[doc('Run a recipe through mmz memoization')]
[group('workflow')]
[no-exit-message]
mmz *ARGS:
    mmz just {{ ARGS }}

[doc('Generate a project from template/ and run every gate')]
[group('validate')]
validate KIND='bin':
    bash scripts/validate.sh "{{ KIND }}"

[doc('Regenerate the template Markdown docs from docs/src/*.typ')]
[group('validate')]
docs-sync:
    nix shell --inputs-from ./template nixpkgs#just nixpkgs#tinymist nixpkgs#typst nixpkgs#typstyle --command bash -c 'cd template && just docs-md'

[doc('Fail if template docs drifted from docs/src')]
[group('validate')]
docs-check:
    nix shell --inputs-from ./template nixpkgs#just nixpkgs#tinymist nixpkgs#typst nixpkgs#typstyle --command bash -c 'cd template && just docs-md-check'

[doc('Check repository and template docs against linecop limits')]
[group('validate')]
check-docs:
    linecop --config .linecop.yaml .
    linecop --config template/.linecop.yaml template

[doc('Check the backlog and that mt fix would change nothing')]
[group('validate')]
check-tasks:
    mt check && mt fix --check

[doc('Lint workflows and shell scripts')]
[group('validate')]
lint:
    actionlint .github/workflows/*.yml template/.github/workflows/*.yml
    shellcheck -S warning scripts/*.sh template/.just/scripts/*.sh template/.githooks/pre-commit template/.githooks/local-paths
