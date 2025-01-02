assert_dir=$(mktemp -d)
migration_dir=$(mktemp -d)
db=$(mktemp)

cp ./migrations/user.sql "$migration_dir"
cp ./migrations/tweet.sql "$migration_dir"

tiny-sqlite-migrate --db "$db" --migrations "$migration_dir"

stdout=$(tiny-sqlite-migrate --db "$db" --migrations "$migration_dir")
echo "$stdout" >"$assert_dir/actual.txt"

cat >"$assert_dir/expected.txt" <<EOF
[CHECKSUM MATCH] tweet.sql
[CHECKSUM MATCH] user.sql
EOF

diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"
