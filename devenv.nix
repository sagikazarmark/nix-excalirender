{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  packages = with pkgs; [
    bun2nix
  ];

  languages = {
    javascript = {
      enable = true;

      bun.enable = true;
    };
  };
}
