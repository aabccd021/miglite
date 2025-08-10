#!/bin/sh

set -eu

(

  printf "\n# Success\n"
  migrations=$(mktemp -d)
  tmp=$(mktemp -d)
  db=$(mktemp)

  echo "CREATE TABLE user (id INTEGER)" >"$migrations/s1-user.sql"

  ./miglite.sh --db "$db" --migrations "$migrations"

  echo "CREATE TABLE tweet (tweet_id INTEGER)" >"$migrations/s2-tweet.sql"

  ./miglite.sh --db "$db" --migrations "$migrations" >"$tmp/actual.txt"

  {
    echo "[CHECKSUM MATCH] s1-user.sql"
    echo "[JUST APPLIED]   s2-tweet.sql"
  } >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"

  sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$tmp/actual.txt"

  {
    echo "migrations"
    echo "sqlite_sequence"
    echo "user"
    echo "tweet"
  } >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"
)

(

  printf "\n# Up To Migration\n"
  migrations=$(mktemp -d)
  tmp=$(mktemp -d)
  db=$(mktemp)

  echo "CREATE TABLE user (id INTEGER)" >"$migrations/s1-user.sql"
  echo "CREATE TABLE tweet (tweet_id INTEGER)" >"$migrations/s2-tweet.sql"
  echo "CREATE TABLE favorite (fav_id INTEGER)" >"$migrations/s3-favorite.sql"
  echo "CREATE TABLE report (rep_id INTEGER)" >"$migrations/s4-report.sql"

  ./miglite.sh --db "$db" --migrations "$migrations" --up-to "s2-tweet.sql" >"$tmp/actual.txt"

  {
    echo "[JUST APPLIED]   s1-user.sql"
    echo "[JUST APPLIED]   s2-tweet.sql"
  } >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"

  sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$tmp/actual.txt"
  {
    echo "migrations"
    echo "sqlite_sequence"
    echo "user"
    echo "tweet"
  } >"$tmp/expected.txt"
  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"
)

(

  printf "\n# Multiple Apply\n"
  migrations=$(mktemp -d)
  tmp=$(mktemp -d)
  db=$(mktemp)

  echo "CREATE TABLE user (id INTEGER)" >"$migrations/s1-user.sql"
  echo "CREATE TABLE tweet (tweet_id INTEGER)" >"$migrations/s2-tweet.sql"

  ./miglite.sh --db "$db" --migrations "$migrations" >"$tmp/actual.txt"
  {
    echo "[JUST APPLIED]   s1-user.sql"
    echo "[JUST APPLIED]   s2-tweet.sql"
  } >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"

  sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$tmp/actual.txt"

  {
    echo "migrations"
    echo "sqlite_sequence"
    echo "user"
    echo "tweet"
  } >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"
)

(

  printf "\n# Checksum Error - User Table\n"
  migrations=$(mktemp -d)
  tmp=$(mktemp -d)
  db=$(mktemp)

  echo "CREATE TABLE user (id INTEGER)" >"$migrations/s1-user.sql"
  echo "CREATE TABLE tweet (tweet_id INTEGER)" >"$migrations/s2-tweet.sql"

  ./miglite.sh --db "$db" --migrations "$migrations" >/dev/null

  rm "$migrations/s1-user.sql"
  echo "CREATE TABLE user (id TEXT)" >"$migrations/s1-user.sql"

  exit_code=0
  ./miglite.sh --db "$db" --migrations "$migrations" >"$tmp/actual.txt" || exit_code=$?
  if [ "$exit_code" -ne 1 ]; then
    echo "Error: Expected exit code 1, got $exit_code"
    exit 1
  fi

  echo "[CHECKSUM ERROR] s1-user.sql" >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"

  sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$tmp/actual.txt"

  {
    echo "migrations"
    echo "sqlite_sequence"
    echo "user"
    echo "tweet"
  } >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"
)

(

  printf "\n# Checksum Error - Tweet Table\n"
  migrations=$(mktemp -d)

  echo "CREATE TABLE user (id INTEGER)" >"$migrations/s1-user.sql"
  echo "CREATE TABLE tweet (tweet_id INTEGER)" >"$migrations/s2-tweet.sql"

  tmp=$(mktemp -d)
  db=$(mktemp)
  ./miglite.sh --db "$db" --migrations "$migrations"

  echo "CREATE TABLE tweet (tweet_id TEXT)" >"$migrations/s2-tweet.sql"
  echo "CREATE TABLE favorite (fav_id INTEGER)" >"$migrations/s3-favorite.sql"
  echo "CREATE TABLE report (rep_id INTEGER)" >"$migrations/s4-report.sql"

  exit_code=0
  ./miglite.sh --db "$db" --migrations "$migrations" >"$tmp/actual.txt" || exit_code=$?
  if [ "$exit_code" -ne 1 ]; then
    echo "Error: Expected exit code 1, got $exit_code"
    exit 1
  fi

  {
    echo "[CHECKSUM MATCH] s1-user.sql"
    echo "[CHECKSUM ERROR] s2-tweet.sql"
  } >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"

  sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$tmp/actual.txt"
  {
    echo "migrations"
    echo "sqlite_sequence"
    echo "user"
    echo "tweet"
  } >"$tmp/expected.txt"
  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"
)

