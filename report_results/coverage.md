# Cobertura de los 40 escenarios

Completos: 7; parciales: 33; faltantes: 0.

OK: HTTP reconciliado con muestras y métricas CPU/memoria/threads presentes para todos los contenedores identificados y sus procesos observados. No certifica muestreo continuo de procesos transitorios. Requests enviados no tiene contador independiente. CPU PARTIAL identifica procesos sin un intervalo de CPU válido, no ausencia de CPU del contenedor. El detalle por proceso está en process_summary.csv (cpu_samples=0); coverage.csv incluye containers_status y processes_without_cpu.

| Deployment | Endpoint | Requests | HTTP data | CPU | Memory | Threads | Estado | Raw source |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| single | aggregation | 1 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/full-aggregation-1 |
| single | aggregation | 10 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/full-aggregation-10 |
| single | aggregation | 100 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/full-aggregation-100 |
| single | aggregation | 1000 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/full-aggregation-1000 |
| single | aggregation | 5000 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/full-aggregation-5000 |
| single | book | 1 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/full-book-1 |
| single | book | 10 | OK | OK | OK | OK | OK | results/matrix-20260916-2305/full-book-10 |
| single | book | 100 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/full-book-100 |
| single | book | 1000 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/full-book-1000 |
| single | book | 5000 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/full-book-5000 |
| single | search | 1 | OK | OK | OK | OK | OK | results/matrix-20260916-2305/full-search-1 |
| single | search | 10 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/full-search-10 |
| single | search | 100 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/full-search-100 |
| single | search | 1000 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/full-search-1000 |
| single | search | 5000 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/full-search-5000 |
| single | static | 1 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/full-static-1 |
| single | static | 10 | OK | OK | OK | OK | OK | results/matrix-20260916-2305/full-static-10 |
| single | static | 100 | OK | OK | OK | OK | OK | results/matrix-20260916-2305/full-static-100 |
| single | static | 1000 | OK | OK | OK | OK | OK | results/matrix-20260916-2305/full-static-1000 |
| single | static | 5000 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/full-static-5000 |
| x3 | aggregation | 1 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-aggregation-1 |
| x3 | aggregation | 10 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-aggregation-10 |
| x3 | aggregation | 100 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-aggregation-100 |
| x3 | aggregation | 1000 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-aggregation-1000 |
| x3 | aggregation | 5000 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-aggregation-5000 |
| x3 | book | 1 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-book-1 |
| x3 | book | 10 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-book-10 |
| x3 | book | 100 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-book-100 |
| x3 | book | 1000 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-book-1000 |
| x3 | book | 5000 | OK | OK | OK | OK | OK | results/matrix-20260916-2305/scaled-book-5000 |
| x3 | search | 1 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-search-1 |
| x3 | search | 10 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-search-10 |
| x3 | search | 100 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-search-100 |
| x3 | search | 1000 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-search-1000 |
| x3 | search | 5000 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-search-5000 |
| x3 | static | 1 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-static-1 |
| x3 | static | 10 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-static-10 |
| x3 | static | 100 | OK | OK | OK | OK | OK | results/matrix-20260916-2305/scaled-static-100 |
| x3 | static | 1000 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-static-1000 |
| x3 | static | 5000 | OK | PARTIAL | OK | OK | PARTIAL | results/matrix-20260916-2305/scaled-static-5000 |
