{

  nixConfig.allow-import-from-derivation = false;

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";

  outputs =
    { self, ... }@inputs:
    let

      overlay = (
        final: prev: {
          miglite = final.writeShellScriptBin "miglite" ''
            export PATH="${final.sqlite}/bin:$PATH"
            ${builtins.readFile ./miglite.sh}
          '';
        }
      );

      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        overlays = [ overlay ];
      };

      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        programs.prettier.enable = true;
        programs.shfmt.enable = true;
        programs.shellcheck.enable = true;
        settings.formatter.shellcheck.options = [
          "-s"
          "sh"
        ];
      };

      testFiles = {
        test-can-migrate = ./test/can-migrate.sh;
        test-can-migrate-upto = ./test/can-migrate-upto.sh;
        test-can-migrate-again = ./test/can-migrate-again.sh;
        test-no-db-file = ./test/no-db-file.sh;
        test-checksum-match = ./test/checksum-match.sh;
        test-checksum-error = ./test/checksum-error.sh;
        test-checksum-error2 = ./test/checksum-error2.sh;
        test-not-applied = ./test/not-applied.sh;
        test-error = ./test/error.sh;
        test-insert-middle = ./test/insert-middle.sh;
        test-insert-first = ./test/insert-first.sh;
        test-remove-middle = ./test/remove-middle.sh;
        test-remove-Last = ./test/remove-last.sh;
      };

      testConfig = {
        buildInputs = [
          pkgs.miglite
          pkgs.sqlite
        ];
      };

      tests = builtins.mapAttrs (
        testName: testFile: pkgs.runCommand testName testConfig "bash ${testFile} && touch $out"
      ) testFiles;

      formatter = treefmtEval.config.build.wrapper;

      packages = tests // {
        all-tests = pkgs.linkFarm "all-tests" tests;
        formatting = treefmtEval.config.build.check self;
        formatter = formatter;
        miglite = pkgs.miglite;
        default = pkgs.miglite;
      };

    in
    {

      packages.x86_64-linux = packages;
      checks.x86_64-linux = packages;
      formatter.x86_64-linux = formatter;
      overlays.default = overlay;

      devShells.x86_64-linux.default = pkgs.mkShellNoCC {
        buildInputs = [
          pkgs.nixd
        ];
      };
    };
}
