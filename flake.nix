{
  description = "My flake with dream2nix packages";

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
    pkgs = importPkgs nixpkgs;
    odoo16_0 = (dream2nix.lib.evalModules {
      packageSets.nixpkgs = pkgs;
      packageSets.nixpkgs-python-ldap-3_4_0 = inputs.nixpkgs-python-ldap-3_4_0.legacyPackages.${system};
      modules = [
        ./default.nix
        {
          paths.projectRoot = ./.;
          # can be changed to ".git" or "flake.nix" to get rid of .project-root
          paths.projectRootFile = "flake.nix";
          paths.package = ./.;
        }
      ];
    });
    # We use npm to get lessc, because the required version is not available in nixpkgs
    odoo16_0_node_modules = (dream2nix.lib.evalModules {
      packageSets.nixpkgs = pkgs;
      modules = [
        ./node.nix
        {
          paths.projectRoot = ./.;
          # can be changed to ".git" or "flake.nix" to get rid of .project-root
          paths.projectRootFile = "flake.nix";
          paths.package = ./.;
        }
      ];
    });
    # Create a PATH with all the bin paths of the given packages/binPaths
    makeBinPath = pkgsWithBinPaths: with nixpkgs.lib;
      strings.concatStrings
        (strings.intersperse
          ":"
          (map
            (x: "${x.pkg}/${x.binPath}")
            pkgsWithBinPaths));
    pkgsWithBinPaths = with pkgs; [
      {
        pkg = odoo16_0.pyEnv;
        binPath = "bin";
      }
      {
        pkg = odoo16_0_node_modules;
        binPath = "lib/node_modules/.bin";
      }
      {
        # TODO: Make our own derivation for this for 0.12.5
        pkg = wkhtmltopdf-bin;
        binPath = "bin";
      }
      {
        pkg = rtlcss;
        binPath = "bin";
      }
      {
        pkg = xz;
        binPath = "bin";
      }
    ];
  in {
    packages.${system}.default = pkgs.writeShellScriptBin "python" ''
        export PATH="${makeBinPath pkgsWithBinPaths}:$PATH"
        export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        python "$@"
      '';
    lock = odoo16_0.lock;
  };
}