# Local Development Guide

This fork uses the **`.devcontainer` Docker Compose stack** for all local development and
testing. It builds from source (unlike the root `docker-compose.yml`, which pulls the
published production image and is no longer used here).

## One-time setup

1. Make sure Docker is running.
2. From the project root, bring up the stack:

   ```bash
   bin/up
   ```

3. Confirm everything is running:

   ```bash
   docker compose -f .devcontainer/docker-compose.yml ps
   ```

   You should see `app`, `db`, `redis`, and `worker` all up.

## Helper scripts

All live in `bin/` and wrap the devcontainer compose file so you never have to type the
`-f .devcontainer/docker-compose.yml` flag by hand.

| Script | What it does |
|---|---|
| `bin/up` | Starts the full stack (`app`, `db`, `redis`, `worker`) in the background |
| `bin/down` | Stops the stack |
| `bin/dc` | Runs any command inside the running `app` container (`docker compose exec app "$@"`) |

> Note: `bin/dev` is reserved — it's the standard Rails/Foreman script (`Procfile.dev`) for
> running the app *without* Docker. We don't use it in this fork, but the filename is left
> alone to avoid confusion with upstream conventions. Our Docker-exec helper is `bin/dc`.

### `bin/up`
```bash
#!/usr/bin/env bash
docker compose -f .devcontainer/docker-compose.yml up -d app db redis worker
```

### `bin/down`
```bash
#!/usr/bin/env bash
docker compose -f .devcontainer/docker-compose.yml down
```

### `bin/dc`
```bash
#!/usr/bin/env bash
docker compose -f .devcontainer/docker-compose.yml exec app "$@"
```

All three need `chmod +x`.

## Day-to-day workflow

Start the stack once per session:

```bash
bin/up
```

Then run anything you need through `bin/dc`, from your normal host terminal (no need to
open a shell inside the container first):

```bash
bin/dc bin/rails test
bin/dc bin/rails test test/models/provider/plaid_test.rb
bin/dc bin/rails console
bin/dc bin/rails db:migrate
bin/dc bundle exec rake some:task
bin/dc bash          # drop into an interactive shell if you want one
```

Edit code as normal on your host in Sublime Text (or whatever editor) — the project
directory is bind-mounted into the `app` container at `/workspace`, so changes are
reflected immediately with no rebuild needed.

Shut down when you're done:

```bash
bin/down
```

## Changes made to `.devcontainer/docker-compose.yml`

The stock devcontainer compose file (as shipped upstream, oriented around VS Code) needed
a few adjustments to work as a standalone local dev environment run entirely from the
terminal:

1. **`app` service now runs the Rails server**, instead of idling:
   ```yaml
   command: bin/rails server -b 0.0.0.0 -p 3000   # was: sleep infinity
   ```

2. **`worker` service got the missing volume mounts** — without these it had no access to
   the source code or gems and failed immediately with "Could not locate Gemfile":
   ```yaml
   worker:
     volumes:
       - ..:/workspace:cached
       - bundle_cache:/bundle
     working_dir: /workspace
   ```

3. **Root `docker-compose.yml` is no longer used** for local dev. It remains in the repo
   (unedited) as the reference production/self-hosting config, but day-to-day work happens
   entirely through the devcontainer stack.

## Test environment notes

- Tests run inside the `app` container against the `db`/`redis` services defined in the
  devcontainer stack — no separate test-specific containers needed.
- **Plaid integration tests are skipped by default.** `PLAID_CLIENT_ID`/`PLAID_SECRET` are
  not set in the devcontainer environment, so `Rails.application.config.plaid` is `nil`.
  `test/models/provider/plaid_test.rb` has a guard to skip cleanly in this case:
  ```ruby
  skip "Plaid credentials not configured" if Rails.application.config.plaid.nil?
  ```
  If you want to exercise real Plaid sandbox behavior, get free sandbox credentials from
  Plaid and add `PLAID_CLIENT_ID` / `PLAID_SECRET` / `PLAID_ENV=sandbox` to the `x-rails-env`
  block in `.devcontainer/docker-compose.yml`.
- `PlaidItem#remove_plaid_item` is guarded to no-op when Plaid isn't configured, so the
  family-data-reset flow doesn't blow up for anyone running without Plaid.

## Known-good baseline

As of the last full run: **0 failures, 0 errors, 9 skips** (902 runs total). The 9 skips
are the Plaid sandbox tests described above — expected and fine without credentials
configured.

## Restoring a local backup

