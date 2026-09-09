# Running caching and search

These are development commands and verification notes, not the university report.
Run commands from the repository root. Keep the existing `.env` from Assignment 2,
or copy `.env.example` to `.env` and replace its example database password.
Native Rails does not automatically load `.env`; export variables in its shell.

## Docker Compose

Each entry file is standalone. Use one at a time; all publish port 3000 and use
the same project-scoped PostgreSQL volume when invoked from this directory.

```sh
# Application + PostgreSQL
docker compose -f compose.yaml up --build -d

# Application + PostgreSQL + Redis
docker compose -f compose.cache.yaml up --build -d

# Application + PostgreSQL + OpenSearch
docker compose -f compose.search.yaml up --build -d

# Application + PostgreSQL + Redis + OpenSearch
docker compose -f compose.full.yaml up --build -d
```

When switching from full to a smaller configuration, first stop the previous
configuration with `docker compose -f compose.full.yaml down`. Do not add `-v`;
that deletes PostgreSQL data. Optional services are not Rails startup dependencies.
OpenSearch can need a minute to become healthy; search falls back while it starts.

```sh
docker compose -f compose.full.yaml ps
docker compose -f compose.full.yaml exec redis redis-cli ping
docker compose -f compose.full.yaml exec opensearch curl -fsS http://localhost:9200/_cluster/health

# Pause application writes for this maintenance command.
docker compose -f compose.full.yaml exec web bin/rails search:reindex

# Real Rails forms/controllers, Redis and OpenSearch. Creates and removes only
# its own verification records. Prints PASS checks; exits nonzero on a failure.
# Includes a complete reindex to repair deliberately failed search writes.
docker compose -f compose.full.yaml exec web bin/rails assignment3:verify

# Separate test database; tests inject adapters and need no Redis/OpenSearch.
docker compose -f compose.yaml run --rm -e RAILS_ENV=test -e PARALLEL_WORKERS=2 web bin/rails test
docker compose -f compose.yaml run --rm --no-deps --entrypoint bin/rubocop web
```

On Windows, `./script/verify_compose.ps1` builds and smoke-tests all four
configurations, stopping omitted optional services between runs. It uses the
isolated Compose project `book-reviews-a3`; `-ProjectName NAME` overrides that name.
It requires port 3000 to be free or owned by that same project.

## Configuration

| Variable | Native default | Purpose |
| --- | --- | --- |
| `CACHE_ENABLED` | `false` | `true` enables the four assignment caches |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis endpoint |
| `SEARCH_ENABLED` | `false` | `true` enables OpenSearch |
| `OPENSEARCH_URL` | `http://localhost:9200` | OpenSearch endpoint |
| `OPENSEARCH_INDEX` | `book_reviews_<Rails environment>_v1` | Dedicated book/review index |

Compose sets these values explicitly for each combination. Restart Rails after
changing configuration. Disabled adapters do not connect to external services.

The migration adds `cache_revisions`; it does not change domain columns. Entrypoints
run `db:prepare`; native installations can use `bin/rails db:migrate`.
Cache revision updates commit with domain writes, and Redis deletions run after
commit. This prevents stale values after failed invalidations, disabled-cache
writes, and a cache fill that finishes after an invalidation. Cache reads inside
transactions bypass Redis. Old, unreachable keys expire after one hour.

Only author aggregates, rated rankings, selling rankings, and per-book average
scores use `ReadCache`. Existing `Rails.cache` configuration remains independent.
Author names, book attributes and ranking display names are loaded from PostgreSQL.
The seed builder explicitly invalidates caches and rebuilds search after its bulk
database replacement, because bulk SQL skips model callbacks.

## Kubernetes

Keep the Assignment 2 PostgreSQL PVC and existing credentials. If no local
`k8s/secret.yaml` exists, follow `README_DELIVERY_2.md` to materialize it from
`k8s/secret.example.yaml`; never commit credentials.

```sh
minikube start --driver=docker --cpus=4 --memory=6144
minikube image build -t book-reviews:assignment3 .
kubectl apply --dry-run=server -k k8s
kubectl apply -k k8s
kubectl -n book-reviews rollout restart deployment/book-reviews-web
kubectl -n book-reviews rollout status deployment/book-reviews-postgres --timeout=5m
kubectl -n book-reviews rollout status deployment/book-reviews-redis --timeout=5m
kubectl -n book-reviews rollout status deployment/book-reviews-opensearch --timeout=5m
kubectl -n book-reviews rollout status deployment/book-reviews-web --timeout=5m
kubectl -n book-reviews exec deployment/book-reviews-web -c rails -- bin/rails search:reindex
kubectl -n book-reviews port-forward service/book-reviews-web 8080:80
```

If the host reports an OpenSearch `vm.max_map_count` bootstrap failure, set it in
the local Linux node: `minikube ssh -- sudo sysctl -w vm.max_map_count=262144`.
The OpenSearch Kubernetes volume is deliberately reconstructable `emptyDir`;
run `search:reindex` after replacing its pod. Redis has no persistence.

## Operational limits

- OpenSearch security is disabled and its service is internal. This configuration
  is for local university development, not production deployment.
- Search synchronization is synchronous after commit. Failed writes are logged
  and require `search:reindex`; there is no durable retry queue. Search may be
  incomplete until recovery. Database writes still succeed during an outage.
- Reindex replaces only the configured index. Pause writes while it runs; searches
  can fall back or see a partial index until it completes. Administrative requests
  allow 60 seconds, while ordinary search requests allow 2 seconds.
- Collapsed pagination uses cardinality with precision 40,000. Counts are approximate
  at large scale. Requests exceeding OpenSearch's result window fall back to the
  existing summary-only PostgreSQL query.
- Cache hits still query small PostgreSQL revision records and current display
  attributes. The author overview materializes one cached aggregate row per author
  into SQL `VALUES` to preserve PostgreSQL filtering, precision and collation.
- Cache revisions remain for deleted IDs to prevent reuse of old Redis keys.
  This table grows with domain churn. Bulk SQL outside the supplied seed workflow
  must explicitly invalidate caches and rebuild search.
- Normal database isolation applies: an in-flight read can reflect the snapshot
  just before a concurrent commit; subsequent reads use the new revision.

Integration references: [Rails RedisCacheStore](https://api.rubyonrails.org/classes/ActiveSupport/Cache/RedisCacheStore.html)
and the [official OpenSearch Ruby client](https://docs.opensearch.org/latest/clients/ruby/).
