{ nixpkgs, nixpkgs-python-ldap-3_4_0, dream2nix, ... }:
rec {
  make-drv = defaults: {
    extra-python-packageSets ? {},
    extra-python-modules ? [],
    python-raw ? defaults.python.raw,
    extra-python-specialArgs ? {},
    extra-node-packageSets ? {},
    extra-node-modules ? [],
    node-raw ? defaults.node.raw,
    extra-node-specialArgs ? {},
  }:
    { 
      python = dream2nix.lib.evalModules {
        packageSets = defaults.python.packageSets // extra-python-packageSets;
        modules = defaults.python.modules ++ extra-python-modules;
        raw = python-raw;
        specialArgs = defaults.python.specialArgs // extra-python-specialArgs;
      };
      node = dream2nix.lib.evalModules {
        packageSets = defaults.node.packageSets // extra-node-packageSets;
        modules = defaults.node.modules ++ extra-node-modules;
        raw = node-raw;
        specialArgs = defaults.node.specialArgs // extra-node-specialArgs;
      };
    };
  drv-builders = {
    v16_0 = make-drv {
      python = {
        packageSets = {
          inherit nixpkgs nixpkgs-python-ldap-3_4_0;
        };
        modules = [
          ./16.0/python.nix
          {
            paths.projectRoot = ./.;
            paths.projectRootFile = "flake.nix";
            paths.package = "16.0";
          }
        ];
        raw = false;
        specialArgs = {};
      };
      node = {
        packageSets = {
          inherit nixpkgs;
        };
        modules = [
          ./16.0/node.nix
          {
            paths.projectRoot = ./.;
            paths.projectRootFile = "flake.nix";
            paths.package = "16.0";
          }
        ];
        raw = false;
        specialArgs = {};
      };
    };
  };
  drvs = {
    v16_0 = drv-builders.v16_0 {};
  };
  # Create a PATH string from all given binPaths
  makeBinPath = binPaths: with nixpkgs.lib;
    strings.concatStrings
      (strings.intersperse
        ":"
        (map
          (x: "${x.pkg}/${x.binPath}")
          binPaths));
  versionToBinPaths = {
    v16_0 = with nixpkgs; {
      python = {
        pkg = drvs.v16_0.python.pyEnv;
        binPath = "bin";
      };
      node = {
        pkg = drvs.v16_0.node;
        binPath = "lib/node_modules/.bin";
      };
      wkhtmltopdf = {
        # TODO: Make our own derivation for this for 0.12.5
        pkg = wkhtmltopdf-bin;
        binPath = "bin";
      };
      rtlcss = {
        pkg = rtlcss;
        binPath = "bin";
      };
      xz = {
        pkg = xz;
        binPath = "bin";
      };
    };
  };
  makePython = binPath: nixpkgs.writeShellScriptBin "python" ''
    export PATH="${binPath}:$PATH"
    export SSL_CERT_FILE="${nixpkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    python "$@"
  '';
  makePythons = versionToBinPaths: with nixpkgs.lib;
    (mapAttrs
      (version: binPaths:
        (makePython (makeBinPath (attrValues binPaths))))
      versionToBinPaths);
}