For vetting changes against real data, you can restore a gzipped `pg_dump` backup into the
devcontainer's `db` service.

Drop your backup file into the project's `tmp/` folder on the host. The restore commands
below run `gunzip` on the **host** and pipe the output into `docker compose exec -T db`
(the `-T` flag allows stdin to pass through into the exec'd process) — this runs directly
against the `db` service rather than going through `app`, since `psql`/`pg_restore` need to
run somewhere they're actually installed (the `db` container, built from the official
`postgres` image, has them; `app` isn't guaranteed to), and `db` doesn't have the workspace
mounted so it can't read `tmp/` on its own.

**Important — target the actual Rails-configured database, not the Postgres default.**
`POSTGRES_DB: postgres` in the devcontainer's `x-db-env` block only sets the name of the
*default/superuser* database that exists when the Postgres container first boots. It is
**not** the database Rails actually connects to. The app's real database name comes from
`config/database.yml` and is `maybe_development` in this fork. Restoring into `postgres`
will silently succeed but leave `maybe_development` empty — which is why the app still
shows the first-time setup prompt even after a "successful" restore.

Confirm the real name any time with:

```bash
bin/dc bin/rails runner 'puts ActiveRecord::Base.connection_db_config.database'
```

Steps:

1. **Drop and recreate the dev database** so you're restoring into a clean slate — Rails'
   own db tasks run through `app` (that's where Rails lives) and stay in sync with
   `database.yml` automatically:

   ```bash
   bin/dc bin/rails db:drop db:create
   ```

2. **Unzip and restore**, run from the host, targeting `db` directly:

   ```bash
   gunzip -c tmp/backup.sql.gz | docker compose -f .devcontainer/docker-compose.yml exec -T -e PGPASSWORD=postgres db psql -U postgres -d maybe_development
   ```

3. **Run any pending migrations** in case the backup predates code changes in your fork:

   ```bash
   bin/dc bin/rails db:migrate
   ```

> **If your backup script ever switches to custom-format dumps** (`pg_dump -Fc`, a binary
> file rather than plain SQL), step 2 changes to `pg_restore` instead of `psql`:
> ```bash
> gunzip -c tmp/backup.dump.gz | docker compose -f .devcontainer/docker-compose.yml exec -T -e PGPASSWORD=postgres db pg_restore -U postgres -d maybe_development --clean --if-exists
> ```
> You can tell which format you have by running `file` on the uncompressed dump — plain text
> is a SQL dump, binary is custom format.

### `bin/restore_db` script

Rather than typing these by hand each time, `bin/restore_db` automates it — using
`rails db:drop db:create` through `app`, and piping the unzip through the host into `db`
via `exec -T`:

```bash
#!/usr/bin/env bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: bin/restore_db path/to/backup.sql.gz"
  echo "  (path should be relative to the project root, e.g. tmp/backup.sql.gz)"
  exit 1
fi

BACKUP_FILE="$1"
COMPOSE_FILE=".devcontainer/docker-compose.yml"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "File not found: $BACKUP_FILE"
  exit 1
fi

echo "Dropping and recreating the database via Rails..."
bin/dc bin/rails db:drop db:create

echo "Determining target database name from Rails config..."
DB_NAME=$(bin/dc bin/rails runner 'puts ActiveRecord::Base.connection_db_config.database' | tail -n 1)

echo "Restoring into database: $DB_NAME"
gunzip -c "$BACKUP_FILE" | docker compose -f "$COMPOSE_FILE" exec -T -e PGPASSWORD=postgres db psql -U postgres -d "$DB_NAME"

echo "Running migrations..."
bin/dc bin/rails db:migrate

echo "Done. Restored into '$DB_NAME' from $BACKUP_FILE"
```

```bash
chmod +x bin/restore_db
```

Usage:

```bash
bin/restore_db tmp/backup.sql.gz
```

Restoring real production data locally means the database now contains real user data — treat it
with the same care you would in production (don't commit it, don't leave it running longer
than needed for the task, wipe it via `bin/down` + volume removal when done if that matters
to you).

## Open items / TODO

- [ ] Confirm `git` is available inside the devcontainer's `Dockerfile` build (needed for
      `Maybe.commit_sha` in `config/initializers/version.rb` — this was an issue on the
      *production*-style image but hasn't been confirmed one way or the other for the
      devcontainer image).
- [ ] Decide whether to delete the root `docker-compose.yml` outright now that it's
      unused, or keep it as a reference/fallback.
- [ ] Document `.env` / credential setup once dependency-update pass begins, if any new
      env vars get introduced.
