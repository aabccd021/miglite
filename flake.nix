{

  nixConfig.allow-import-from-derivation = false;

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { self, nixpkgs, treefmt-nix }:
    let

      overlay = (final: prev: {
        miglite = final.writeShellApplication {
          name = "miglite";
          runtimeInputs = [ final.sqlite ];
          text = builtins.readFile ./miglite.sh;
        };
      });

      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ overlay ];
      };

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

      test = import ./test {
        pkgs = pkgs;
      };

      packages = test.tests // {
        all-test = test.all-test;
        formatting = treefmtEval.config.build.check self;
        miglite = pkgs.miglite;
        default = pkgs.miglite;
      };

    in
    {

      formatter.x86_64-linux = treefmtEval.config.build.wrapper;

      packages.x86_64-linux = packages;

      checks.x86_64-linux = packages;

      overlays.default = overlay;

    };
}
