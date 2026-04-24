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

        src = inputs.git-patcher.lib.applyPatches {
          inherit upstream pkgs;
          src = self;
        };
        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit src;
          hash = "sha256-dZ5tnRgbivbrutmI8DJ/qmTd+yGW8UjkcnJddFk04s8=";
        };
        version = (builtins.fromTOML (builtins.readFile "${src}/Cargo.toml")).package.version;

        # TODO: implement original packages instead of overriding nixpkgs
        nushell = pkgs.nushell.overrideAttrs (oldAttrs: {
          inherit src cargoDeps version;
          cargoBuildFlags =
            (oldAttrs.cargoBuildFlags or [])
            ++ [
              "--features"
              "system-clipboard"
            ];
          doCheck = false;
        });
        nu_plugin_polars = pkgs.nushellPlugins.polars.overrideAttrs (oldAttrs: {
          inherit src cargoDeps version;
        });
      in {
        devShell = pkgs.mkShell {
          buildInputs = [
            inputs.git-patcher.packages.${system}.default
          ];

          GIT_PATCHER_CONFIG = ./patcher.toml;
        };

        packages = {
          inherit src nushell nu_plugin_polars;
          default = nushell;
        };
      }
    );
}