(

  printf "\n# Apply Remaining\n"
  migrations=$(mktemp -d)
  tmp=$(mktemp -d)
  db=$(mktemp)

  echo "CREATE TABLE user (id INTEGER)" >"$migrations/s1-user.sql"
  echo "CREATE TABLE tweet (tweet_id INTEGER)" >"$migrations/s2-tweet.sql"

  ./miglite.sh --db "$db" --migrations "$migrations"

  echo "CREATE TABLE favorite (fav_id INTEGER)" >"$migrations/s3-favorite.sql"
  echo "CREATE TABLE report (rep_id INTEGER)" >"$migrations/s4-report.sql"

  ./miglite.sh --db "$db" --migrations "$migrations" >"$tmp/actual.txt"

  {
    echo "[CHECKSUM MATCH] s1-user.sql"
    echo "[CHECKSUM MATCH] s2-tweet.sql"
    echo "[JUST APPLIED]   s3-favorite.sql"
    echo "[JUST APPLIED]   s4-report.sql"
  } >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"

  sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$tmp/actual.txt"
  {
    echo "migrations"
    echo "sqlite_sequence"
    echo "user"
    echo "tweet"
    echo "favorite"
    echo "report"
  } >"$tmp/expected.txt"
  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"
)

(

  printf "\n# SQL Error\n"
  migrations=$(mktemp -d)
  tmp=$(mktemp -d)
  db=$(mktemp)

  echo "CREATE TABLE user (id INTEGER)" >"$migrations/s1-user.sql"
  ./miglite.sh --db "$db" --migrations "$migrations"

  echo "random non sql string here" >"$migrations/s2-error.sql"
  echo "CREATE TABLE favorite (fav_id INTEGER)" >"$migrations/s3-favorite.sql"
  echo "CREATE TABLE report (rep_id INTEGER)" >"$migrations/s4-report.sql"

  exit_code=0
  ./miglite.sh --db "$db" --migrations "$migrations" >"$tmp/actual.txt" || exit_code=$?
  if [ "$exit_code" -ne 1 ]; then
    echo "Error: Expected exit code 1, got $exit_code"
    exit 1
  fi

  {
    echo "[CHECKSUM MATCH] s1-user.sql"
    echo "[SQL ERROR]      s2-error.sql"
  } >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"

  sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$tmp/actual.txt"

  {
    echo "migrations"
    echo "sqlite_sequence"
    echo "user"
  } >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"
)

(

  printf "\n# Checksum Error - Admin Table\n"
  migrations=$(mktemp -d)
  tmp=$(mktemp -d)
  db=$(mktemp)

  echo "CREATE TABLE user (id INTEGER)" >"$migrations/s1-user.sql"
  echo "CREATE TABLE tweet (tweet_id INTEGER)" >"$migrations/s2-tweet.sql"
  echo "CREATE TABLE favorite (fav_id INTEGER)" >"$migrations/s3-favorite.sql"

  ./miglite.sh --db "$db" --migrations "$migrations"

  echo "CREATE TABLE admin (adm_id INTEGER)" >"$migrations/s0-admin.sql"

  exit_code=0
  ./miglite.sh --db "$db" --migrations "$migrations" >"$tmp/actual.txt" || exit_code=$?
  if [ "$exit_code" -ne 1 ]; then
    echo "Error: Expected exit code 1, got $exit_code"
    exit 1
  fi

  echo "[CHECKSUM ERROR] s0-admin.sql" >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"

  sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$tmp/actual.txt"
  {
    echo "migrations"
    echo "sqlite_sequence"
    echo "user"
    echo "tweet"
    echo "favorite"
  } >"$tmp/expected.txt"
  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"
)

(

  printf "\n# Checksum Error - Favorite Table\n"
  migrations=$(mktemp -d)
  tmp=$(mktemp -d)
  db=$(mktemp)

  echo "CREATE TABLE user (id INTEGER)" >"$migrations/s1-user.sql"
  echo "CREATE TABLE tweet (tweet_id INTEGER)" >"$migrations/s2-tweet.sql"
  echo "CREATE TABLE report (rep_id INTEGER)" >"$migrations/s4-report.sql"

  ./miglite.sh --db "$db" --migrations "$migrations"

  echo "CREATE TABLE favorite (fav_id INTEGER)" >"$migrations/s3-favorite.sql"

  exit_code=0
  ./miglite.sh --db "$db" --migrations "$migrations" >"$tmp/actual.txt" || exit_code=$?
  if [ "$exit_code" -ne 1 ]; then
    echo "Error: Expected exit code 1, got $exit_code"
    exit 1
  fi

  {
    echo "[CHECKSUM MATCH] s1-user.sql"
    echo "[CHECKSUM MATCH] s2-tweet.sql"
    echo "[CHECKSUM ERROR] s3-favorite.sql"
  } >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"

  sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$tmp/actual.txt"
  {
    echo "migrations"
    echo "sqlite_sequence"
    echo "user"
    echo "tweet"
    echo "report"
  } >"$tmp/expected.txt"
  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"
)

