{
  config,
  lib,
  dream2nix,
  ...
}: let
  src = ./.;
in {
  imports = [
    dream2nix.modules.dream2nix.pip
    dream2nix.modules.dream2nix.nodejs-node-modules-v3
  ];

  deps = {nixpkgs, nixpkgs-python-ldap-3_4_0, ...}: {
    inherit
      (nixpkgs)
      postgresql
      openldap
      cyrus_sasl
      rsync
      ;
    inherit
      (nixpkgs-python-ldap-3_4_0.python39Packages)
      ldap
      ;
    python = nixpkgs.python39;
  };

  name = "odoo";
  version = "16.0";

  mkDerivation = {
    inherit src;
  };

  pip = {
    pypiSnapshotDate = "2024-01-01";
    requirementsFiles = [
      "16.0/requirements.txt"
    ];

    flattenDependencies = true;

    # These buildInputs are only used during locking, well-behaved, i.e.
    # PEP 518 packages should not those, but some packages like psycopg2
    # require dependencies to be available during locking in order to execute
    # setup.py. This is fixed in psycopg3
    nativeBuildInputs = [config.deps.postgresql];

    # fix some builds via package-specific overrides
    drvs = {
      psycopg2 = {
        imports = [
          dream2nix.modules.dream2nix.nixpkgs-overrides
        ];

        # We can bulk-inherit overrides from nixpkgs, to which often helps to
        # get something working quickly. In this case it's needed for psycopg2
        # to build on aarch64-darwin. We exclude propagatedBuildInputs to keep
        # python deps from our lock file and avoid version conflicts
        nixpkgs-overrides = {
          exclude = ["propagatedBuildInputs"];
        };
        # packages-specific build inputs that are used for this
        # package only. Included here for demonstration
        # purposes, as nativeBuildInputs from nixpkgs-overrides
        # should already include it
        mkDerivation.nativeBuildInputs = [config.deps.postgresql];
      };
      libsass.mkDerivation = {
        doCheck = false;
        doInstallCheck = lib.mkForce false;
      };
      pypdf2.mkDerivation = {
        doCheck = false;
        doInstallCheck = lib.mkForce false;
      };
      python-ldap.mkDerivation.buildInputs = [config.deps.openldap.dev config.deps.cyrus_sasl.dev];
      python-ldap.mkDerivation.patches = config.deps.ldap.patches;
    };
  };
}