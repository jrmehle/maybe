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

## Open items / TODO

- [ ] Confirm `git` is available inside the devcontainer's `Dockerfile` build (needed for
      `Maybe.commit_sha` in `config/initializers/version.rb` — this was an issue on the
      *production*-style image but hasn't been confirmed one way or the other for the
      devcontainer image).
- [ ] Decide whether to delete the root `docker-compose.yml` outright now that it's
      unused, or keep it as a reference/fallback.
- [ ] Document `.env` / credential setup once dependency-update pass begins, if any new
      env vars get introduced.
