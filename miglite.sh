db_file=""
migrations_dir=""
validate_only=false

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
  --validate-only)
    validate_only=true
    ;;
  *)
    echo "Error: Unknown flag: $1" >&2
    exit 1
    ;;
  esac
  shift
done

if [ -z "$db_file" ] || [ -z "$migrations_dir" ]; then
  echo "Usage: migrate --db <db_file> --migrations <migrations_dir> [--validate-only]"
  exit 1
fi

if [ ! -f "$db_file" ]; then
  echo "Database file not found at $db_file"
  exit 1
fi

sqlite3 "$db_file" <<EOF
CREATE TABLE IF NOT EXISTS migrations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  checksum TEXT NOT NULL
);
EOF

id=0
file_checksum=$(echo | md5sum | awk '{print $1}')

migrations=$(find "$migrations_dir" -type f | sort)

for migration in $migrations; do
  id=$((id + 1))
  migration_name=$(basename "$migration")
  file_content=$(cat "$migration")
  file_checksum=$(echo "$file_checksum $file_content" | md5sum | awk '{print $1}')
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

  if [ "$validate_only" = true ]; then
    echo "[NOT APPLIED]    $migration_name"
    continue
  fi

  if ! sqlite3 "$db_file" <"$migration"; then
    echo "[SQL ERROR]      $migration_name"
    exit 1
  fi

  echo "[JUST APPLIED]   $migration_name"
  sqlite3 "$db_file" "INSERT INTO migrations (checksum) VALUES ('$file_checksum');"

done
