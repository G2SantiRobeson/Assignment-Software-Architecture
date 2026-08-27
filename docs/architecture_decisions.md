# Architecture Decisions

This document is an objective technical implementation record for the coded portion of the assignment. It is not the students' final report.

# 1. Conventional Rails monolith

## Decision

Implement the application as one conventional Ruby on Rails monolith containing the domain models, HTML controllers and views, query objects, seed integration, and tests.

## Architectural Driver

Ruby and Rails are mandatory constraints. The assignment has one cohesive book-review domain, a modest dataset, no authentication requirement, a small-team/university scope, and quality priorities of correctness, maintainability, and simplicity.

## Alternatives Considered

A separate JavaScript frontend and JSON API, domain microservices, or independent reporting/search services.

## Trade-off

One deployable application keeps transactions, associations, routing, tests, and local setup direct. It gives up independent component deployment and scaling, neither of which is required for this workload.

## Cost of Changing Later

**High.** Splitting the monolith would change application boundaries, deployment, HTTP contracts, transaction ownership, tests, and likely the user interface.

# 2. PostgreSQL as the only database engine

## Decision

Use PostgreSQL through the `pg` adapter in every Rails environment; development is documented against PostgreSQL 16 and Compose pins `postgres:16-alpine`.

## Architectural Driver

PostgreSQL is a mandatory constraint. The reports also need correct relational aggregation, check constraints, unique indexes, `ILIKE`, filtered aggregates, and window functions.

## Alternatives Considered

SQLite for development/tests, MySQL, or database-neutral processing in Ruby.

## Trade-off

Using the same engine everywhere prevents dialect and constraint drift and enables clear database-side queries. It requires a PostgreSQL service for local development and tests and makes several queries PostgreSQL-specific.

## Cost of Changing Later

**High.** A different engine would require configuration and schema changes plus rewrites and re-verification of report, search, constraint, and test behavior.

# 3. Active Record for persistence and domain rules

## Decision

Use Active Record models, associations, validations, callbacks, migrations, transactions, locking, eager loading, and query relations. Keep specialized SQL inside query objects where Active Record alone would obscure correctness.

## Architectural Driver

Rails convention, maintainability, testability, and the requirement to enforce rules both in models and PostgreSQL favor Active Record as the persistence boundary.

## Alternatives Considered

Direct SQL throughout controllers, a separate repository/data-mapper layer, or an additional ORM.

## Trade-off

Active Record integrates naturally with Rails forms and CRUD and keeps routine persistence concise. Complex aggregation still needs SQL knowledge, and callbacks must be accounted for when bulk APIs bypass them.

## Cost of Changing Later

**High.** Replacing Active Record would affect every model, migration, controller, query, seed service, and database-oriented test.

# 4. Required Author-to-Books relationship

## Decision

Model `Author has_many :books` and `Book belongs_to :author` with a non-null `books.author_id`, an index, and a PostgreSQL foreign key. Deletion is deliberately restricted when dependent books exist.

## Architectural Driver

The domain requires every book to have an author, and the reports require book counts, review averages, and sales totals grouped by author. Data integrity takes priority over convenient destructive deletion.

## Alternatives Considered

Storing an author name on each book, an optional author foreign key, a many-to-many authorship table, or cascading deletion of an author's books.

## Trade-off

The normalized one-to-many relationship makes the required queries and integrity rules direct. It supports one author per book, as specified, rather than multi-author works; restricted deletion requires dependent records to be handled explicitly.

## Cost of Changing Later

**High.** Optional or multi-author semantics would require schema migration, form and controller changes, query rewrites, seed remapping, and new integrity tests.

# 5. Normalized yearly Sale records

## Decision

Store annual sales as `Sale(book_id, year, sales)` rows. Enforce one row per book/year with a composite unique index and constrain year to `1..9999` and sales to non-negative integers in both model and database layers.

## Architectural Driver

The domain explicitly requires sales by year, publication-year ranking, and at least five annual observations per seeded book. Normalization and data integrity are prioritized.

## Alternatives Considered

A JSON/hash column on `Book`, one lifetime total only, or separate year-specific columns.

## Trade-off

Rows are easy to validate, aggregate, rank, and extend to additional years. They add a table and synchronization work for the required lifetime-sales field.

## Cost of Changing Later

**High.** Replacing annual rows would alter the schema, CRUD, seed generator, lifetime totals, publication-year ranking query, and tests.

