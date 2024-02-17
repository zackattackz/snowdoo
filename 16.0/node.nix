{
  config,
  lib,
  dream2nix,
  ...
}: let
  src = ./.;
in {
  imports = [
    dream2nix.modules.dream2nix.nodejs-node-modules-v3
  ];

  name = "odoo-node-modules";
  version = "16.0";

  nodejs-package-lock-v3.packageLockFile = ./package-lock.json;
}