{
  lib,
  stdenv,
  fetchFromGitHub,
  bun,
  bun2nix,
  makeWrapper,
  nodejs,
  pkg-config,
  python3,
  cairo,
  pango,
  libpng,
  libjpeg,
  giflib,
  librsvg,
  pixman,
  fontconfig,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "excalirender";
  version = "1.10.5";

  src = fetchFromGitHub {
    owner = "JonRC";
    repo = "excalirender";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Kk5JdIQGZMeIoks9eNcsyQN08SptPXJ4E/xFMKi6xy8=";
  };

  nativeBuildInputs = [
    bun2nix.hook
    makeWrapper
    nodejs
    pkg-config
    python3
  ];

  buildInputs = [
    cairo
    pango
    libpng
    libjpeg
    giflib
    librsvg
    pixman
    fontconfig
  ];

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ./bun.nix;
    useFakeNode = false;
  };

  env = {
    npm_config_build_from_source = "true";
    npm_config_nodedir = nodejs;
  };

  bunInstallFlags =
    if stdenv.hostPlatform.isDarwin then
      [
        "--production"
        "--linker=hoisted"
        "--backend=copyfile"
      ]
    else
      [
        "--production"
        "--linker=hoisted"
      ];

  dontUseBunBuild = true;
  dontUseBunCheck = true;

  buildPhase = ''
    runHook preBuild

    npm rebuild canvas --build-from-source

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/libexec/${finalAttrs.pname}" "$out/bin"
    cp -r src assets package.json bun.lock node_modules "$out/libexec/${finalAttrs.pname}/"

    makeWrapper ${bun}/bin/bun "$out/bin/${finalAttrs.pname}" \
      --add-flags run \
      --add-flags "$out/libexec/${finalAttrs.pname}/src/index.ts" \
      --set FONTCONFIG_PATH "${fontconfig.out}/etc/fonts" \
      --set FONTCONFIG_FILE "${fontconfig.out}/etc/fonts/fonts.conf"

    runHook postInstall
  '';

  meta = {
    description = "Render Excalidraw files to PNG, SVG, and PDF";
    homepage = "https://github.com/JonRC/excalirender";
    license = lib.licenses.mit;
    mainProgram = finalAttrs.pname;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
