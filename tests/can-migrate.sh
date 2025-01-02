assert_dir=$(mktemp -d)
migration_dir=$(mktemp -d)
db=$(mktemp)

cp ./migrations/user.sql "$migration_dir"
cp ./migrations/tweet.sql "$migration_dir"

tiny-sqlite-migrate --db "$db" --migrations "$migration_dir"

sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$assert_dir/actual.txt"

cat >"$assert_dir/expected.txt" <<EOF
migrations
sqlite_sequence
tweet
user
EOF

diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"
