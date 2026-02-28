{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      flake-utils,
      nixpkgs,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
        };
      in
      {
        # For `nix develop`:
        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            just
            tokei
            jq
            cargo-generate
          ];
        };
      }
    );
}
