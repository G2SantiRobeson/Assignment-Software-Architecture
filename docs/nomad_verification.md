# Nomad deployment verification

This record contains objective evidence from the local Group 7 Nomad deployment. It is a technical verification record, not the students' final report.

## Environment

- Verification date: 2026-08-25
- Host environment: WSL2, Ubuntu 24.04, systemd, cgroup v2
- Nomad: 1.11.3
- Linux Docker Engine: 29.1.3
- Nomad node: `dae863f6`, eligible and ready
- Docker task driver: detected and healthy

The Rails production image `book-reviews:nomad` was built in the same Linux Docker Engine used by the Nomad client. The PostgreSQL, migration, and web jobs all passed live-agent validation and scheduler planning.

## Deployment

- Initial PostgreSQL allocation: `325e9061`
- PostgreSQL service endpoint: `172.31.174.105:5432`
- Migration allocation: `e1d0b5ad`
- Migration result: complete, exit code 0
- Seed result: 50 authors, 300 books, 1,609 reviews, 1,500 sales, validation passed
- Initial web allocation: `19f4fef5`
- Initial web endpoint: `172.31.174.105:21014`
- Initial `/up` and `/` checks from Windows: HTTP 200

Rails and the migration job obtained the database address and port from Nomad native service discovery. Secrets were loaded into job-scoped Nomad Variables; their values were suppressed from command output and were not written to the repository or image.

## Web allocation recovery

```text
Original allocation:
19f4fef5

Action:
nomad alloc stop 19f4fef5

Replacement allocation:
56cce600

Replacement endpoint:
172.31.174.105:27283

Post-recovery checks:
/up = HTTP 200
/   = HTTP 200

Result:
PASS
```

Nomad restored the desired count to one and registered only the healthy replacement endpoint.

## PostgreSQL allocation persistence

```text
Data before replacement:
51:NOMAD_PERSISTENCE_AUDIT_20260825

Original database allocation:
325e9061

Action:
nomad alloc stop 325e9061

Replacement database allocation:
91b11e5e

Data after replacement:
51:NOMAD_PERSISTENCE_AUDIT_20260825

Rails after database replacement:
/up = HTTP 200
/   = HTTP 200

Result:
PASS
```

The database files remained in the Docker named volume `book_reviews_nomad_postgres_data`, mounted from `/var/lib/docker/volumes/book_reviews_nomad_postgres_data/_data` in the WSL2 Docker Engine.

## Horizontal scaling

The registered web job was scaled from one to two allocations:

| Allocation | Endpoint | Health result |
| --- | --- | --- |
| `56cce600` | `172.31.174.105:27283` | HTTP 200 |
| `d6d4f7d4` | `172.31.174.105:28534` | HTTP 200 |

Nomad reported `Desired=2`, `Placed=2`, and `Healthy=2`. The job was then scaled back to one healthy allocation, matching the committed jobspec.
