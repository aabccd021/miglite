{

  nixConfig.allow-import-from-derivation = false;

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";

  outputs = { self, ... }@inputs:
    let

      overlay = (final: prev: {
        miglite = final.writeShellApplication {
          name = "miglite";
          runtimeInputs = [ final.sqlite ];
          text = builtins.readFile ./miglite.sh;
        };
      });

      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        overlays = [ overlay ];
      };

      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixpkgs-fmt.enable = true;
        programs.prettier.enable = true;
        programs.shfmt.enable = true;
        programs.shellcheck.enable = true;
        settings.formatter.shellcheck.options = [ "-s" "sh" ];
        settings.global.excludes = [ "*.sql" "LICENSE" ];
      };

      devShells.default = pkgs.mkShellNoCC {
        buildInputs = [ pkgs.nixd ];
      };

      test = import ./test { pkgs = pkgs; };

      formatter = treefmtEval.config.build.wrapper;

      packages = devShells // test.tests // {
        all-test = test.all-test;
        formatting = treefmtEval.config.build.check self;
        formatter = formatter;
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
