# Miglite

Miglite is a shell script for migrating SQLite databases.


todo
zig
foreign key
synchronization full
check final schema

## Dependencies

- GNU Coreutils
- sqlite3 CLI
- POSIX compliant shell

## Usage

```
./miglite.sh --db <db_file> --migrations <migrations_dir> [--check] [--up-to <migration>]
```

When executed, Miglite will apply all migration files in the specified directory in alphabetical
order.

Migration files that have already been applied will not be applied for a second time, but their
checksums will be verified to ensure they haven't changed.

When `--check` flag is used, Miglite will not run any migration, and will only check the checksums
of the already applied migrations.

When `--up-to` flag is used, Miglite will apply migrations or verify checksums only up to a specific
migration file.

## Examples

### Apply All Migrations

```bash
./miglite.sh --db ./my_database.db --migrations ./migrations
```

### Check Migrations Without Applying

```bash
./miglite.sh --db ./my_database.db --migrations ./migrations --check
```

### Apply Migrations Up To a Specific File

```bash
./miglite.sh --db ./my_database.db --migrations ./migrations --up-to 005_create_products.sql
```

## Output Messages

Each migration file will be prefixed with a status message indicating its state:

- `[CHECKSUM MATCH]`: Migration was previously applied and its checksum is valid
- `[CHECKSUM ERROR]`: Migration was previously applied but its checksum doesn't match
- `[NOT APPLIED]`: Migration hasn't been applied yet (only shown when `--check` is used)
- `[JUST APPLIED]`: Migration was successfully applied during this run
- `[SQL ERROR]`: Migration failed to apply due to SQL errors

## LICENCE

```
Zero-Clause BSD
=============

Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL
WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLEs
FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY
DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```
