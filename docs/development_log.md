# Development Log

This file records objective implementation and verification facts for the coded portion of the assignment. It does not record time spent, student experience, group opinion, or material for the student-authored final report.

## Initial repository audit

- The repository started on a clean branch with one initial commit and only a placeholder `README.md`; no Rails application, Gemfile, domain code, migrations, or tests were present.
- The host shell did not provide `ruby`, `rails`, `bundle`, or `psql` on `PATH`.
- Docker was therefore used to bootstrap and verify the assigned Ruby/Rails/PostgreSQL stack.

## Rails bootstrap and environment errors

1. `docker pull ruby:3.3.8-slim-bookworm` completed and provided the required Ruby version.
2. A Rails 8.0.2 gem-install attempt in that slim image reached the native `websocket-driver` build and failed with `make failed: No such file or directory`. The image did not include the compiler toolchain needed by that dependency.
3. A retry that attempted to install `build-essential` in the slim container timed out before it made repository changes.
4. `docker pull ruby:3.3.8-bookworm` supplied the full Ruby image with the required native build tooling. `Dockerfile.dev` consequently uses `ruby:3.3.8-bookworm` rather than the slim development image.
5. A combined gem-install/generator container command reported a successful Rails installation and then `rails: not found`. Inspection in a subsequent container found the executable at `/usr/local/bundle/bin/rails`. Invoking that executable directly allowed the Rails generator to run.
6. The Rails application was generated conventionally with PostgreSQL selected. The generated production image remains multi-stage and installs build dependencies only in its build stage.
7. Dependency resolution with `bundle install` produced the committed lockfile with Ruby-facing Rails dependencies at exactly Rails 8.0.5.1, `pg` 1.6.3, and Bundler 2.5.22.

The missing `make` error and executable-lookup error occurred during isolated bootstrap containers; neither was hidden by removing a dependency. Moving development generation/build work to the full Ruby image and addressing the executable path resolved the actual causes.

## PostgreSQL and Rails configuration

- `.ruby-version` pins Ruby 3.3.8.
- `Gemfile` pins Rails 8.0.5.1 and uses the `pg` adapter.
- `config/database.yml` defines PostgreSQL databases `book_reviews_development` and `book_reviews_test` and accepts `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`, `DATABASE_URL`, and `RAILS_MAX_THREADS`.
- `compose.yaml` pins PostgreSQL 16 Alpine, includes a `pg_isready` health check, persists PostgreSQL in a named volume, and passes the database hostname/credentials to Rails.
- `Dockerfile.dev` pins `ruby:3.3.8-bookworm`, installs the PostgreSQL client, installs the locked bundle, and starts Rails on all container interfaces.
- The Rails `db:create` and `db:migrate` tasks completed successfully against PostgreSQL. The migration created the four domain tables, foreign keys, relationship indexes, unique Open Library key indexes, the unique `(book_id, year)` index, non-null rules, defaults, and named check constraints. `db/schema.rb` was generated from the migrated PostgreSQL database.

## Domain and CRUD implementation facts

- `Author`, `Book`, `Review`, and `Sale` use Active Record associations and validations matching the domain.
- Parent deletion uses `dependent: :restrict_with_error` for `Author -> Book` and `Book -> Review/Sale`; the implementation does not silently cascade-delete the domain graph.
- The yearly `Sale` model refreshes the affected books' cached lifetime sales after create, update, reassignment, and destroy. Book rows are locked and refreshed in stable ID order. Seed bulk inserts perform the refresh explicitly because `insert_all!` skips callbacks.
- Standard RESTful resources expose all seven CRUD actions for authors, books, reviews, and sales. Forms select the required associated author/book and render shared validation errors.
- CRUD list/show controllers use eager loading or already-loaded associations where related names/records are rendered.

## Open Library and seed implementation facts

