assert_dir=$(mktemp -d)
migrations=$(mktemp -d)
db=$(mktemp)

cp ./migrations_template/s1-user.sql "$migrations"
cp ./migrations_template/s2-tweet.sql "$migrations"

miglite --db "$db" --migrations "$migrations"

rm "$migrations"/s2-tweet.sql
cp ./migrations_template/s2-tweet-modified.sql "$migrations"

cp ./migrations_template/s3-favorite.sql "$migrations"
cp ./migrations_template/s4-report.sql "$migrations"

exit_code=0
miglite --db "$db" --migrations "$migrations" >"$assert_dir/actual.txt" || exit_code=$?

if [ "$exit_code" -ne 1 ]; then
  echo "Error: Expected exit code 1, got $exit_code"
  exit 1
fi

cat >"$assert_dir/expected.txt" <<EOF
[CHECKSUM MATCH] s1-user.sql
[CHECKSUM ERROR] s2-tweet-modified.sql
Migration ID      : 2
Database checksum : 3b1f121ee60d7d789d6d10c341a28879
File checksum     : 44552e8bbf16636f7f7c6c9dc8fd4045
EOF

diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"

sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$assert_dir/actual.txt"
cat >"$assert_dir/expected.txt" <<EOF
migrations
sqlite_sequence
user
tweet
EOF
diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"
