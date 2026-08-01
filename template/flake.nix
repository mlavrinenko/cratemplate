{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    qahq.url = "github:mlavrinenko/qahq";
    # Memoized command runner, taken direct rather than through qahq: the
    # `tags:` this project's .mmz/config.yaml uses need mmz >= 0.5.0, and
    # qahq's own pin lags. Drop this input and use `qahq.packages.*.mmz` once
    # qahq ships >= 0.5.0.
    mmz.url = "github:mlavrinenko/mmz";
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
      mmz,
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
        llvm = pkgs.llvmPackages_21.llvm;
      in
      {
        # For `nix build` & `nix run`:
        packages.default = naersk'.buildPackage {
          src = ./.;
        };

        # For `nix develop`:
        devShells.default = pkgs.mkShell {
          # RUSTC_WRAPPER comes from the host session (e.g. a system-wide build
          # cache like kache); the dev shell inherits it and it never reaches the
          # `nix build` sandbox. No wrapper pinned here.
          nativeBuildInputs = [
            qahq.packages.${system}.cargo-crap
            qahq.packages.${system}.ejectest
            qahq.packages.${system}.jscpd
            qahq.packages.${system}.linecop
            qahq.packages.${system}.outdatty
            # Memoized command runner. Every arm of `just check` runs as
            # `mmz just <subgate>`, so an arm whose declared inputs are
            # unchanged since it last passed is skipped. Rules and their input
            # scopes live in .mmz/config.yaml; `mmz --is-fresh --tag gate`
            # asserts a prior pass without running anything.
            mmz.packages.${system}.default
          ] ++ (with pkgs; [
            rustc
            cargo
            cargo-llvm-cov
            cargo-machete
            cargo-mutants
            cargo-deny
            clippy
            rustfmt
            just
            moreutils
            nixd
            rust-analyzer
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
