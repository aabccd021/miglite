set -eu

trap 'cd $(pwd)' EXIT
cd "$(mktemp -d)" || exit 1

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

miglite --db "$db" --migrations "$migrations"

cat >"$migrations/s2-tweet.sql" <<EOF
CREATE TABLE tweet (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES user(id)
);
EOF

miglite --db "$db" --migrations "$migrations" >actual.txt

cat >expected.txt <<EOF
[CHECKSUM MATCH] s1-user.sql
[JUST APPLIED]   s2-tweet.sql
EOF

diff --unified --color=always expected.txt actual.txt

sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >actual.txt

cat >expected.txt <<EOF
migrations
sqlite_sequence
user
tweet
EOF

diff --unified --color=always expected.txt actual.txt
