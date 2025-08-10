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

      test =
        pkgs.runCommand "test"
          {
            buildInputs = [ pkgs.sqlite ];
          }
          ''
            cp -L ${./test.sh} ./test.sh
            cp -L ${./miglite.sh} ./miglite.sh
            ./test.sh
            touch "$out";
          '';

      packages = {
        test = test;
        formatting = treefmtEval.config.build.check self;
        miglite = pkgs.miglite;
        default = pkgs.miglite;
      };

    in
    {

      packages.x86_64-linux = packages;

      checks.x86_64-linux = packages;

      overlays.default = overlay;

      formatter.x86_64-linux = treefmtEval.config.build.wrapper;

      devShells.x86_64-linux.default = pkgs.mkShellNoCC {
        buildInputs = [
          pkgs.nixd
        ];
      };
    };
}
