assert_dir=$(mktemp -d)
migrations=$(mktemp -d)

cp ./migrations_template/s1-user.sql "$migrations"
cp ./migrations_template/s2-tweet.sql "$migrations"

exit_code=0
miglite --db ./db.sqlite --migrations "$migrations" >"$assert_dir/actual.txt" || exit_code=$?

if [ "$exit_code" -ne 1 ]; then
  echo "Error: Expected exit code 1, got $exit_code"
  exit 1
fi

echo "Database file not found at ./db.sqlite" >"$assert_dir/expected.txt"

diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"
