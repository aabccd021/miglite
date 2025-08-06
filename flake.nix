{

  nixConfig.allow-import-from-derivation = false;

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";

  outputs =
    { self, ... }@inputs:
    let
      lib = inputs.nixpkgs.lib;
      collectInputs =
        is:
        pkgs.linkFarm "inputs" (
          builtins.mapAttrs (
            name: i:
            pkgs.linkFarm name {
              self = i.outPath;
              deps = collectInputs (lib.attrByPath [ "inputs" ] { } i);
            }
          ) is
        );

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
        settings.global.excludes = [
          "*.sql"
          "LICENSE"
        ];
      };

      devShells.default = pkgs.mkShellNoCC {
        buildInputs = [ pkgs.nixd ];
      };

      runTest =
        name: testPath:
        pkgs.runCommandNoCC name { } ''
          export PATH="${pkgs.miglite}/bin:${pkgs.sqlite}/bin:$PATH"
          bash ${testPath}
          touch "$out"
        '';

      testFiles = {
        test-can-migrate = ./test/can-migrate.sh;
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

      tests = builtins.mapAttrs runTest testFiles;

      formatter = treefmtEval.config.build.wrapper;

      packages =
        devShells
        // tests
        // {
          all-test = pkgs.linkFarm "all-test" tests;
          formatting = treefmtEval.config.build.check self;
          formatter = formatter;
          allInputs = collectInputs inputs;
          miglite = pkgs.miglite;
          default = pkgs.miglite;
        };

    in
    {

      packages.x86_64-linux = packages // {
        gcroot = pkgs.linkFarm "gcroot" packages;
      };

      checks.x86_64-linux = packages;
      formatter.x86_64-linux = formatter;
      devShells.x86_64-linux = devShells;
      overlays.default = overlay;

    };
}
