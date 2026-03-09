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
      let
        shell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            just
            tokei
            jq
            cargo-generate
          ];
        };
      in
      {
        devShells.default = shell;
        # Compat alias for older Nix versions that don't resolve devShells.default
        devShell = shell;
      }
    );
}
