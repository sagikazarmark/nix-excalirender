{
  description = "Nix packaging for excalirender";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: lib.genAttrs systems f;

      version = "1.10.5";
      sourceSpec = {
        owner = "JonRC";
        repo = "excalirender";
        rev = "v${version}";
        hash = "sha256-Kk5JdIQGZMeIoks9eNcsyQN08SptPXJ4E/xFMKi6xy8=";
      };
      mkExcalirender =
        pkgs:
        let
          runtimeLibraries = with pkgs; [
            cairo
            pango
            libpng
            libjpeg
            giflib
            librsvg
            pixman
            fontconfig
          ];
        in
        pkgs.buildNpmPackage rec {
          pname = "excalirender";
          inherit version;

          src = pkgs.fetchFromGitHub sourceSpec;
          npmDepsFetcherVersion = 3;
          npmDepsHash = "sha256-qMIQ2tj0dk0CTn3SrARosnSIX+rxrk6hrfutO0NRXfw=";

          nativeBuildInputs = with pkgs; [
            bun
            makeWrapper
            pkg-config
          ];

          buildInputs = runtimeLibraries;

          env.npm_config_build_from_source = "true";

          postPatch = ''
            cp ${./package-lock.json} package-lock.json
          '';

          dontNpmBuild = true;
          npmInstallFlags = [ "--omit=dev" ];
          npmPruneFlags = [ "--omit=dev" ];

          installPhase = ''
            runHook preInstall

            mkdir -p "$out/libexec/${pname}" "$out/bin"
            cp -r src assets package.json package-lock.json node_modules "$out/libexec/${pname}/"

            makeWrapper ${pkgs.bun}/bin/bun "$out/bin/${pname}" \
              --add-flags run \
              --add-flags "$out/libexec/${pname}/src/index.ts" \
              --set FONTCONFIG_PATH "${pkgs.fontconfig.out}/etc/fonts" \
              --set FONTCONFIG_FILE "${pkgs.fontconfig.out}/etc/fonts/fonts.conf"

            runHook postInstall
          '';

          meta = {
            description = "Render Excalidraw files to PNG, SVG, and PDF";
            homepage = "https://github.com/JonRC/excalirender";
            license = lib.licenses.mit;
            mainProgram = pname;
            platforms = systems;
            sourceProvenance = [ lib.sourceTypes.fromSource ];
          };
        };

      overlay =
        final: prev:
        lib.optionalAttrs (prev.stdenv.hostPlatform.isLinux || prev.stdenv.hostPlatform.isDarwin) {
          excalirender = mkExcalirender final;
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
