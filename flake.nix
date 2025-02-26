{

  nixConfig.allow-import-from-derivation = false;

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { self, nixpkgs, treefmt-nix }:
    let

      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      treefmtEval = treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixpkgs-fmt.enable = true;
        programs.prettier.enable = true;
        settings.formatter.prettier.excludes = [ "secrets.yaml" ];
        programs.shfmt.enable = true;
        programs.shellcheck.enable = true;
        settings.formatter.shellcheck.options = [ "-s" "sh" ];
        settings.global.excludes = [ "*.sql" "LICENSE" ];
      };

      tiny-sqlite-migrate = pkgs.writeShellApplication {
        name = "tiny-sqlite-migrate";
        runtimeInputs = [ pkgs.sqlite pkgs.gawk ];
        text = builtins.readFile ./tiny-sqlite-migrate.sh;
      };

      runTest = name: testPath:
        pkgs.runCommandNoCC name { } ''
          set -euo pipefail
          export PATH="${tiny-sqlite-migrate}/bin:${pkgs.sqlite}/bin:$PATH"
          cp -Lr ${./migrations} ./migrations_template
          echo "set -euo pipefail" > ./test.sh
          cat ${testPath} >> ./test.sh
          bash ./test.sh
          touch "$out"
        '';

      testFiles = {
        test-can-migrate = ./tests/can-migrate.sh;
        test-can-migrate-again = ./tests/can-migrate-again.sh;
        test-no-db-file = ./tests/no-db-file.sh;
        test-checksum-match = ./tests/checksum-match.sh;
        test-checksum-error = ./tests/checksum-error.sh;
        test-checksum-error2 = ./tests/checksum-error2.sh;
        test-not-applied = ./tests/not-applied.sh;
        test-error = ./tests/error.sh;
        test-insert-middle = ./tests/insert-middle.sh;
        test-remove-middle = ./tests/remove-middle.sh;
        test-remove-Last = ./tests/remove-last.sh;
      };

      tests = builtins.mapAttrs runTest testFiles;

      all-test = pkgs.linkFarm "all-test" tests;

      packages = tests //
        {
          all-test = all-test;
          formatting = treefmtEval.config.build.check self;
          tiny-sqlite-migrate = tiny-sqlite-migrate;
          default = tiny-sqlite-migrate;
        }
      ;

    in
    {

      formatter.x86_64-linux = treefmtEval.config.build.wrapper;

      packages.x86_64-linux = packages;

      checks.x86_64-linux = packages;

    };
}
