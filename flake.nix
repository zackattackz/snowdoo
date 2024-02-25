{
  description = "Flake providing python interpreters (with dependencies) for various odoo versions";

  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
    nixpkgs.follows = "dream2nix/nixpkgs";
    nixpkgs-python-ldap-3_4_0.url = "github:NixOS/nixpkgs/f597e7e9fcf37d8ed14a12835ede0a7d362314bd";
  };

  outputs = inputs @ {
    self,
    dream2nix,
    nixpkgs,
    nixpkgs-python-ldap-3_4_0,
    ...
  }: let
    system = "x86_64-linux";
    importPkgs = pkgs: import pkgs {
      inherit system;
      config.allowUnfree = true;
      config.allowUnfreePredicate = pkg: true;
      config.permittedInsecurePackages = [
          # Required by wkhtmltopdf-bin
          "openssl-1.1.1w"
        ];
    };
    snowdoo-lib-args = {
      inherit dream2nix;
      nixpkgs = importPkgs nixpkgs;
      nixpkgs-python-ldap-3_4_0 = inputs.nixpkgs-python-ldap-3_4_0.legacyPackages.${system};
    };
    snowdoo-lib = import ./lib snowdoo-lib-args;
  in {
    packages.${system} = with snowdoo-lib;
    {
      lib = snowdoo-lib;
      pythons = makePythons versionToBinPaths;
    };
  };
}