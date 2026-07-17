{
  description = "Personal Nix packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-2605-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
  };

  outputs =
    inputs:
    let
      nixpkgs = inputs.nixpkgs // {
        legacyPackages = inputs.nixpkgs.legacyPackages // {
          # nixpkgs 26.11 dropped x86_64-darwin; keep its package set on 26.05.
          x86_64-darwin = import inputs.nixpkgs-2605-darwin {
            system = "x86_64-darwin";
            config.allowDeprecatedx86_64Darwin = true;
          };
        };
      };

      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      packages = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          allPackages = pkgs.lib.packagesFromDirectoryRecursive {
            inherit (pkgs) callPackage;
            directory = ./packages;
          };
        in
        pkgs.lib.filterAttrs (
          _: package: pkgs.lib.meta.availableOn pkgs.stdenv.hostPlatform package
        ) allPackages
      );
    in
    {
      inherit packages;

      checks = packages;
    };
}
