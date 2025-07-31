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
        packages.smithy4s = pkgs.callPackage ./smithy4s.nix {
          bs = pkgs.callPackage ./bs.nix { };
        };
      };
    };
}

