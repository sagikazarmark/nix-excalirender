{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    bun2nix.url = "github:nix-community/bun2nix";
    bun2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, bun2nix, ... }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: lib.genAttrs systems f;

      overlay =
        final: prev:
        lib.optionalAttrs (prev.stdenv.hostPlatform.isLinux || prev.stdenv.hostPlatform.isDarwin) {
          excalirender = final.callPackage ./package.nix {
            bun2nix = bun2nix.packages.${final.stdenv.hostPlatform.system}.bun2nix;
          };
        };
    in
    {
      overlays.default = overlay;

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        lib.optionalAttrs (pkgs.stdenv.hostPlatform.isLinux || pkgs.stdenv.hostPlatform.isDarwin) {
          inherit (pkgs) excalirender;
          default = pkgs.excalirender;
        }
      );
    };
}