- `OpenLibraryImporter` uses standard-library `Net::HTTP` and JSON parsing. It calls `/search.json` for discovery and batched work searches and `/authors/{id}.json` for author details.
- Discovery uses multiple English-language subject queries. Work searches batch up to ten selected author keys, request at most 100 documents per page, and cap each author batch at five pages.
- Requests send an identifying User-Agent, apply open/read timeouts, and retry bounded transient network failures and HTTP `429`, `500`, `502`, `503`, and `504` responses. Consecutive requests are throttled to one per second by default, or three per second when a custom contact email/User-Agent is configured; `OPEN_LIBRARY_REQUEST_INTERVAL` can override the minimum interval.
- The importer validates JSON shape, normalizes author/work keys, dates, and text, deduplicates records, and caches author-detail responses. It returns normalized data and warnings but performs no database writes.
- `AssignmentDatasetBuilder` persists usable Open Library authors/books first, supplies explicit synthetic values for missing required metadata, creates only the remaining author/book deficit locally, and generates all reviews and yearly sales locally.
- Each build is a transactional reset: existing sales, reviews, books, and authors are deleted and rebuilt in dependency order within one transaction. Repeated builds do not accumulate generated rows; a failed database rebuild rolls back.
- `SeedDataVerifier` queries the completed database for cardinalities, author presence, the 1–10 review range, distinct sale years, duplicate annual sales, invalid values, pre-publication sales, searchable summaries, and mismatches between yearly sums and cached book totals. It raises instead of reporting an incomplete seed as successful.

### Executed live seed

Command:

```text
bundle exec rails db:seed
```

Network access to Open Library was available. The command completed with these reported counts:

| Metric | Result |
| --- | ---: |
| Open Library authors | 50 |
| Open Library books | 300 |
| Fallback authors | 0 |
| Fallback books | 0 |
| Total authors | 50 |
| Total books | 300 |
| Total reviews | 1,609 |
| Total yearly sales | 1,500 |
| Reviews per book | 1..10 |
| Minimum distinct sale years per book | 5 |

### Executed offline-fallback seed

The seed was also run with `OPEN_LIBRARY_ENABLED=false`. It completed without network access and reported 0 Open Library authors/books, 50 fallback authors, 300 fallback books, 1,609 reviews, 1,500 yearly sales, a 1..10 review range, and at least five distinct sale years per book. This verified that a fresh assignment dataset does not depend on external availability.

## Report and search implementation facts

- Complex SQL is contained in `app/queries`; controllers coordinate HTTP input and ERB views render query results.
- Author statistics uses independent author-level subqueries for book count, review average, and sales sum, then left-joins them to authors. This prevents review-by-sale row multiplication and retains authors with no related records.
- Author-statistics sorting maps external values to four fixed SQL expressions and validates direction. Author text uses escaped parameterized `ILIKE`; numeric minimum/maximum filters are parsed before parameterized predicates are added.
- Top-rated books aggregates reviews and uses `ROW_NUMBER()` per book for deterministic highest/lowest review selection. Final order is average descending, review count descending, case-insensitive book name ascending, and book ID ascending.
- Top-selling books independently aggregates book and author totals. A separate annual relation uses `ROW_NUMBER()` partitioned by year with sales descending, then case-insensitive book name and ID tie-breakers. It is joined to each book only for the year extracted from that book's publication date.
- Summary search tokenizes whitespace, removes empty/case-insensitive duplicate tokens, escapes PostgreSQL wildcard characters, combines parameterized `ILIKE` predicates with OR, preloads authors, and orders deterministically.
- Search pagination is implemented with `COUNT`, `LIMIT`, and `OFFSET`, defaults to 20 records, caps the query object's page size at 100, normalizes page values, and preserves `q` in page links.

## Tests executed and fixes

### Initial CRUD/report request batch

Command:

```text
bundle exec rails test test/integration/crud_flows_test.rb test/integration/report_pages_test.rb
```

Result: **16 runs, 152 assertions, 0 failures, 0 errors**.

Additional CRUD flow cases were added later, so this historical count is not a current full-suite count.

### Initial model batch

Command:

