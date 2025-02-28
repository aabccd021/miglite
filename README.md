# Miglite

A POSIX compliant shell script for migrating SQLite databases.

## Overview

This migration script allows you to:

- Apply SQL migration files to a SQLite database in sequential order
- Track applied migrations with checksums to detect changes
- Validate migration files against the database state
- Run migrations up to a specific file

## Usage

```
./migrate --db <db_file> --migrations <migrations_dir> [--check] [--up-to <migration>]
```

### Required Parameters

- `--db <db_file>`: Path to the SQLite database file
- `--migrations <migrations_dir>`: Directory containing migration files

### Optional Parameters

- `--check`: Validate migration files against the database. New migrations will not be applied.
- `--up-to <migration>`: Apply/validate migrations up to and including the specified file

## Examples

### Apply All Migrations

```bash
./migrate --db ./my_database.db --migrations ./migrations
```

### Check Migrations Without Applying

```bash
./migrate --db ./my_database.db --migrations ./migrations --check
```

### Apply Migrations Up To a Specific File

```bash
./migrate --db ./my_database.db --migrations ./migrations --up-to 005_create_products.sql
```

## How It Works

### Migration Files

Migration files should be SQL files placed in the migrations directory.
They will be executed in alphabetical order sorted by `sort` command.
So prefixing them with numbers like `001_create_users.sql`, `002_add_email_column.sql`, etc. is recommended.

### Migration Tracking

The script creates a `migrations` table in your database to track applied migrations:

Each applied migration gets an entry with:

- An auto-incremented ID
- A checksum calculated from all migrations up to that point

### Checksum Validation

When running the script on a database with existing migrations,
it validates the checksums of applied migrations against the current migration files.

The script stores the checksum of each migration file in the `migrations` table.

```sql
CREATE TABLE IF NOT EXISTS migrations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  checksum TEXT NOT NULL
);
```

This prevents changes to migration files after they've been applied.

## Output Messages

The script provides the following status messages for each migration file:

- `[CHECKSUM MATCH]`: Migration was previously applied and its checksum is valid
- `[CHECKSUM ERROR]`: Migration was previously applied but its checksum doesn't match
- `[NOT APPLIED]`: Migration hasn't been applied yet (only shown when `--check` is used)
- `[JUST APPLIED]`: Migration was successfully applied during this run
- `[SQL ERROR]`: Migration failed to apply due to SQL errors

## Usage with Nix Flakes

### Run directly

```sh
nix run github:aabccd021/miglite -- --db ./my_database.db --migrations ./migrations
```

### Use as package

```nix
{
  inputs.miglite.url = "github:aabccd021/miglite";
  outputs = { self, miglite }: {
    packages.x86_64-linux.miglite = miglite.packages.x86_64-linux.miglite;
  };
}
```

### Use with overlays

```nix
{
  inputs.miglite.url = "github:aabccd021/miglite";
  outputs = { self, nixpkgs, miglite }:
  let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ miglite.overlays.default ];
    };
  in
  {
    packages.x86_64-linux.miglite = pkgs.miglite;
  };
}
```
