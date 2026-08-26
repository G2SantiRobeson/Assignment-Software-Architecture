# Book Reviews

This repository contains the coded portion of a server-rendered book-review assignment. It provides CRUD pages for authors, books, reviews, and yearly sales; database-backed reports; summary search; and a reproducible seed-data pipeline. This README and the files under `docs/` are technical implementation records, not the students' final report.

## Required software

- Ruby 3.3.8 (pinned by `.ruby-version`)
- Bundler 2.5.22 (the version recorded in `Gemfile.lock`)
- Rails 8.0.5.1 (locked in `Gemfile` and `Gemfile.lock`)
- PostgreSQL 16

Docker Desktop with Docker Compose can provide Ruby and PostgreSQL instead of a native installation. The development container uses `ruby:3.3.8-bookworm`; Compose uses `postgres:16-alpine`.

## Native setup

Install and start PostgreSQL 16, then make a PostgreSQL role available to the application. Configure the connection in the current shell. For example, in PowerShell:

```powershell
$env:DB_HOST = "localhost"
$env:DB_PORT = "5432"
$env:DB_USERNAME = "postgres"
$env:DB_PASSWORD = "your-local-password"
```

On a POSIX shell, set the same variables with `export`. Then install dependencies and prepare the databases:

```text
gem install bundler -v 2.5.22
bundle install
bundle exec rails db:create
bundle exec rails db:migrate
```

`bundle exec rails db:prepare` may be used in place of the separate database creation and migration commands. The configured database names are `book_reviews_development` and `book_reviews_test`.

Populate development data if required:

```text
bundle exec rails db:seed
```

