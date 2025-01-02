assert_dir=$(mktemp -d)
migration_dir=$(mktemp -d)
db=$(mktemp)

cp ./migrations/s1-user.sql "$migration_dir"
cp ./migrations/s2-tweet.sql "$migration_dir"

tiny-sqlite-migrate --db "$db" --migrations "$migration_dir" >"$assert_dir/actual.txt"
cat >"$assert_dir/expected.txt" <<EOF
[JUST APPLIED]   s1-user.sql
[JUST APPLIED]   s2-tweet.sql
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
