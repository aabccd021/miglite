assert_dir=$(mktemp -d)
migration_dir=$(mktemp -d)
db=$(mktemp)

cp ./migrations/s1-user.sql "$migration_dir"
cp ./migrations/s1-tweet.sql "$migration_dir"

tiny-sqlite-migrate --db "$db" --migrations "$migration_dir"

stdout=$(tiny-sqlite-migrate --db "$db" --migrations "$migration_dir")
echo "$stdout" >"$assert_dir/actual.txt"

cat >"$assert_dir/expected.txt" <<EOF
[CHECKSUM MATCH] s1-tweet.sql
[CHECKSUM MATCH] s1-user.sql
EOF

diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"
