assert_dir=$(mktemp -d)
migrations=$(mktemp -d)
db=$(mktemp)

cp ./migrations_template/s1-user.sql "$migrations"
miglite --db "$db" --migrations "$migrations"

cp ./migrations_template/s2-tweet.sql "$migrations"
cp ./migrations_template/s3-favorite.sql "$migrations"
miglite --db "$db" --migrations "$migrations" --check >"$assert_dir/actual.txt"

cat >"$assert_dir/expected.txt" <<EOF
[CHECKSUM MATCH] s1-user.sql
[NOT APPLIED]    s2-tweet.sql
[NOT APPLIED]    s3-favorite.sql
EOF

diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"

sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$assert_dir/actual.txt"

cat >"$assert_dir/expected.txt" <<EOF
migrations
sqlite_sequence
user
EOF

diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"
