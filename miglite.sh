set -eu

db_file=""
migrations_dir=""
check=false
upto=""

while [ $# -gt 0 ]; do
  case "$1" in
  --db)
    db_file=$2
    shift
    ;;
  --migrations)
    migrations_dir=$2
    shift
    ;;
  --check)
    check=true
    ;;
  --up-to)
    upto=$2
    shift
    ;;
  *)
    echo "Error: Unknown flag: $1" >&2
    exit 1
    ;;
  esac
  shift
done

if [ -z "$db_file" ] || [ -z "$migrations_dir" ]; then
  echo "Usage: migrate --db <db_file> --migrations <migrations_dir> [--check] [--up-to <migration>]" >&2
  exit 1
fi

if [ ! -f "$db_file" ]; then
  echo "Database file not found at $db_file"
  exit 1
fi

if [ -n "$upto" ] && [ ! -f "$migrations_dir/$upto" ]; then
  echo "Migration file $upto was used in --up-to but not found in $migrations_dir"
  exit 1
fi

sqlite3 "$db_file" <<EOF
CREATE TABLE IF NOT EXISTS migrations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  checksum TEXT NOT NULL
) STRICT;
EOF

id=0
file_checksum=""
migration_name=""

migration_files=$(find "$migrations_dir" -type f | sort)

for migration_file in $migration_files; do
  if [ -n "$upto" ] && [ "$migration_name" = "$upto" ]; then
    break
  fi

  id=$((id + 1))
  migration_name=$(basename "$migration_file")
  migration_content=$(cat "$migration_file")
  file_checksum=$(echo "$file_checksum$migration_content" | md5sum | cut -d' ' -f1)
  db_checksum=$(sqlite3 "$db_file" "SELECT checksum FROM migrations WHERE id = $id;")

  if [ -n "$db_checksum" ]; then

    if [ "$db_checksum" != "$file_checksum" ]; then
      echo "[CHECKSUM ERROR] $migration_name"
      echo "Migration ID      : $id"
      echo "Database checksum : $db_checksum"
      echo "File checksum     : $file_checksum"
      exit 1
    fi

    echo "[CHECKSUM MATCH] $migration_name"
    continue

  fi

  if [ "$check" = true ]; then
    echo "[NOT APPLIED]    $migration_name"
    continue
  fi

  if ! sqlite3 "$db_file" <"$migration_file"; then
    echo "[SQL ERROR]      $migration_name"
    exit 1
  fi

  echo "[JUST APPLIED]   $migration_name"
  sqlite3 "$db_file" "INSERT INTO migrations (checksum) VALUES ('$file_checksum');"

done
