# nix-excalirender

Nix packaging for [`JonRC/excalirender`](https://github.com/JonRC/excalirender).

This package builds `excalirender` from source, installs Bun dependencies via [bun2nix](https://github.com/nix-community/bun2nix),
and rebuilds the native `canvas` addon inside Nix so the final package works on Linux and Darwin.

## Usage

Run it once:

```bash
nix run github:sagikazarmark/nix-excalirender#excalirender -- --help
```

Add it to your dev shell in `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    excalirender.url = "github:sagikazarmark/nix-excalirender";
    excalirender.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, excalirender, ... }:
    let
      system = "aarch64-darwin"; # Replace this with your system
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ excalirender.packages.${system}.excalirender ];
      };
    };
}
```

Or use the overlay:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    excalirender.url = "github:sagikazarmark/nix-excalirender";
    excalirender.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, excalirender, ... }:
    let
      system = "aarch64-darwin"; # Replace this with your system
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ excalirender.overlays.default ];
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.excalirender ];
      };
    };
}
```

## License

The project is licensed under the [MIT License](LICENSE).
