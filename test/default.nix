{ pkgs }:
let
  runTest =
    name: testPath:
    pkgs.runCommandNoCC name { } ''
      set -euo pipefail
      export PATH="${pkgs.miglite}/bin:${pkgs.sqlite}/bin:$PATH"
      cp -Lr ${./migrations} ./migrations_template
      echo "set -euo pipefail" > ./test.sh
      cat ${testPath} >> ./test.sh
      bash ./test.sh
      touch "$out"
    '';

  testFiles = {
    test-can-migrate = ./can-migrate.sh;
    test-can-migrate-again = ./can-migrate-again.sh;
    test-no-db-file = ./no-db-file.sh;
    test-checksum-match = ./checksum-match.sh;
    test-checksum-error = ./checksum-error.sh;
    test-checksum-error2 = ./checksum-error2.sh;
    test-not-applied = ./not-applied.sh;
    test-error = ./error.sh;
    test-insert-middle = ./insert-middle.sh;
    test-insert-first = ./insert-first.sh;
    test-remove-middle = ./remove-middle.sh;
    test-remove-Last = ./remove-last.sh;
  };

in
rec {
  tests = builtins.mapAttrs runTest testFiles;
  all-test = pkgs.linkFarm "all-test" tests;
}
