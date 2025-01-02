assert_dir=$(mktemp -d)
migration_dir=$(mktemp -d)
db=$(mktemp)

cp ./migrations/s1-user.sql "$migration_dir"
cp ./migrations/s1-tweet.sql "$migration_dir"

tiny-sqlite-migrate --db "$db" --migrations "$migration_dir" >/dev/null

rm "$migration_dir/s1-user.sql"
cp ./migrations/s1-user-modified.sql "$migration_dir"

stdout=$(tiny-sqlite-migrate --db "$db" --migrations "$migration_dir" || true)
echo "$stdout" >"$assert_dir/actual.txt"

cat >"$assert_dir/expected.txt" <<EOF
[CHECKSUM MATCH] s1-tweet.sql
[CHECKSUM ERROR] s1-user-modified.sql
Migration ID      : 2
Database checksum : 12771694d24b05bf862ebc16bcb5d4a3
File checksum     : 71d78c9dbeaf63f86457f81a36a4560e
EOF

diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"
