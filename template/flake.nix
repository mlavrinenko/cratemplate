{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    linecop = {
      url = "github:mlavrinenko/linecop";
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
      flake-utils,
      linecop,
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

      in
      {
        # For `nix build` & `nix run`:
        packages.default = naersk'.buildPackage {
          src = ./.;
        };

        # For `nix develop`:
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            linecop.packages.${system}.default
          ] ++ (with pkgs; [
            rustc
            cargo
            cargo-tarpaulin
            clippy
            rustfmt
            just
            nixd
            rust-analyzer
          ]);
        };
      }
    );
}