```text
bundle exec rails test test/models
```

Initial result: **24 runs, 78 assertions, 0 failures, 0 errors**.

After adding database-schema coverage, the same model-directory command initially exposed test-code compatibility problems:

- Schema assertion helpers referenced an undefined `connection` receiver. A local helper returning `ApplicationRecord.connection` was added.
- Rails 8 `insert!` expects the attributes as a positional hash; keyword-style calls in the constraint-bypass tests were changed to explicit hash arguments.

These were test mechanics, not weakened model or database rules. After the fixes, the expanded model result was **29 runs, 119 assertions, 0 failures, 0 errors**.

### Seed/query/report targeted batch

A targeted batch covering seed services, query objects, and report-page integration tests initially had one failure. The dataset-builder test asserted an exact minimum review count produced by a particular pseudo-random sequence even though the requirement is a range of 1 through 10. The assertion was corrected to verify the required lower and upper bounds. Production generation logic and validation rules were not weakened.

Result after the test correction: **35 runs, 189 assertions, 0 failures, 0 errors**.

These entries are intentionally labeled targeted batches. A targeted result is not represented here as a full-suite result; subsequent complete-suite and quality-command results should be appended only after those commands have actually finished.

## Docker reproducibility check

`docker compose build web` completed successfully from the committed lockfile. The first execution of a documented one-off `web` command then failed with `Bundler::GemNotFound`: the Compose `bundle_data` mount hid gems that had already been installed at `/usr/local/bundle` in the built image. The unnecessary gem-volume mount and declaration were removed. Compose now uses the image's locked bundle directly; dependency changes require `docker compose build web` again.

## Final independent audit and verification

The independent second pass found and corrected these concrete edge cases before the final run:

- Author/report and search regressions were expanded to isolate every numeric boundary, literal `%` and `_` wildcard handling, equal-name ID tie-breaks, authors with books but no reviews/sales, oversized search input, and rendered pagination persistence.
- Search input is now bounded to 500 normalized characters and 50 distinct accepted tokens before constructing the OR expression. The displayed and paginated query is exactly the accepted token set; a 2,000-token request no longer overflows Arel's visitor stack.
- Open Library discovery now interleaves subject queries, counts usable deduplicated books rather than raw documents, keeps useful works with missing optional metadata, retries/translates TLS and HTTP protocol failures, and limits each ten-author work-search batch to five pages. This caps the assignment target at 25 work-search calls in a pathological duplicate/incomplete response while still supplementing only deficits.
- Synthetic fallback books are owned only by explicitly synthetic authors, avoiding fabricated authorship claims when a partial real import supplies authors but too few books. Duplicate source authors are removed before deciding the fallback deficit.
- Publication dates too late to support all configured forward sale years use the explicit synthetic date. Sale generation is forward-only and rejects an impossible sale-year count above 9,999.
- Generated publication-year sale values deliberately exercise deterministic annual ties while later years remain varied.
- Concurrent `Sale` inserts for different years on one book originally reproduced a PostgreSQL lock-upgrade deadlock: each foreign-key insert held `KEY SHARE`, then requested `FOR UPDATE` while refreshing the cached total. The book refresh now locks with `FOR NO KEY UPDATE`, which remains mutually serializing but is compatible with the foreign-key lock. A bounded two-connection PostgreSQL regression verifies both rows commit and the exact total is stored.

The refreshed live Open Library seed completed after the importer selection changes:

| Metric | Result |
| --- | ---: |
| Open Library authors | 50 |
| Open Library books | 300 |
| Fallback authors | 0 |
| Fallback books | 0 |
| Incomplete Open Library records skipped | 2 |
| Total reviews | 1,609 |
| Total yearly sales | 1,500 |
| Reviews per book | 1..10 |
| Minimum distinct sale years per book | 5 |
| Cached sales mismatches | 0 |
| Same-year equal-sales groups | 59 |

