assert_dir=$(mktemp -d)
migrations=$(mktemp -d)
db=$(mktemp)

cat >"$migrations/s1-user.sql" <<EOF
CREATE TABLE user (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL
);
EOF

cat >"$migrations/s2-tweet.sql" <<EOF
CREATE TABLE tweet (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES user(id)
);
EOF

cat >"$migrations/s3-favorite.sql" <<EOF
CREATE TABLE favorite (
  user_id INTEGER NOT NULL,
  tweet_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES user(id),
  FOREIGN KEY (tweet_id) REFERENCES tweet(id)
);
EOF

miglite --db "$db" --migrations "$migrations"

rm "$migrations/s2-tweet.sql"

exit_code=0
miglite --db "$db" --migrations "$migrations" >"$assert_dir/actual.txt" || exit_code=$?

if [ "$exit_code" -ne 1 ]; then
  echo "Error: Expected exit code 1, got $exit_code"
  exit 1
fi

cat >"$assert_dir/expected.txt" <<EOF
[CHECKSUM MATCH] s1-user.sql
[CHECKSUM ERROR] s3-favorite.sql
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