# 6. Synchronize `Book.number_of_sales` from yearly sales

## Decision

Treat `SUM(sales.sales)` as authoritative and maintain `Book.number_of_sales` as a synchronized lifetime-total cache. `Sale` callbacks refresh totals after create/update/destroy, including both books when a sale changes ownership. The refresh locks books in stable ID order. Bulk seed insertion performs one explicit refresh pass because `insert_all!` bypasses callbacks.

## Architectural Driver

The assignment requires both `Book.number_of_sales` and yearly `Sale` records without allowing two unrelated sources of truth. Correctness under normal CRUD and centralized behavior are required.

## Alternatives Considered

Allowing manual edits to both values, calculating the total on every read and ignoring the column, database triggers, or duplicating refresh logic in controllers.

## Trade-off

The stored field remains consistent for Rails writes and is cheap to display. Each sale mutation performs an aggregate/update and depends on writes going through the model or an explicit bulk refresh; direct SQL outside that contract could make the cache stale.

## Cost of Changing Later

**Medium.** The synchronization is centralized, but changing authority or moving to triggers would require a data reconciliation, callback/service changes, and regression testing of all write paths.

# 7. Open Library as the primary author/book source

## Decision

Prefer Open Library for author identity, book identity, title, author relationship, first publication year, and available descriptive metadata. Use `/search.json` with selected fields for bounded discovery and author-batch work searches and perform at most one cached `/authors/{id}.json` detail lookup per selected author. Normalize stable `/authors/OL...A` and `/works/OL...W` keys for deduplication. Throttle to one request per second by default, or three per second when custom contact identification is configured.

## Architectural Driver

The assignment explicitly prefers real Open Library bibliographic data while requiring at least 50 authors and 300 books and reasonable API usage.

## Alternatives Considered

Entirely procedural records, another external catalog, or hundreds of unbatched edition/work requests.

## Trade-off

Real identities and relationships make the dataset more representative; selected search fields, author batching, caching, and throttling keep usage bounded and policy-conscious. Seed results depend on upstream availability and metadata quality. A usable `first_publish_year` is represented consistently as January 1 because the assignment model stores a date; a missing, invalid, or too-late year that cannot support the configured forward sales horizon uses the explicit synthetic publication-date fallback.

## Cost of Changing Later

**Medium.** The source is isolated behind a normalized result contract, but a replacement would still need equivalent selection, mapping, deduplication, tests, and usage policies.

# 8. Isolate Open Library integration from seed orchestration

## Decision

Keep HTTP, response validation, retry behavior, parsing, normalization, and author-detail caching in `OpenLibraryImporter`. Keep persistence, fallback generation, review/sale generation, and transactional rebuilding in `AssignmentDatasetBuilder`. Let `db/seeds.rb` configure, invoke, verify, and report the result.

## Architectural Driver

External integration concerns must not turn `db/seeds.rb` into a large API client. Separation improves maintainability, testability, and graceful failure handling.

## Alternatives Considered

All seed and HTTP logic inline in `db/seeds.rb`, persistence inside the HTTP client, or controller-driven importing.

## Trade-off

Each service has a narrow, independently testable responsibility and normal application requests never depend on Open Library. The design adds service interfaces and result objects to a small application.

## Cost of Changing Later

**Medium.** Responsibilities can be rearranged without schema changes, but importer/builder contracts and their focused tests would need coordinated updates.

# 9. Graceful external API fallback

## Decision

Apply bounded timeouts and configurable retries for transient network errors and HTTP `429`/`5xx` responses. Treat per-query, author-detail, malformed-response, and availability failures as warnings where possible. Persist all usable normalized records, then fill only remaining author/book deficits locally; allow `OPEN_LIBRARY_ENABLED=false` for a fully offline seed.

## Architectural Driver

Open Library downtime is explicitly not a blocker. Seeding must reliably satisfy assignment cardinalities without making normal runtime depend on an external service.

## Alternatives Considered

Fail the entire seed on any API error, silently omit required records, retry indefinitely, or always skip the primary source.

## Trade-off

Seeding completes predictably during outages and exposes limitations in warnings and source counts. An offline or partial run contains synthetic identities and may differ from a live run.

## Cost of Changing Later

**Medium.** Failure policy is localized, but stricter or asynchronous behavior would change operational expectations, seed output, and importer/builder tests.

