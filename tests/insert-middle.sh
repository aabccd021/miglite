assert_dir=$(mktemp -d)
migrations=$(mktemp -d)
db=$(mktemp)

cp ./migrations_template/s1-user.sql "$migrations"
cp ./migrations_template/s2-tweet.sql "$migrations"
cp ./migrations_template/s4-report.sql "$migrations"

miglite --db "$db" --migrations "$migrations"

cp ./migrations_template/s3-favorite.sql "$migrations"

exit_code=0
miglite --db "$db" --migrations "$migrations" >"$assert_dir/actual.txt" || exit_code=$?

if [ "$exit_code" -ne 1 ]; then
  echo "Error: Expected exit code 1, got $exit_code"
  exit 1
fi

cat >"$assert_dir/expected.txt" <<EOF
[CHECKSUM MATCH] s1-user.sql
[CHECKSUM MATCH] s2-tweet.sql
[CHECKSUM ERROR] s3-favorite.sql
Migration ID      : 3
Database checksum : 01e9bc5a4febdd985b95c0c559dbb69e
File checksum     : 0425d8041f846d47b7cc0206951564ae
EOF

diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"

sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$assert_dir/actual.txt"
cat >"$assert_dir/expected.txt" <<EOF
migrations
sqlite_sequence
user
tweet
report
EOF
diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"
