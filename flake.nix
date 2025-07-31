{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts = { url = "github:hercules-ci/flake-parts"; };
  };

  outputs = inputs@{ nixpkgs, flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
      perSystem = { system, config, pkgs, ... }: {
        packages.default = pkgs.callPackage ./derivation.nix {
          inherit (self.packages.${system}) smithy4s;
        };
        packages.smithy4s = let
          bs = (pkgs.callPackage ./bs.nix { });
          version = "0.18.40";
        in bs.wrap {
          inherit version;
          pname = "smithy4s";
          mainClass = "smithy4s.codegen.cli.Main";
          libraryDependencies = [
            "com.disneystreaming.smithy4s:smithy4s-codegen-cli_2.13:${version}"
          ];
          lockFile = ./smithy4s-lock.json;
        };
      };
    };
}

