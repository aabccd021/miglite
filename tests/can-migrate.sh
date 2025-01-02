assert_dir=$(mktemp -d)
migration_dir=$(mktemp -d)
db=$(mktemp)

cp ./migrations/s1-user.sql "$migration_dir"
cp ./migrations/s1-tweet.sql "$migration_dir"

stdout=$(tiny-sqlite-migrate --db "$db" --migrations "$migration_dir")

sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$assert_dir/actual.txt"

cat >"$assert_dir/expected.txt" <<EOF
migrations
sqlite_sequence
tweet
user
EOF

diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"

echo "$stdout" >"$assert_dir/stdout_actual.txt"

cat >"$assert_dir/stdout_expected.txt" <<EOF
[JUST APPLIED]   s1-tweet.sql
[JUST APPLIED]   s1-user.sql
EOF

diff --unified --color=always "$assert_dir/stdout_expected.txt" "$assert_dir/stdout_actual.txt"
