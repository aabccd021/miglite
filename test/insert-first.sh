assert_dir=$(mktemp -d)
migrations=$(mktemp -d)
db=$(mktemp)

cp ./migrations_template/s1-user.sql "$migrations"
cp ./migrations_template/s2-tweet.sql "$migrations"
cp ./migrations_template/s3-favorite.sql "$migrations"

miglite --db "$db" --migrations "$migrations"

cp ./migrations_template/s0-admin.sql "$migrations"

exit_code=0
miglite --db "$db" --migrations "$migrations" >"$assert_dir/actual.txt" || exit_code=$?

if [ "$exit_code" -ne 1 ]; then
  echo "Error: Expected exit code 1, got $exit_code"
  exit 1
fi

cat >"$assert_dir/expected.txt" <<EOF
[CHECKSUM ERROR] s0-admin.sql
Migration ID      : 1
Database checksum : 1b4130145fb7ca626a90a4e1fafe77ab
File checksum     : b81f8a0f30312af0b94cca4bcf5ac3c8
EOF

diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"

sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$assert_dir/actual.txt"
cat >"$assert_dir/expected.txt" <<EOF
migrations
sqlite_sequence
user
tweet
favorite
EOF
diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"
