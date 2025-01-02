assert_dir=$(mktemp -d)
migration_dir=$(mktemp -d)

cp ./migrations/s1-user.sql "$migration_dir"
cp ./migrations/s1-tweet.sql "$migration_dir"

stdout=$(tiny-sqlite-migrate --db ./db.sqlite --migrations "$migration_dir" || true)
printf "%s" "$stdout" >"$assert_dir/actual.txt"

printf "Database file not found at ./db.sqlite" >"$assert_dir/expected.txt"

diff --unified --color=always "$assert_dir/expected.txt" "$assert_dir/actual.txt"
