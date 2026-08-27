# Book Reviews

This repository contains the coded portion of a server-rendered book-review assignment. It provides CRUD pages for authors, books, reviews, and yearly sales; database-backed reports; summary search; and a reproducible seed-data pipeline. This README and the files under `docs/` are technical implementation records, not the students' final report.

The complete container-orchestration guide for the second delivery is in [`README_DELIVERY_2.md`](README_DELIVERY_2.md). It covers Docker Compose, the local Kubernetes deployment, persistent state, scaling, and the required verification procedures.

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

Copy the example environment file once and replace its development-only password. The resulting `.env` is ignored by Git and is read automatically by Docker Compose:

```powershell
Copy-Item .env.example .env
notepad .env
```

Ruby gems are installed in the built `web` image, so rebuild it after changing `Gemfile` or `Gemfile.lock`. From the repository root, the complete system starts with one command:

```text
docker compose up --build -d
```

This starts PostgreSQL and Rails and publishes Rails on [http://localhost:3000](http://localhost:3000). The development entrypoint removes a stale Puma PID and runs `db:prepare`, so new databases and pending migrations are handled automatically. Run `docker compose exec web bin/rails db:seed` only when the assignment dataset must be recreated; the seed intentionally replaces existing domain records. Stop the services with `docker compose down`. The named `postgres_data` volume preserves database data; do not add `--volumes` unless deleting that data is intended.

To prepare the Docker test database and run the suite:

```text
docker compose run --rm -e RAILS_ENV=test web bin/rails db:prepare
docker compose run --rm -e RAILS_ENV=test web bin/rails test
```

## Database configuration

`config/database.yml` uses the PostgreSQL adapter and accepts the following environment variables:

| Variable | Purpose | Default/behavior |
| --- | --- | --- |
| `DB_HOST` | PostgreSQL host | Unset for the native libpq default; `db` in Compose |
| `DB_PORT` | PostgreSQL port | `5432` |
| `DB_USERNAME` | PostgreSQL role | Unset for the native libpq default; required in Compose `.env` |
| `DB_PASSWORD` | PostgreSQL password | Unset natively; required in Compose `.env` |
| `DATABASE_URL` | Standard Rails connection URL | If set, Rails merges it over `database.yml` |
| `RAILS_MAX_THREADS` | Active Record connection-pool size | `5` |
| `APP_DATABASE_PASSWORD` | Alternate production password | Used only when `DB_PASSWORD` is absent |

Do not commit real database credentials. Compose reads them from the ignored `.env`; `.env.example` contains placeholders only.

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
