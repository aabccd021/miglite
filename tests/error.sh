assert_dir=$(mktemp -d)
migration_dir=$(mktemp -d)
db=$(mktemp)

cp ./migrations/s1-user.sql "$migration_dir"
tiny-sqlite-migrate --db "$db" --migrations "$migration_dir"

cp ./migrations/s2-error.sql "$migration_dir"

exit_code=0
tiny-sqlite-migrate --db "$db" --migrations "$migration_dir" >"$assert_dir/actual.txt" || exit_code=$?

if [ "$exit_code" -ne 1 ]; then
  echo "Error: Expected exit code 1, got $exit_code"
  exit 1
fi

cat >"$assert_dir/expected.txt" <<EOF
[CHECKSUM MATCH] s1-user.sql
[SQL ERROR]      s2-error.sql
EOF

diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"

sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$assert_dir/actual.txt"

cat >"$assert_dir/expected.txt" <<EOF
migrations
sqlite_sequence
user
EOF

diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"