Start the application at [http://localhost:3000](http://localhost:3000):

```text
bundle exec rails server
```

On systems that execute repository binstubs directly, the equivalent forms are `bin/rails db:prepare`, `bin/rails db:seed`, `bin/rails test`, and `bin/rails server`. `bin/setup --skip-server` is also supported for dependency installation, database preparation, and temporary-file cleanup.

## Docker setup

Copy the environment template, replace its example password, and start the complete system from the repository root. Ruby gems are installed in the built `web` image, so rebuild after changing `Gemfile` or `Gemfile.lock`.

```powershell
Copy-Item .env.example .env
# Edit .env and replace POSTGRES_PASSWORD.
docker compose up --build -d
docker compose ps
docker compose logs web db migrate
```

On POSIX systems, use `cp .env.example .env`. A one-shot `migrate` service waits for PostgreSQL and runs `bin/rails db:prepare` before Rails starts, avoiding concurrent migrations when the web service is scaled. The application is published at [http://localhost:3000](http://localhost:3000); `/up` is its health endpoint. The first database preparation also loads the seed dataset and may take longer because the importer attempts to contact Open Library.

Stop the services with `docker compose down`. The Compose project owns a named `postgres_data` volume, physically mounted at `/var/lib/postgresql/data` in the database container. `docker compose down` preserves it; do not add `--volumes` unless deleting the database is intentional. To verify persistence, create a recognizable row, run `docker compose down`, start the system again, and query the same row.

To prepare the Docker test database and run the suite:

```text
docker compose run --rm -e RAILS_ENV=test web bin/rails db:prepare
docker compose run --rm -e RAILS_ENV=test web bin/rails test
```

## HashiCorp Nomad deployment

The `nomad/` directory is the Group 7 orchestrator deliverable. It uses a single native Linux Nomad server/client, Nomad-native service registration, Docker tasks, Nomad Variables for secrets, and a Docker named volume for the local PostgreSQL workload. No Consul, Vault, or Kubernetes installation is required. This setup is intentionally for a one-node academic environment: the Docker volume is node-local and must be replaced by CSI/shared storage before adding Nomad client nodes.

Prerequisites are a native Linux host, Linux VM, or WSL2 distribution with its own Linux Docker Engine, Nomad 1.11.x, `curl`, and enough permission for the Nomad client and `/opt/nomad/data`. A Windows Nomad client cannot launch Linux Docker images, and running a Nomad client inside Docker is not a supported deployment. Stop any local service already using TCP port 5432, including this repository's Compose stack.

Start the agent in its own terminal from the repository root:

```bash
sudo nomad agent -config=nomad/agent.hcl
```

In another terminal, verify that the node is ready and that the Docker driver is healthy:

```bash
export NOMAD_ADDR=http://127.0.0.1:4646
nomad version
nomad node status -verbose
```

Build the immutable Rails production image, generate runtime secrets, and store them in job-scoped Nomad Variables. The same generated values must be used in the commands below; they are never written to the repository or image.

```bash
docker build -t book-reviews:nomad .
export BOOK_REVIEWS_DB_PASSWORD="$(openssl rand -base64 32)"
export BOOK_REVIEWS_SECRET_KEY_BASE="$(openssl rand -hex 64)"
nomad var put nomad/jobs/book-reviews-postgres postgres_password="$BOOK_REVIEWS_DB_PASSWORD"
nomad var put nomad/jobs/book-reviews-migrate database_password="$BOOK_REVIEWS_DB_PASSWORD" secret_key_base="$BOOK_REVIEWS_SECRET_KEY_BASE"
nomad var put nomad/jobs/book-reviews-web database_password="$BOOK_REVIEWS_DB_PASSWORD" secret_key_base="$BOOK_REVIEWS_SECRET_KEY_BASE"
```

Validate, plan, and deploy in dependency order. The batch migration must complete before the web job is submitted.

```bash
nomad job validate nomad/postgres.nomad.hcl
nomad job validate nomad/migrate.nomad.hcl
nomad job validate nomad/web.nomad.hcl
nomad job plan nomad/postgres.nomad.hcl
nomad job run nomad/postgres.nomad.hcl
nomad job status book-reviews-postgres
nomad job run nomad/migrate.nomad.hcl
nomad job status book-reviews-migrate
nomad job run nomad/web.nomad.hcl
nomad job status book-reviews-web
nomad service info book-reviews-web
```

`nomad service info` reports the allocated host address and dynamic port. Verify the exact reported endpoint with `curl http://<address>:<port>/up` and open `http://<address>:<port>/`. In WSL2, use the reported WSL address from Windows rather than assuming that its dynamic port is forwarded to `127.0.0.1`. The Nomad UI is available inside the Linux environment at [http://127.0.0.1:4646](http://127.0.0.1:4646).

To test web self-healing, copy the running web allocation ID from `nomad job status book-reviews-web`, confirm the installed syntax with `nomad alloc stop -help`, and run `nomad alloc stop <web-allocation-id>`. A subsequent job status must show a healthy replacement allocation, and the replacement address returned by `nomad service info book-reviews-web` must answer `/up`.

To test PostgreSQL persistence, create a recognizable record with `nomad alloc exec -task postgres <database-allocation-id> psql -U book_reviews -d book_reviews_production`, stop that allocation with `nomad alloc stop <database-allocation-id>`, wait for its replacement, and query the record through the replacement allocation. Do not remove the `book_reviews_nomad_postgres_data` Docker volume during this test.

The web group uses a dynamic host port and may be scaled without a manifest redesign:

```bash
nomad job scale book-reviews-web 2
nomad job status book-reviews-web
nomad service info book-reviews-web
```

All Rails allocations share PostgreSQL and the same cookie-signing secret. This application has no uploaded-file subsystem; its in-process cache and Active Job queue are ephemeral, so a future feature that relies on cross-instance cache consistency or durable background jobs should use a shared service such as Redis or a database-backed queue.

Stop and purge the jobs when finished. This does not delete the PostgreSQL Docker volume.

```bash
nomad job stop -purge book-reviews-web
nomad job stop -purge book-reviews-migrate
nomad job stop -purge book-reviews-postgres
```

Removing `book_reviews_nomad_postgres_data` with `docker volume rm` is a separate, destructive database reset. The committed `agent.hcl` has no ACL or transport-security configuration and must not be treated as an Internet-facing production Nomad cluster.

## Database configuration

`config/database.yml` uses the PostgreSQL adapter and accepts the following environment variables:

| Variable | Purpose | Default/behavior |
| --- | --- | --- |
| `DB_HOST` | PostgreSQL host | Unset for the native libpq default; `db` in Compose; rendered from Nomad native service discovery in Nomad |
| `DB_PORT` | PostgreSQL port | `5432` |
| `DB_NAME` | Environment database | Rails environment default; follows `POSTGRES_DB` in Compose |
| `TEST_DB_NAME` | Test database | `book_reviews_test` |
| `DB_USERNAME` | PostgreSQL role | Unset for the native libpq default; `book_reviews` in container deployments |
| `DB_PASSWORD` | PostgreSQL password | Required from `.env` in Compose or a Nomad Variable in Nomad |
| `DATABASE_URL` | Standard Rails connection URL | If set, Rails merges it over `database.yml` |
| `RAILS_MAX_THREADS` | Active Record connection-pool size | `5` |
| `APP_DATABASE_PASSWORD` | Alternate production password | Used only when `DB_PASSWORD` is absent |

Do not commit real database credentials. `.env` and local Nomad variable files are ignored; `.env.example` contains placeholders only.

## Open Library seed/import behavior

`db/seeds.rb` asks `OpenLibraryImporter` for real author and book metadata before `AssignmentDatasetBuilder` persists anything. The importer uses Open Library's `/search.json` endpoint with a selected field list for discovery and batched book retrieval, then performs at most one cached `/authors/{id}.json` detail lookup per selected author. Stable author and work keys are normalized and deduplicated in memory and are protected by unique PostgreSQL indexes when present. A usable `first_publish_year` is stored consistently as January 1 of that year. A missing, invalid, or impossibly late year that cannot accommodate the configured forward sale-year range receives the explicit synthetic publication-date fallback. Requests are rate-limited to one per second by default, or three per second when a custom contact email/User-Agent identifies the client; the interval is configurable.

A fresh real-data import requires outbound HTTPS access to `openlibrary.org`. Open Library is not contacted during normal application requests. If it is disabled, unavailable, times out, returns malformed data, or supplies too few usable records, the builder logs warnings and creates only the missing authors/books locally. Missing birth dates, origins, biographies, summaries, and publication dates receive explicit synthetic fallbacks. Reviews and yearly sales are always generated locally with a deterministic random seed.

The seed command enforces at least 50 authors, 300 books, 1–10 reviews per book, and at least five distinct sale years per book. It finishes by verifying these cardinalities, constraints, searchable summaries, and cached sales totals; verification failure raises an error.

Important: `db:seed` is deliberately reset-based. It fetches external data first, then deletes and rebuilds all `Sale`, `Review`, `Book`, and `Author` rows inside one transaction. A database error rolls the rebuild back, and reruns do not accumulate duplicate generated records. This makes the operation repeatable for an assignment dataset, but it is destructive to manually entered records. The fallback portion is deterministic for a fixed random seed; live Open Library results can change upstream.

### Seed environment variables

| Variable | Default | Behavior |
| --- | --- | --- |
| `OPEN_LIBRARY_ENABLED` | `true` | Set to `false`, `0`, `no`, or `off` for a fully local fallback seed |
| `OPEN_LIBRARY_BASE_URL` | `https://openlibrary.org` | HTTP(S) API base URL |
| `OPEN_LIBRARY_CONTACT_EMAIL` | unset | Included in the default identifying User-Agent when supplied |
| `OPEN_LIBRARY_USER_AGENT` | generated identifier | Overrides the complete Open Library User-Agent |
| `OPEN_LIBRARY_OPEN_TIMEOUT` | `5` seconds | Connection timeout |
| `OPEN_LIBRARY_READ_TIMEOUT` | `10` seconds | Response-read timeout |
| `OPEN_LIBRARY_RETRIES` | `2` | Retry setting, clamped to `0..4`, for transient network/HTTP failures |
| `OPEN_LIBRARY_REQUEST_INTERVAL` | `1` second, or `1/3` second with custom identification | Minimum seconds between requests; non-negative values override the usage-policy default |
| `SEED_AUTHOR_COUNT` | `50` | Requested author target; values below 50 are raised to 50 |
| `SEED_BOOK_COUNT` | `300` | Requested book target; values below 300 are raised to 300 |
| `SEED_SALES_YEARS` | `5` | Forward sale years per book; values below 5 are raised to 5 and values above 9,999 are rejected |
| `SEED_RANDOM_SEED` | `20260812` | Deterministic review and sales generation seed |

For a reliable offline seed:

```powershell
$env:OPEN_LIBRARY_ENABLED = "false"
bundle exec rails db:seed
```

Use `OPEN_LIBRARY_ENABLED=false bundle exec rails db:seed` in a POSIX shell.

## Tests and quality checks

Prepare the test database once after schema changes, then run Minitest:

```text
RAILS_ENV=test bundle exec rails db:prepare
bundle exec rails test
```

In PowerShell, set `$env:RAILS_ENV = "test"` for the preparation command, then remove or reset it before running the development server. Rails also provides the configured checks:

```text
bundle exec rubocop
bundle exec brakeman
```

## Main pages

| Page | Route |
| --- | --- |
| Book list / home | `/` or `/books` |
| Author CRUD | `/authors` (with `/new`, `/:id`, and `/:id/edit`) |
| Book CRUD | `/books` (with `/new`, `/:id`, and `/:id/edit`) |
| Review CRUD | `/reviews` (with `/new`, `/:id`, and `/:id/edit`) |
| Yearly sale CRUD | `/sales` (with `/new`, `/:id`, and `/:id/edit`) |
| Author statistics | `/reports/author-statistics` |
| Top 10 rated books | `/reports/top-rated-books` |
| Top 50 selling books | `/reports/top-selling-books` |
| Book summary search | `/book-search?q=search+terms` |
| Health check | `/up` |

All CRUD resources use standard Rails REST actions for `index`, `show`, `new`, `create`, `edit`, `update`, and `destroy`. Search uses case-insensitive ANY-word matching, returns 20 records per page, and preserves the normalized `q` in pagination links. To bound public-request complexity, search accepts at most 500 normalized characters and 50 distinct tokens per request; the form and page links show exactly the accepted query.

## Technical records

- `docs/architecture_decisions.md` records implementation decisions and trade-offs.
- `docs/development_log.md` records objective commands, errors, fixes, and verification facts.
- `docs/nomad_verification.md` records the live Nomad deployment, recovery, persistence, and scaling evidence.