(

  printf "\n# Missing Database File\n"
  migrations=$(mktemp -d)
  tmp=$(mktemp -d)

  echo "CREATE TABLE user (id INTEGER)" >"$migrations/s1-user.sql"
  echo "CREATE TABLE tweet (tweet_id INTEGER)" >"$migrations/s2-tweet.sql"

  exit_code=0
  ./miglite.sh --db ./db.sqlite --migrations "$migrations" >"$tmp/actual.txt" || exit_code=$?
  if [ "$exit_code" -ne 1 ]; then
    echo "Error: Expected exit code 1, got $exit_code"
    exit 1
  fi

  echo "Database file not found at ./db.sqlite" >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"
)

(

  printf "\n# Check Option\n"
  migrations=$(mktemp -d)
  tmp=$(mktemp -d)
  db=$(mktemp)

  echo "CREATE TABLE user (id INTEGER)" >"$migrations/s1-user.sql"
  ./miglite.sh --db "$db" --migrations "$migrations"

  echo "CREATE TABLE tweet (tweet_id INTEGER)" >"$migrations/s2-tweet.sql"
  echo "CREATE TABLE favorite (fav_id INTEGER)" >"$migrations/s3-favorite.sql"

  ./miglite.sh --db "$db" --migrations "$migrations" --check >"$tmp/actual.txt"

  {
    echo "[CHECKSUM MATCH] s1-user.sql"
    echo "[NOT APPLIED]    s2-tweet.sql"
    echo "[NOT APPLIED]    s3-favorite.sql"
  } >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"

  sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$tmp/actual.txt"

  {
    echo "migrations"
    echo "sqlite_sequence"
    echo "user"
  } >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"
)

(

  printf "\n# Remove Migration File\n"
  migrations=$(mktemp -d)
  tmp=$(mktemp -d)
  db=$(mktemp)

  echo "CREATE TABLE user (id INTEGER)" >"$migrations/s1-user.sql"
  echo "CREATE TABLE tweet (tweet_id INTEGER)" >"$migrations/s2-tweet.sql"
  echo "CREATE TABLE favorite (fav_id INTEGER)" >"$migrations/s3-favorite.sql"

  ./miglite.sh --db "$db" --migrations "$migrations"

  rm "$migrations/s3-favorite.sql"

  ./miglite.sh --db "$db" --migrations "$migrations" >"$tmp/actual.txt"

  {
    echo "[CHECKSUM MATCH] s1-user.sql"
    echo "[CHECKSUM MATCH] s2-tweet.sql"
  } >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"

  sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$tmp/actual.txt"
  {
    echo "migrations"
    echo "sqlite_sequence"
    echo "user"
    echo "tweet"
    echo "favorite"
  } >"$tmp/expected.txt"
  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"
)

(

  printf "\n# Remove Middle Migration File\n"
  migrations=$(mktemp -d)
  tmp=$(mktemp -d)
  db=$(mktemp)

  echo "CREATE TABLE user (id INTEGER)" >"$migrations/s1-user.sql"
  echo "CREATE TABLE tweet (tweet_id INTEGER)" >"$migrations/s2-tweet.sql"
  echo "CREATE TABLE favorite (fav_id INTEGER)" >"$migrations/s3-favorite.sql"

  ./miglite.sh --db "$db" --migrations "$migrations"

  rm "$migrations/s2-tweet.sql"

  exit_code=0
  ./miglite.sh --db "$db" --migrations "$migrations" >"$tmp/actual.txt" || exit_code=$?
  if [ "$exit_code" -ne 1 ]; then
    echo "Error: Expected exit code 1, got $exit_code"
    exit 1
  fi

  {
    echo "[CHECKSUM MATCH] s1-user.sql"
    echo "[CHECKSUM ERROR] s3-favorite.sql"
  } >"$tmp/expected.txt"

  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"

  sqlite3 "$db" "SELECT name FROM sqlite_master WHERE type='table';" >"$tmp/actual.txt"
  {
    echo "migrations"
    echo "sqlite_sequence"
    echo "user"
    echo "tweet"
    echo "favorite"
  } >"$tmp/expected.txt"
  diff --unified --color=always "$tmp/expected.txt" "$tmp/actual.txt"
)
