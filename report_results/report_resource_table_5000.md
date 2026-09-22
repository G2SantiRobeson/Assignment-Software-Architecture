# Resource measurements at 5000 requests

Each test lasted 300 seconds. Components shown: static origin for static assets; Rails application for aggregation and book details; OpenSearch for search. Each application replica is a separate row. This selection follows the endpoint roles in the assignment and does not identify a bottleneck.

CPU average and maximum, memory maximum, and thread maximum are descriptive statistics of the container samples collected during each run. The collector also ran briefly before and after k6. Full measurements for all containers and individual processes are in `infrastructure_summary.csv` and `process_summary.csv`. The companion CSV retains the raw source path for every row.

| Endpoint | Deployment | Container | CPU avg (%) | CPU max (%) | Memory max (MiB) | Threads max |
| --- | --- | --- | --- | --- | --- | --- |
| Static asset | single | static-1 | 2.33 | 5.4 | 35.6 | 10 |
| Static asset | x3 | static-1 | 1.82 | 4.0 | 36.0 | 9 |
| Aggregation | single | web-1 | 16.82 | 24.08 | 140.3 | 12 |
| Aggregation | x3 | web-1 | 4.4 | 7.8 | 131.4 | 11 |
| Aggregation | x3 | web-2 | 4.6 | 7.63 | 135.6 | 11 |
| Aggregation | x3 | web-3 | 4.38 | 7.64 | 135.0 | 11 |
| Search | single | opensearch-1 | 8.65 | 27.8 | 1534.0 | 131 |
| Search | x3 | opensearch-1 | 4.16 | 10.1 | 1536.0 | 133 |
| Book detail | single | web-1 | 10.39 | 14.45 | 136.4 | 11 |
| Book detail | x3 | web-1 | 3.49 | 6.26 | 133.0 | 11 |
| Book detail | x3 | web-2 | 3.25 | 6.16 | 134.3 | 11 |
| Book detail | x3 | web-3 | 3.21 | 6.64 | 129.3 | 11 |
