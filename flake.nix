{
  inputs = {
    self.submodules = true;

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    git-patcher.url = "github:yuko1101/git-patcher";
    upstream = {
      url = ./upstream;
      flake = false;
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    upstream,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        devShell = pkgs.mkShell {
          buildInputs = [
            inputs.git-patcher.packages.${system}.default
          ];

          GIT_PATCHER_CONFIG = ./patcher.toml;
        };

        packages.src = inputs.git-patcher.lib.applyPatches {
          inherit upstream pkgs;
          src = self;
        };
      }
    );
}
