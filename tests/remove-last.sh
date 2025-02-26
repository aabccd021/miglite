assert_dir=$(mktemp -d)
migrations=$(mktemp -d)
db=$(mktemp)

cp ./migrations_template/s1-user.sql "$migrations"
cp ./migrations_template/s2-tweet.sql "$migrations"
cp ./migrations_template/s3-favorite.sql "$migrations"

miglite --db "$db" --migrations "$migrations"

rm "$migrations/s3-favorite.sql"

miglite --db "$db" --migrations "$migrations" >"$assert_dir/actual.txt"

cat >"$assert_dir/expected.txt" <<EOF
[CHECKSUM MATCH] s1-user.sql
[CHECKSUM MATCH] s2-tweet.sql
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
