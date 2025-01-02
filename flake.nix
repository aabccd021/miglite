{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    project-utils = {
      url = "github:aabccd021/project-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, treefmt-nix, project-utils }:
    let

      utilPkgs = project-utils.packages.x86_64-linux;
      utilLib = project-utils.lib;

      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      treefmtEval = treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixpkgs-fmt.enable = true;
        programs.prettier.enable = true;
        settings.formatter.prettier.excludes = [ "secrets.yaml" ];
        programs.shfmt.enable = true;
        programs.shellcheck.enable = true;
        settings.formatter.shellcheck.options = [ "-s" "sh" ];
      };

      scripts = {
        checkpoint = utilPkgs.checkpoint;
      };

      tiny-sqlite-migrate = pkgs.writeShellApplication {
        name = "tiny-sqlite-migrate";
        runtimeInputs = [ pkgs.sqlite ];
        text = builtins.readFile ./tiny-sqlite-migrate.sh;
      };

      runTest = testPath: pkgs.runCommandNoCC "run-test"
        { } ''
        export PATH="${tiny-sqlite-migrate}/bin:${pkgs.sqlite}/bin:$PATH"
        cp -Lr ${./migrations} ./migrations
        echo "set -euo pipefail" > ./test.sh
        cat ${testPath} >> ./test.sh
        bash ./test.sh
        touch "$out"
      '';

      tests = {
        can-migrate = runTest ./tests/can-migrate.sh;
      };

      packages = utilLib.safeMergeAttrs [
        scripts
        tests
        {
          formatting = treefmtEval.config.build.check self;
        }
      ];

    in
    {

      formatter.x86_64-linux = treefmtEval.config.build.wrapper;

      packages.x86_64-linux = packages;

      checks.x86_64-linux = packages;

      apps.x86_64-linux = builtins.mapAttrs
        (name: script: {
          type = "app";
          program = "${script}/bin/${name}";
        })
        scripts;

    };
}
