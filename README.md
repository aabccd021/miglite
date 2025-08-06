# Miglite

Shell script for migrating SQLite databases.

## TODO

- upto test
- change license

## Usage

```
miglite --db <db_file> --migrations <migrations_dir> [--check] [--up-to <migration>]
```

## Examples

### Apply All Migrations

```bash
miglite --db ./my_database.db --migrations ./migrations
```

### Check Migrations Without Applying

```bash
miglite --db ./my_database.db --migrations ./migrations --check
```

### Apply Migrations Up To a Specific File

```bash
miglite --db ./my_database.db --migrations ./migrations --up-to 005_create_products.sql
```

## Output Messages

The script provides the following status messages for each migration file:

- `[CHECKSUM MATCH]`: Migration was previously applied and its checksum is valid
- `[CHECKSUM ERROR]`: Migration was previously applied but its checksum doesn't match
- `[NOT APPLIED]`: Migration hasn't been applied yet (only shown when `--check` is used)
- `[JUST APPLIED]`: Migration was successfully applied during this run
- `[SQL ERROR]`: Migration failed to apply due to SQL errors