The live publication years spanned 1200 through 2024, all 50 imported authors owned books, review scores covered 1 through 5, yearly sale values were varied, and no book lacked a searchable summary. A separate seed in `RAILS_ENV=test` with `OPEN_LIBRARY_ENABLED=false` again produced 50 fallback authors, 300 fallback books, 1,609 reviews, 1,500 sales, 40 same-year tie groups, and zero cached-total mismatches; validation passed.

The definitive clean database command was executed after every audit fix:

```text
RAILS_ENV=test bundle exec rails db:test:purge db:test:prepare test
```

Docker supplied the environment variables and PostgreSQL service. Result: **92 runs, 546 assertions, 0 failures, 0 errors, 0 skips**.

Final quality commands on the same tree reported:

- `bundle exec rubocop`: **57 files inspected, no offenses**.
- `bundle exec brakeman --no-pager --no-exit-on-warn`: no application-code security warning; one weak lifecycle notice that Rails 8.0.5.1 support ends on 2026-10-07.
- `bin/importmap audit`: **No vulnerable packages found**.
- `bundle exec rails zeitwerk:check`: **All is good!**

The live development database was left with the successful Open Library-backed dataset. The clean full suite operated only on `book_reviews_test`.

## Assignment 02 local Kubernetes runtime verification

The required local Kubernetes behavior was verified on 2026-08-27 after the
infrastructure audit fixes:

- Minikube 1.38.1 was installed and started with the Docker driver, 4 CPUs and
  6144 MiB of memory. The single control-plane node reached `Ready` on
  Kubernetes 1.35.1.
- Minikube enabled its `standard` host-path StorageClass. The locally built
  `book-reviews:local` production image was loaded into Minikube and confirmed
  in the node image list.
- `kubectl apply --dry-run=client -k k8s` accepted all eight rendered resources.
  `kubectl apply -k k8s` then created the namespace, ConfigMap, local Secret,
  two Services, PVC, PostgreSQL Deployment, and Rails Deployment.
- Both Deployments rolled out successfully. The Rails and PostgreSQL Pods each
  reached `1/1 Running`. The PVC `book-reviews-postgres-data` reached `Bound`
  with 2 GiB, `ReadWriteOnce`, StorageClass `standard`, and PV
  `pvc-0ac58a85-e821-499e-a181-2ff847b736cb`.

### Application Service reachability

`kubectl port-forward service/book-reviews-web 8080:80` exposed the Kubernetes
Service. Requests to `/up` and `/` both returned HTTP 200. The Service's
EndpointSlice pointed to the ready Rails Pod.

### Rails self-healing

The original Rails Pod
`book-reviews-web-7985bbc869-fgst9` (UID
`ce2a2712-9372-4650-be3a-a62bf1679e8b`) was deleted without changing the
Deployment. Kubernetes created
`book-reviews-web-7985bbc869-927sc` (UID
`9324dd0a-1b03-4624-aedf-2775d78b1abe`). The Deployment returned to one desired,
ready, available, and updated replica, and `/up` again returned HTTP 200.

### PostgreSQL Pod persistence

A book named `KUBERNETES_PERSISTENCE_MARKER` was created with database ID 301.
The original PostgreSQL Pod
`book-reviews-postgres-8475c5476c-l2dm9` (UID
`c22e3ec1-ffb2-4ff5-86a3-a5200ba41234`) was deleted. Kubernetes created
`book-reviews-postgres-8475c5476c-bq7s2` (UID
`c16cd762-1310-4c3b-882e-8142c77aa3cc`). The PVC remained `Bound` to the same PV,
and the marker still existed with ID 301 and count 1. PostgreSQL logged that the
data directory already contained a database and skipped initialization, then
opened the existing database successfully.

### Horizontal replica check

The Rails Deployment was temporarily scaled to two replicas. Both reached
`Ready` and `Available`, and the Service EndpointSlice contained both Pod IPs.
The Deployment was then restored to the committed value of one replica and
settled at one desired/current/ready/available replica. The application and the
Kubernetes persistence marker remained reachable through the Service afterward.
