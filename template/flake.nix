{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    qahq.url = "github:mlavrinenko/qahq/58f9ec937d7631efb4da8fc38f76bed0a325b696";
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      qahq,
      flake-utils,
      naersk,
      nixpkgs,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
        };

        naersk' = pkgs.callPackage naersk { };

        # nixpkgs' rustc ships no `llvm-tools-preview` component, so
        # cargo-llvm-cov cannot find llvm-cov/llvm-profdata in the sysroot.
        # Point it at a standalone LLVM of the SAME major as rustc's — a
        # mismatched llvm-profdata rejects the profraw format.
        # canibump:llvm-tools - drop the two shell exports when cargo-llvm-cov
        # finds distro LLVM itself.
        llvm = pkgs.llvmPackages_21.llvm;
      in
      {
        # The same nixfmt the dev shell and `just tools::nix-fmt-check` use, so
        # `nix fmt` cannot disagree with the gate.
        formatter = pkgs.nixfmt;

        # For `nix build` & `nix run`. naersk cannot build a crate whose
        # manifest takes a git dependency, so `nix build` fails on one; a crate
        # that takes one needs a different builder. The template has none, so
        # the package keeps naersk. canibump:naersk-git - switch builders when
        # naersk can. `pname` is set because a virtual workspace
        # has no root `[package]`: naersk then falls back to
        # `rust-workspace-unknown` and `nix run` looks for a binary of that name.
        # It names the binary `nix run` starts, so point it at the right crate's
        # when the project becomes a workspace. The version is the workspace's,
        # else the package's.
        packages.default = naersk'.buildPackage {
          src = ./.;
          pname = "{{project-name}}";
          version =
            let
              cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
            in
            cargoToml.workspace.package.version or cargoToml.package.version;
        };

        # For `nix develop`:
        devShells.default = pkgs.mkShell {
          # RUSTC_WRAPPER comes from the host session (e.g. a system-wide build
          # cache like kache); the dev shell inherits it and it never reaches the
          # `nix build` sandbox. No wrapper pinned here.
          nativeBuildInputs = [
            qahq.packages.${system}.canibump
            qahq.packages.${system}.cargo-crap
            qahq.packages.${system}.ejectest
            qahq.packages.${system}.jscpd
            qahq.packages.${system}.linecop
            # Memoized command runner. Every arm of `just check` runs as
            # `mmz just <subgate>`, so an arm whose declared inputs are
            # unchanged since it last passed is skipped. Rules and their input
            # scopes live in .mmz/config.yaml. `mmz --is-fresh --tag gate`
            # asserts a prior pass without running anything.
            qahq.packages.${system}.mmz
            qahq.packages.${system}.outdatty
          ]
          # cargo-generate renders the tracker choice into the condition, so
          # `none` leaves `mt` out of the shell without a second flake input.
          ++ pkgs.lib.optional ("{{ task_tracker }}" == "mindtape") qahq.packages.${system}.mindtape
          ++ (with pkgs; [
            # `just lint::workflows` and `just lint::shellcheck`.
            actionlint
            shellcheck
            # `just tools::secrets`: on demand, because a full scan is slow and
            # the fixtures carry deliberate fakes.
            gitleaks
            rustc
            cargo
            cargo-llvm-cov
            cargo-machete
            cargo-mutants
            cargo-deny
            # The bump, CHANGELOG dating and commit behind `just release`.
            cargo-release
            # cargo-nextest is the test runner `just test` gates on — doctests
            # run in a separate `cargo test --doc` pass, which is why `just
            # test` spells out both. cargo-outdated is a dev aid, deliberately
            # not wired into `just check`: a new upstream release is not a
            # reason for a gate to go red.
            cargo-nextest
            cargo-outdated
            # `wt` forks and lands worktrees: `just fork` and `just land` run
            # it, and .config/wt.toml holds the hooks it fires.
            worktrunk
            # `just count-tests` parses nextest's JSON listing with jq.
            jq
            clippy
            rustfmt
            just
            nixfmt
            nixd
            rust-analyzer
            # Docs pipeline: `typst eval` reads each source's metadata,
            # `typlite` (from tinymist) renders it to Markdown, and `typstyle`
            # formats the Typst sources. All three are nixpkgs packages pinned
            # by flake.lock, so the template adds no flake input for docs.
            typst
            tinymist
            typstyle
          ]);
          shellHook = ''
            export LLVM_COV=${llvm}/bin/llvm-cov
            export LLVM_PROFDATA=${llvm}/bin/llvm-profdata
            # Wire the tracked pre-commit hook (.githooks/) on every shell
            # entry, so a fresh clone's first `nix develop` installs it and
            # a hooksPath edit is picked up live. Quiet: log noise would
            # print on every shell a contributor opens.
            just install-hooks > /dev/null 2>&1
          '';
        };
      }
    );
}
