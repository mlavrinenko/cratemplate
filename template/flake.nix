{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    ejectest = {
      url = "github:mlavrinenko/ejectest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    linecop = {
      url = "github:mlavrinenko/linecop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    outdatty = {
      url = "github:mlavrinenko/outdatty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      ejectest,
      flake-utils,
      linecop,
      outdatty,
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

        # cargo-crap (CRAP metric gate) isn't in nixpkgs yet; build the
        # published crate from crates.io so the dev shell stays self-contained.
        cargo-crap = pkgs.rustPlatform.buildRustPackage {
          pname = "cargo-crap";
          version = "0.2.2";
          src = pkgs.fetchCrate {
            pname = "cargo-crap";
            version = "0.2.2";
            hash = "sha256-cZ30mdHHLXzpvMhkC6XoPMgfqAdsmdqhEfHq8T15Fmw=";
          };
          cargoHash = "sha256-vzkGNzQrVOtfpGLniGTdPRQfwA9jn5elXhudrFC7w9g=";
          # Dev/CI tool: skip its own test suite to keep the build lean.
          doCheck = false;
        };

      in
      {
        # For `nix build` & `nix run`:
        packages.default = naersk'.buildPackage {
          src = ./.;
        };

        # For `nix develop`:
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            cargo-crap
            ejectest.packages.${system}.default
            linecop.packages.${system}.default
            outdatty.packages.${system}.default
          ] ++ (with pkgs; [
            rustc
            cargo
            cargo-machete
            cargo-tarpaulin
            clippy
            rustfmt
            just
            moreutils
            nixd
            rust-analyzer
            sccache
          ]);
        };
      }
    );
}