# 10. Explicit real-versus-synthetic seed boundary

## Decision

Use Open Library records first for author/book identity and relationships. Mark locally supplied missing origins/descriptions and deficit records as synthetic. Generate all reviews and sales locally with a deterministic `SEED_RANDOM_SEED`. Map a usable Open Library `first_publish_year` to January 1; use the documented synthetic date when metadata is absent, invalid, or too late to fit the configured forward-only sale years.

## Architectural Driver

Real bibliographic data is preferred, but external records do not reliably contain every required field and Open Library does not provide the assignment's review/sales dataset.

## Alternatives Considered

Discard incomplete real records, invent unsupported nationalities for real authors, mix unlabeled generated fields with real claims, or make all entities synthetic.

## Trade-off

The dataset meets validations and clearly exposes fallback provenance in values and final source counts. Some fields are assignment mock data and must not be interpreted as bibliographic facts.

## Cost of Changing Later

**Medium.** Provenance fields or a richer metadata source could be added, but existing records, importer mappings, builder behavior, and documentation would need migration.

# 11. Dedicated complex-query objects

## Decision

Place report and search logic in classes under `app/queries`. Controllers coordinate parameters and responses, and ERB templates render already-shaped results.

## Architectural Driver

The reports require non-trivial aggregation, windowing, sorting, filtering, tie-breaking, and pagination. Query clarity, correctness, reuse, and isolated testing are higher priorities than minimizing class count.

## Alternatives Considered

Large SQL strings in views, aggregation in controllers, loading records into Ruby, or placing every report as a broad model scope.

## Trade-off

The SQL and its parameter policy are reviewable and testable without bloated controllers or templates. Query objects are application-specific abstractions and include PostgreSQL-specific expressions.

## Cost of Changing Later

**Low.** Moving orchestration to scopes or another query layer is mostly localized as long as returned attributes and controller contracts remain stable.

# 12. Independently pre-aggregate author statistics

## Decision

Compute book counts, review-score averages, and yearly-sale sums in three independent subqueries grouped by author, then `LEFT JOIN` each result to authors. Coalesce absent metrics to zero. Use a fixed map of sortable SQL expressions, a fixed direction list, parameterized numeric ranges, and escaped `ILIKE` author filtering.

## Architectural Driver

Every author must remain visible, every metric must be sortable/filterable, aggregation must happen in PostgreSQL, and joining books to both reviews and sales directly would multiply rows and corrupt `COUNT`, `AVG`, and `SUM`.

## Alternatives Considered

One naive multi-join with aggregates, correlated subqueries per output row, loading associations into Ruby, or excluding authors without related records.

## Trade-off

Independent aggregates are mathematically correct and make zero-record behavior explicit: zero books, no review score, and no sales render as `0`. The SQL is longer and an author's average is the average of all review scores across that author's books, not an average of separately rounded book averages.

## Cost of Changing Later

**Medium.** A different metric definition or materialized statistics would require query, filter/sort semantics, UI labels, and mathematical regression tests to change together.

# 13. Deterministic top-rated ranking and review selection

## Decision

Rank only books with reviews by average score descending, review count descending, case-insensitive book name ascending, then book ID ascending, and limit to ten. For each book, use `ROW_NUMBER()` partitions to select the highest and lowest review by score, breaking equal-score ties by the lowest review ID.

## Architectural Driver

The top-rated page must show a correct top ten plus deterministic highest/lowest review text without N+1 queries or Ruby-side ranking.

## Alternatives Considered

Ordering only by average, random/unspecified review ties, separate review queries per book, or including unrated books with a zero score.

## Trade-off

Results and tied review selection are stable and produced in one database-side relation. Lowest ID gives insertion-order-like tie behavior but does not attempt to choose the most useful review by up-votes.

## Cost of Changing Later

**Low.** Ranking and tie rules are localized to one query object and its tests, though changed rules will intentionally change displayed results.

# 14. Independent totals for the top-selling report

## Decision

Compute lifetime book totals and lifetime author totals in separate grouped subqueries, join them to books, order books by total sales descending then case-insensitive name and ID, and limit to fifty. Compute publication-year status from a separate annual ranking relation joined on both book ID and the year extracted from `date_of_publication`.

## Architectural Driver

The report needs book totals, author totals, and a publication-year top-five flag without multiplicative joins. All ranking must happen in PostgreSQL and be deterministic.

## Alternatives Considered

