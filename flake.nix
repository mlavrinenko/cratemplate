{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    mindtape = {
      url = "github:mlavrinenko/mindtape/v0.5.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mmz.url = "github:mlavrinenko/mmz";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    qahq.url = "github:mlavrinenko/qahq/db3ad7eeba1634477f88eb2c78a330f8430a6b64";
  };

  outputs =
    {
      flake-utils,
      mindtape,
      mmz,
      nixpkgs,
      qahq,
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
          nativeBuildInputs = [
            mindtape.packages.${system}.default
            mmz.packages.${system}.default
            # linecop 0.7.0: `just check-docs` enforces both .linecop.yaml files.
            qahq.packages.${system}.linecop
          ] ++ (with pkgs; [
            # `just lint::workflows` and `just lint::shellcheck` in template/.
            actionlint
            shellcheck
            just
            tokei
            jq
            cargo-generate
          ]);
        };
      in
      {
        devShells.default = shell;
        # Compat alias for older Nix versions that don't resolve devShells.default
        devShell = shell;
      }
    );
}
