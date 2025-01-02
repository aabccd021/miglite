assert_dir=$(mktemp -d)
migration_dir=$(mktemp -d)

cp ./migrations/s1-user.sql "$migration_dir"
cp ./migrations/s2-tweet.sql "$migration_dir"

exit_code=0
tiny-sqlite-migrate --db ./db.sqlite --migrations "$migration_dir" >"$assert_dir/actual.txt" || exit_code=$?

if [ "$exit_code" -ne 1 ]; then
  echo "Error: Expected exit code 1, got $exit_code"
  cat actual.txt
  exit 1
fi

echo "Database file not found at ./db.sqlite" >"$assert_dir/expected.txt"

diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"