Joining author books and all their sales into one aggregate, trusting the cached book total for analytics, ranking all lifetime sales for the top-five flag, or calculating totals in Ruby.

## Trade-off

Separated aggregates prevent inflated totals and make yearly semantics explicit. The query repeats controlled aggregation work and is tied to PostgreSQL SQL features; books without sales remain eligible with a zero total.

## Cost of Changing Later

**Medium.** Changing the definition of totals or the publication-year comparison affects several subqueries, output attributes, explanatory UI, and mathematical tests.

# 15. `ROW_NUMBER()` for an exact annual top five

## Decision

Use `ROW_NUMBER()` partitioned by sale year for publication-year ranking. Order by annual sales descending, case-insensitive book name ascending, then book ID ascending. A book is top five only when its resulting row number is `1..5` in its own publication year.

## Architectural Driver

"Top 5" is ambiguous when sales tie. The application needs exactly five deterministic positions and must use sales made during each book's publication year.

## Alternatives Considered

`RANK()` (which leaves gaps and can include more than five tied books), `DENSE_RANK()` (which can also include more than five), or arbitrary database ordering among ties.

## Trade-off

The page always has an exact, repeatable five-position cutoff per year. Equal annual sales do not share rank; alphabetical name and then ID decide their order.

## Cost of Changing Later

**Low.** Switching tie semantics is a localized SQL and test change, but it changes the meaning and potentially the number of flagged books.

# 16. Escaped PostgreSQL `ILIKE` ANY-word search

## Decision

Split trimmed input on whitespace, ignore empty and case-insensitive duplicate tokens, cap accepted input at 500 normalized characters and 50 distinct tokens, escape SQL wildcard characters, and combine parameterized `summary ILIKE '%token%'` predicates with OR. Return no records for an empty token set, expose exactly the accepted query in the form/page links, and order matches by case-insensitive book name then ID.

## Architectural Driver

Search must be case-insensitive, match any entered word, resist SQL injection and wildcard surprises, handle empty input, and remain simple for a modest dataset.

## Alternatives Considered

PostgreSQL full-text search, an external search engine, AND semantics, raw SQL interpolation, or Ruby-side filtering.

## Trade-off

The implementation exactly matches the requested substring/ANY-word behavior for the bounded accepted query and needs no new dependency. Bounding the public input prevents pathological expression trees, but excess input is deliberately omitted from the displayed accepted query. Leading-wildcard `ILIKE` does not use an ordinary B-tree efficiently, and whitespace tokenization does not provide stemming or language-aware ranking.

## Cost of Changing Later

**Medium.** Moving to full-text or external search would require indexing/configuration, changed match semantics, result tests, and possibly relevance-oriented UI.

# 17. Small custom limit/offset pagination

## Decision

Paginate search in the query object with PostgreSQL `COUNT`, `LIMIT`, and `OFFSET`: 20 results by default, a hard internal maximum of 100, invalid pages normalized to page 1, and out-of-range pages clamped to the last page. Pagination links merge the original `q` value.

## Architectural Driver

Only summary search requires pagination, query persistence is mandatory, the dataset is modest, and unnecessary dependencies are discouraged.

## Alternatives Considered

Kaminari, Pagy, will_paginate, keyset pagination, or returning every match.

## Trade-off

The page object is small, explicit, and sufficient for the assignment. Offset performance degrades on very deep pages and it lacks the broader helpers and features of a pagination gem.

## Cost of Changing Later

**Low.** Pagination is isolated to one query result object and one view; adopting a gem mainly changes that interface, links, and tests.

# 18. Server-rendered Rails UI

## Decision

Render ERB pages on the server using Rails layouts, form helpers, RESTful routes, and standard controller responses. Use eager loading in CRUD listings and keep presentation logic out of database queries where practical.

## Architectural Driver

A server-rendered application is sufficient, no separate client is required, and simplicity, maintainability, usability, and Rails conventions are explicit priorities.

## Alternatives Considered

React, Vue, Angular, a standalone SPA consuming JSON, or a GraphQL client/server split.

## Trade-off

Forms, validation errors, CSRF protection, routing, and deployment remain cohesive with little client-side complexity. Highly interactive behavior would require incremental JavaScript or later API boundaries.

## Cost of Changing Later

**High.** A separate frontend would require API design, client routing/state/forms, duplicated validation handling, a new build/deployment path, and broad integration-test changes.
