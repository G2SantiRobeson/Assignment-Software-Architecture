# Tablas de resultados

Ventana configurada: 300 s. `single` = full con 1 réplica web; `x3` = scaled con 3. Tiempos en ms; CPU en % (100 % = un CPU lógico); memoria en MiB; threads en número. Promedios de infraestructura aritméticos por muestra, sin ponderación temporal. `—` = dato ausente. Las tablas redondean a 6 cifras significativas; los CSV conservan precisión.


# Static Asset

## Response times

| Requests | single Avg ms | single P95 ms | single P99 ms | x3 Avg ms | x3 P95 ms | x3 P99 ms |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 3.74352 | 3.74352 | 3.74352 | 8.15738 | 8.15738 | 8.15738 |
| 10 | 3.0864 | 4.49186 | 4.57054 | 3.87544 | 6.88558 | 8.60977 |
| 100 | 3.15369 | 3.77523 | 4.87645 | 3.76955 | 5.0298 | 8.19278 |
| 1000 | 3.74445 | 4.93826 | 7.8453 | 3.13092 | 4.24641 | 5.72978 |
| 5000 | 3.68462 | 4.78348 | 7.85543 | 2.77909 | 3.30895 | 3.73477 |

## Requests and errors

| Requests | single Completados | single Exitosos | single Fallidos | single Error % | single req/s | x3 Completados | x3 Exitosos | x3 Fallidos | x3 Error % | x3 req/s |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 1 | 0 | 0 | 0.00333345 | 1 | 1 | 0 | 0 | 0.00333349 |
| 10 | 10 | 10 | 0 | 0 | 0.0333346 | 10 | 10 | 0 | 0 | 0.0333349 |
| 100 | 100 | 100 | 0 | 0 | 0.333346 | 100 | 100 | 0 | 0 | 0.33335 |
| 1000 | 1000 | 1000 | 0 | 0 | 3.33352 | 1000 | 1000 | 0 | 0 | 3.33348 |
| 5000 | 5000 | 5000 | 0 | 0 | 16.6676 | 5000 | 5000 | 0 | 0 | 16.6674 |

## CPU

### web

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-web-1 | 0.800714 | 0.01 | 8.59 |
| single | 10 | book-reviews-a4-web-1 | 0.741707 | 0.01 | 3.68 |
| single | 100 | book-reviews-a4-web-1 | 0.648571 | 0.01 | 3.53 |
| single | 1000 | book-reviews-a4-web-1 | 1.11625 | 0.01 | 4.24 |
| single | 5000 | book-reviews-a4-web-1 | 1.18175 | 0.01 | 4.09 |
| x3 | 1 | book-reviews-a4-web-1 | 0.843333 | 0.01 | 4.27 |
| x3 | 1 | book-reviews-a4-web-2 | 1.12846 | 0.01 | 4.29 |
| x3 | 1 | book-reviews-a4-web-3 | 1.12205 | 0.01 | 4.52 |
| x3 | 10 | book-reviews-a4-web-1 | 1.13 | 0.01 | 4.42 |
| x3 | 10 | book-reviews-a4-web-2 | 0.878718 | 0 | 4.66 |
| x3 | 10 | book-reviews-a4-web-3 | 0.764615 | 0.01 | 4.55 |
| x3 | 100 | book-reviews-a4-web-1 | 0.733846 | 0 | 4.68 |
| x3 | 100 | book-reviews-a4-web-2 | 0.851538 | 0 | 4.01 |
| x3 | 100 | book-reviews-a4-web-3 | 0.577436 | 0.01 | 4.06 |
| x3 | 1000 | book-reviews-a4-web-1 | 0.66225 | 0 | 3.34 |
| x3 | 1000 | book-reviews-a4-web-2 | 0.7815 | 0 | 3.66 |
| x3 | 1000 | book-reviews-a4-web-3 | 0.7655 | 0.01 | 3.61 |
| x3 | 5000 | book-reviews-a4-web-1 | 0.807805 | 0 | 3.23 |
| x3 | 5000 | book-reviews-a4-web-2 | 0.974634 | 0 | 3.03 |
| x3 | 5000 | book-reviews-a4-web-3 | 0.700976 | 0 | 2.97 |

### static

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-static-1 | 0.885714 | 0.01 | 3.26 |
| single | 10 | book-reviews-a4-static-1 | 0.591707 | 0.01 | 3.44 |
| single | 100 | book-reviews-a4-static-1 | 1.12405 | 0.01 | 5.43 |
| single | 1000 | book-reviews-a4-static-1 | 0.86225 | 0.01 | 5.02 |
| single | 5000 | book-reviews-a4-static-1 | 2.3255 | 0.01 | 5.4 |
| x3 | 1 | book-reviews-a4-static-1 | 0.539487 | 0.01 | 4.22 |
| x3 | 10 | book-reviews-a4-static-1 | 0.883077 | 0.01 | 4 |
| x3 | 100 | book-reviews-a4-static-1 | 0.944615 | 0.01 | 5.81 |
| x3 | 1000 | book-reviews-a4-static-1 | 0.881 | 0.01 | 3.61 |
| x3 | 5000 | book-reviews-a4-static-1 | 1.82 | 0.01 | 4 |

### traefik

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-traefik-1 | 1.0019 | 0 | 12.78 |
| single | 10 | book-reviews-a4-traefik-1 | 1.30756 | 0 | 8.11 |
| single | 100 | book-reviews-a4-traefik-1 | 1.03452 | 0 | 7.67 |
| single | 1000 | book-reviews-a4-traefik-1 | 2.7975 | 0.06 | 8.76 |
| single | 5000 | book-reviews-a4-traefik-1 | 3.88275 | 0.11 | 11.22 |
| x3 | 1 | book-reviews-a4-traefik-1 | 1.48256 | 0 | 8.01 |
| x3 | 10 | book-reviews-a4-traefik-1 | 1.61051 | 0.05 | 8.83 |
| x3 | 100 | book-reviews-a4-traefik-1 | 1.30308 | 0 | 8.27 |
| x3 | 1000 | book-reviews-a4-traefik-1 | 2.4225 | 0.34 | 9.31 |
| x3 | 5000 | book-reviews-a4-traefik-1 | 3.69463 | 0.08 | 8.28 |

### db

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-db-1 | 1.24643 | 0 | 3.94 |
| single | 10 | book-reviews-a4-db-1 | 1.74146 | 0 | 3.79 |
| single | 100 | book-reviews-a4-db-1 | 1.56667 | 0 | 3.61 |
| single | 1000 | book-reviews-a4-db-1 | 2.12125 | 0 | 4.02 |
| single | 5000 | book-reviews-a4-db-1 | 1.8535 | 0 | 4.74 |
| x3 | 1 | book-reviews-a4-db-1 | 1.41897 | 0 | 5.1 |
| x3 | 10 | book-reviews-a4-db-1 | 2.9641 | 0 | 4.92 |
| x3 | 100 | book-reviews-a4-db-1 | 1.71231 | 0 | 5.73 |
| x3 | 1000 | book-reviews-a4-db-1 | 1.5775 | 0 | 3.8 |
| x3 | 5000 | book-reviews-a4-db-1 | 1.57488 | 0 | 3.28 |

### redis

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-redis-1 | 0.561905 | 0.25 | 3.12 |
| single | 10 | book-reviews-a4-redis-1 | 0.848049 | 0.26 | 3.16 |
| single | 100 | book-reviews-a4-redis-1 | 1.14071 | 0.27 | 3.29 |
| single | 1000 | book-reviews-a4-redis-1 | 0.99825 | 0.27 | 3.77 |
| single | 5000 | book-reviews-a4-redis-1 | 1.0165 | 0.29 | 3.33 |
| x3 | 1 | book-reviews-a4-redis-1 | 0.888462 | 0.29 | 4.55 |
| x3 | 10 | book-reviews-a4-redis-1 | 0.953077 | 0.3 | 4.11 |
| x3 | 100 | book-reviews-a4-redis-1 | 0.99641 | 0.28 | 3.24 |
| x3 | 1000 | book-reviews-a4-redis-1 | 0.87 | 0.27 | 5.85 |
| x3 | 5000 | book-reviews-a4-redis-1 | 0.668293 | 0.24 | 2.49 |

### opensearch

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-opensearch-1 | 1.66857 | 0.57 | 26.8 |
| single | 10 | book-reviews-a4-opensearch-1 | 1.13732 | 0.54 | 9.81 |
| single | 100 | book-reviews-a4-opensearch-1 | 0.933095 | 0.49 | 3.76 |
| single | 1000 | book-reviews-a4-opensearch-1 | 1.0115 | 0.63 | 4.54 |
| single | 5000 | book-reviews-a4-opensearch-1 | 0.9745 | 0.61 | 4.49 |
| x3 | 1 | book-reviews-a4-opensearch-1 | 1.03795 | 0.6 | 4.75 |
| x3 | 10 | book-reviews-a4-opensearch-1 | 1.03846 | 0.59 | 4.47 |
| x3 | 100 | book-reviews-a4-opensearch-1 | 1.31564 | 0.57 | 5.01 |
| x3 | 1000 | book-reviews-a4-opensearch-1 | 0.79125 | 0.46 | 4.36 |
| x3 | 5000 | book-reviews-a4-opensearch-1 | 0.719512 | 0.44 | 3.48 |

## Memory

### web

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-web-1 | 105.379 | 101.5 | 109.9 |
| single | 10 | book-reviews-a4-web-1 | 116.554 | 115.1 | 121.2 |
| single | 100 | book-reviews-a4-web-1 | 119.89 | 119.1 | 120.6 |
| single | 1000 | book-reviews-a4-web-1 | 125.047 | 124 | 126.1 |
| single | 5000 | book-reviews-a4-web-1 | 132.403 | 131.2 | 133.9 |
| x3 | 1 | book-reviews-a4-web-1 | 105.251 | 100.9 | 110.6 |
| x3 | 1 | book-reviews-a4-web-2 | 105.1 | 101.1 | 109 |
| x3 | 1 | book-reviews-a4-web-3 | 105.213 | 101.2 | 109.3 |
| x3 | 10 | book-reviews-a4-web-1 | 113.497 | 112.7 | 114.1 |
| x3 | 10 | book-reviews-a4-web-2 | 112.626 | 112 | 113.6 |
| x3 | 10 | book-reviews-a4-web-3 | 113.418 | 112.8 | 114.4 |
| x3 | 100 | book-reviews-a4-web-1 | 118.677 | 118 | 119.3 |
| x3 | 100 | book-reviews-a4-web-2 | 118.349 | 117.6 | 119 |
| x3 | 100 | book-reviews-a4-web-3 | 118.169 | 117.5 | 119.1 |
| x3 | 1000 | book-reviews-a4-web-1 | 122.39 | 120.6 | 128.1 |
| x3 | 1000 | book-reviews-a4-web-2 | 121.963 | 121 | 122.8 |
| x3 | 1000 | book-reviews-a4-web-3 | 121.53 | 120.5 | 122.8 |
| x3 | 5000 | book-reviews-a4-web-1 | 127.929 | 126.9 | 128.9 |
| x3 | 5000 | book-reviews-a4-web-2 | 128.317 | 126.9 | 131.6 |
| x3 | 5000 | book-reviews-a4-web-3 | 127.724 | 126.5 | 128.9 |

### static

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-static-1 | 24.1867 | 22.85 | 28.4 |
| single | 10 | book-reviews-a4-static-1 | 25.9863 | 24.57 | 27.03 |
| single | 100 | book-reviews-a4-static-1 | 27.9488 | 26.32 | 32.46 |
| single | 1000 | book-reviews-a4-static-1 | 29.2802 | 28.6 | 29.86 |
| single | 5000 | book-reviews-a4-static-1 | 29.962 | 29.27 | 35.61 |
| x3 | 1 | book-reviews-a4-static-1 | 29.8059 | 29.14 | 30.58 |
| x3 | 10 | book-reviews-a4-static-1 | 31.2077 | 30.37 | 35.73 |
| x3 | 100 | book-reviews-a4-static-1 | 31.4579 | 30.59 | 35.89 |
| x3 | 1000 | book-reviews-a4-static-1 | 30.8998 | 30.11 | 31.98 |
| x3 | 5000 | book-reviews-a4-static-1 | 31.1283 | 29.91 | 35.95 |

### traefik

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-traefik-1 | 112.44 | 111.2 | 113.7 |
| single | 10 | book-reviews-a4-traefik-1 | 115.5 | 114.2 | 130.9 |
| single | 100 | book-reviews-a4-traefik-1 | 116.59 | 115.6 | 117.6 |
| single | 1000 | book-reviews-a4-traefik-1 | 119.132 | 117.7 | 129.7 |
| single | 5000 | book-reviews-a4-traefik-1 | 120.713 | 118.9 | 121.7 |
| x3 | 1 | book-reviews-a4-traefik-1 | 119.497 | 117.9 | 120.8 |
| x3 | 10 | book-reviews-a4-traefik-1 | 119.644 | 118.5 | 121.3 |
| x3 | 100 | book-reviews-a4-traefik-1 | 120.618 | 119.3 | 121.7 |
| x3 | 1000 | book-reviews-a4-traefik-1 | 123.138 | 119.9 | 137.6 |
| x3 | 5000 | book-reviews-a4-traefik-1 | 123.371 | 120.3 | 133.9 |

### db

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-db-1 | 48.9474 | 47.68 | 50.14 |
| single | 10 | book-reviews-a4-db-1 | 49.5017 | 47.82 | 55.76 |
| single | 100 | book-reviews-a4-db-1 | 49.55 | 48.34 | 54.03 |
| single | 1000 | book-reviews-a4-db-1 | 49.555 | 48.66 | 56.32 |
| single | 5000 | book-reviews-a4-db-1 | 50.03 | 48.83 | 54.41 |
| x3 | 1 | book-reviews-a4-db-1 | 52.8259 | 51.91 | 57.38 |
| x3 | 10 | book-reviews-a4-db-1 | 55.1095 | 52.76 | 57.72 |
| x3 | 100 | book-reviews-a4-db-1 | 55.3069 | 53.56 | 61.01 |
| x3 | 1000 | book-reviews-a4-db-1 | 53.9432 | 52.93 | 54.79 |
| x3 | 5000 | book-reviews-a4-db-1 | 57.5895 | 55.52 | 59.03 |

### redis

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-redis-1 | 8.59948 | 7.957 | 12.32 |
| single | 10 | book-reviews-a4-redis-1 | 8.30076 | 7.637 | 8.891 |
| single | 100 | book-reviews-a4-redis-1 | 8.69883 | 7.738 | 13.32 |
| single | 1000 | book-reviews-a4-redis-1 | 9.9577 | 9.309 | 14.06 |
| single | 5000 | book-reviews-a4-redis-1 | 10.7773 | 10 | 11.31 |
| x3 | 1 | book-reviews-a4-redis-1 | 15.3459 | 14.79 | 15.99 |
| x3 | 10 | book-reviews-a4-redis-1 | 15.471 | 14.61 | 19.75 |
| x3 | 100 | book-reviews-a4-redis-1 | 15.5967 | 14.51 | 20.12 |
| x3 | 1000 | book-reviews-a4-redis-1 | 15.2797 | 14.62 | 15.85 |
| x3 | 5000 | book-reviews-a4-redis-1 | 16.3102 | 15.54 | 19.12 |

### opensearch

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-opensearch-1 | 1483.75 | 1471.49 | 1496.06 |
| single | 10 | book-reviews-a4-opensearch-1 | 1471.81 | 1471.49 | 1472.51 |
| single | 100 | book-reviews-a4-opensearch-1 | 1473.51 | 1472.51 | 1474.56 |
| single | 1000 | book-reviews-a4-opensearch-1 | 1472.36 | 1471.49 | 1476.61 |
| single | 5000 | book-reviews-a4-opensearch-1 | 1483.7 | 1482.75 | 1484.8 |
| x3 | 1 | book-reviews-a4-opensearch-1 | 1500.11 | 1497.09 | 1530.88 |
| x3 | 10 | book-reviews-a4-opensearch-1 | 1524.79 | 1520.64 | 1525.76 |
| x3 | 100 | book-reviews-a4-opensearch-1 | 1524.87 | 1523.71 | 1529.86 |
| x3 | 1000 | book-reviews-a4-opensearch-1 | 1528.29 | 1527.81 | 1532.93 |
| x3 | 5000 | book-reviews-a4-opensearch-1 | 1493.54 | 1492.99 | 1494.02 |

## Threads

### web

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-web-1 | 10 | 10 | 10 |
| single | 10 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| single | 100 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| single | 1000 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| single | 5000 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| x3 | 1 | book-reviews-a4-web-1 | 10.0256 | 10 | 11 |
| x3 | 1 | book-reviews-a4-web-2 | 10 | 10 | 10 |
| x3 | 1 | book-reviews-a4-web-3 | 10 | 10 | 10 |
| x3 | 10 | book-reviews-a4-web-1 | 10 | 10 | 10 |
| x3 | 10 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 10 | book-reviews-a4-web-3 | 10.1282 | 10 | 15 |
| x3 | 100 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| x3 | 100 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 100 | book-reviews-a4-web-3 | 11 | 11 | 11 |
| x3 | 1000 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| x3 | 1000 | book-reviews-a4-web-2 | 11.05 | 11 | 12 |
| x3 | 1000 | book-reviews-a4-web-3 | 11 | 11 | 11 |
| x3 | 5000 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| x3 | 5000 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 5000 | book-reviews-a4-web-3 | 11 | 11 | 11 |

### static

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| single | 10 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| single | 100 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| single | 1000 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| single | 5000 | book-reviews-a4-static-1 | 9.025 | 9 | 10 |
| x3 | 1 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| x3 | 10 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| x3 | 100 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| x3 | 1000 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| x3 | 5000 | book-reviews-a4-static-1 | 9 | 9 | 9 |

### traefik

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-traefik-1 | 17.1429 | 17 | 23 |
| single | 10 | book-reviews-a4-traefik-1 | 17 | 17 | 17 |
| single | 100 | book-reviews-a4-traefik-1 | 17 | 17 | 17 |
| single | 1000 | book-reviews-a4-traefik-1 | 17 | 17 | 17 |
| single | 5000 | book-reviews-a4-traefik-1 | 17 | 17 | 17 |
| x3 | 1 | book-reviews-a4-traefik-1 | 18.1026 | 18 | 22 |
| x3 | 10 | book-reviews-a4-traefik-1 | 18.2308 | 18 | 27 |
| x3 | 100 | book-reviews-a4-traefik-1 | 18 | 18 | 18 |
| x3 | 1000 | book-reviews-a4-traefik-1 | 18.775 | 18 | 30 |
| x3 | 5000 | book-reviews-a4-traefik-1 | 18.1463 | 18 | 24 |

### db

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-db-1 | 7 | 7 | 7 |
| single | 10 | book-reviews-a4-db-1 | 7.14634 | 7 | 8 |
| single | 100 | book-reviews-a4-db-1 | 7 | 7 | 7 |
| single | 1000 | book-reviews-a4-db-1 | 7 | 7 | 7 |
| single | 5000 | book-reviews-a4-db-1 | 7.175 | 7 | 8 |
| x3 | 1 | book-reviews-a4-db-1 | 9 | 9 | 9 |
| x3 | 10 | book-reviews-a4-db-1 | 9.69231 | 9 | 10 |
| x3 | 100 | book-reviews-a4-db-1 | 9.58974 | 9 | 10 |
| x3 | 1000 | book-reviews-a4-db-1 | 9 | 9 | 9 |
| x3 | 5000 | book-reviews-a4-db-1 | 10.6341 | 10 | 11 |

### redis

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-redis-1 | 6.14286 | 6 | 12 |
| single | 10 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| single | 100 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| single | 1000 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| single | 5000 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| x3 | 1 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| x3 | 10 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| x3 | 100 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| x3 | 1000 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| x3 | 5000 | book-reviews-a4-redis-1 | 6 | 6 | 6 |

### opensearch

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-opensearch-1 | 125.095 | 125 | 128 |
| single | 10 | book-reviews-a4-opensearch-1 | 127 | 127 | 127 |
| single | 100 | book-reviews-a4-opensearch-1 | 127 | 127 | 127 |
| single | 1000 | book-reviews-a4-opensearch-1 | 129 | 129 | 129 |
| single | 5000 | book-reviews-a4-opensearch-1 | 129 | 129 | 129 |
| x3 | 1 | book-reviews-a4-opensearch-1 | 129 | 129 | 129 |
| x3 | 10 | book-reviews-a4-opensearch-1 | 129 | 129 | 129 |
| x3 | 100 | book-reviews-a4-opensearch-1 | 129.051 | 129 | 131 |
| x3 | 1000 | book-reviews-a4-opensearch-1 | 129 | 129 | 129 |
| x3 | 5000 | book-reviews-a4-opensearch-1 | 131 | 131 | 131 |


# Expensive Aggregation

## Response times

| Requests | single Avg ms | single P95 ms | single P99 ms | x3 Avg ms | x3 P95 ms | x3 P99 ms |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 156.569 | 156.569 | 156.569 | 213.339 | 213.339 | 213.339 |
| 10 | 27.8482 | 71.8476 | 78.2854 | 57.2721 | 126.295 | 144.866 |
| 100 | 18.5475 | 26.1896 | 35.5765 | 20.2117 | 28.8228 | 46.1355 |
| 1000 | 16.1136 | 20.2621 | 24.9089 | 12.4606 | 16.0386 | 26.1872 |
| 5000 | 14.9284 | 19.9573 | 25.5461 | 11.3267 | 13.469 | 15.4613 |

## Requests and errors

| Requests | single Completados | single Exitosos | single Fallidos | single Error % | single req/s | x3 Completados | x3 Exitosos | x3 Fallidos | x3 Error % | x3 req/s |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 1 | 0 | 0 | 0.00333347 | 1 | 1 | 0 | 0 | 0.0033335 |
| 10 | 10 | 10 | 0 | 0 | 0.0333346 | 10 | 10 | 0 | 0 | 0.033335 |
| 100 | 100 | 100 | 0 | 0 | 0.333346 | 100 | 100 | 0 | 0 | 0.333348 |
| 1000 | 1000 | 1000 | 0 | 0 | 3.33353 | 1000 | 1000 | 0 | 0 | 3.33348 |
| 5000 | 5000 | 5000 | 0 | 0 | 16.6676 | 5000 | 5000 | 0 | 0 | 16.6674 |

## CPU

### web

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-web-1 | 0.812195 | 0.01 | 4.59 |
| single | 10 | book-reviews-a4-web-1 | 0.663571 | 0.01 | 3.31 |
| single | 100 | book-reviews-a4-web-1 | 1.183 | 0.01 | 5.48 |
| single | 1000 | book-reviews-a4-web-1 | 3.79025 | 0.01 | 8.67 |
| single | 5000 | book-reviews-a4-web-1 | 16.8215 | 0.01 | 24.08 |
| x3 | 1 | book-reviews-a4-web-1 | 0.741795 | 0 | 4.22 |
| x3 | 1 | book-reviews-a4-web-2 | 0.870256 | 0 | 5.84 |
| x3 | 1 | book-reviews-a4-web-3 | 0.44359 | 0.01 | 3.94 |
| x3 | 10 | book-reviews-a4-web-1 | 0.950513 | 0.01 | 4.47 |
| x3 | 10 | book-reviews-a4-web-2 | 1.22846 | 0.01 | 5.09 |
| x3 | 10 | book-reviews-a4-web-3 | 1.15179 | 0.01 | 10.98 |
| x3 | 100 | book-reviews-a4-web-1 | 0.96175 | 0 | 5.67 |
| x3 | 100 | book-reviews-a4-web-2 | 1.10275 | 0 | 6 |
| x3 | 100 | book-reviews-a4-web-3 | 1.1415 | 0.01 | 4.76 |
| x3 | 1000 | book-reviews-a4-web-1 | 1.41878 | 0 | 4.28 |
| x3 | 1000 | book-reviews-a4-web-2 | 1.50293 | 0.01 | 5.02 |
| x3 | 1000 | book-reviews-a4-web-3 | 1.29805 | 0.01 | 4.92 |
| x3 | 5000 | book-reviews-a4-web-1 | 4.40375 | 0.03 | 7.8 |
| x3 | 5000 | book-reviews-a4-web-2 | 4.605 | 0.22 | 7.63 |
| x3 | 5000 | book-reviews-a4-web-3 | 4.38325 | 0.24 | 7.64 |

### static

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-static-1 | 0.852439 | 0.01 | 3.43 |
| single | 10 | book-reviews-a4-static-1 | 0.918333 | 0 | 3.76 |
| single | 100 | book-reviews-a4-static-1 | 0.56975 | 0.01 | 3.49 |
| single | 1000 | book-reviews-a4-static-1 | 0.694 | 0.01 | 3.76 |
| single | 5000 | book-reviews-a4-static-1 | 1.003 | 0 | 4.78 |
| x3 | 1 | book-reviews-a4-static-1 | 0.613846 | 0.01 | 3.56 |
| x3 | 10 | book-reviews-a4-static-1 | 0.573846 | 0 | 4.28 |
| x3 | 100 | book-reviews-a4-static-1 | 0.5755 | 0.01 | 3.45 |
| x3 | 1000 | book-reviews-a4-static-1 | 0.634878 | 0 | 3.43 |
| x3 | 5000 | book-reviews-a4-static-1 | 0.472 | 0 | 2.75 |

### traefik

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-traefik-1 | 1.00122 | 0 | 6.47 |
| single | 10 | book-reviews-a4-traefik-1 | 1.18262 | 0 | 8.35 |
| single | 100 | book-reviews-a4-traefik-1 | 1.7975 | 0 | 8.49 |
| single | 1000 | book-reviews-a4-traefik-1 | 1.80325 | 0.11 | 8.93 |
| single | 5000 | book-reviews-a4-traefik-1 | 3.81425 | 0 | 12.6 |
| x3 | 1 | book-reviews-a4-traefik-1 | 1.46821 | 0 | 7.88 |
| x3 | 10 | book-reviews-a4-traefik-1 | 1.88154 | 0 | 11.53 |
| x3 | 100 | book-reviews-a4-traefik-1 | 1.85825 | 0 | 9.03 |
| x3 | 1000 | book-reviews-a4-traefik-1 | 1.48415 | 0.02 | 6.51 |
| x3 | 5000 | book-reviews-a4-traefik-1 | 3.91425 | 0.27 | 8.68 |

### db

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-db-1 | 1.64512 | 0 | 3.83 |
| single | 10 | book-reviews-a4-db-1 | 1.29024 | 0 | 3.64 |
| single | 100 | book-reviews-a4-db-1 | 1.93825 | 0 | 4.31 |
| single | 1000 | book-reviews-a4-db-1 | 2.38075 | 0.03 | 4.71 |
| single | 5000 | book-reviews-a4-db-1 | 3.66975 | 0 | 6.63 |
| x3 | 1 | book-reviews-a4-db-1 | 1.70513 | 0 | 5.3 |
| x3 | 10 | book-reviews-a4-db-1 | 0.831026 | 0 | 4.53 |
| x3 | 100 | book-reviews-a4-db-1 | 1.5555 | 0 | 4.53 |
| x3 | 1000 | book-reviews-a4-db-1 | 1.70561 | 0 | 3.93 |
| x3 | 5000 | book-reviews-a4-db-1 | 2.54 | 1.33 | 4.45 |

### redis

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-redis-1 | 0.656829 | 0.25 | 3.09 |
| single | 10 | book-reviews-a4-redis-1 | 0.705476 | 0.25 | 2.81 |
| single | 100 | book-reviews-a4-redis-1 | 0.79825 | 0.26 | 3.31 |
| single | 1000 | book-reviews-a4-redis-1 | 1.067 | 0.33 | 3.51 |
| single | 5000 | book-reviews-a4-redis-1 | 1.16125 | 0.35 | 3.67 |
| x3 | 1 | book-reviews-a4-redis-1 | 0.910513 | 0.3 | 3.45 |
| x3 | 10 | book-reviews-a4-redis-1 | 0.832564 | 0.3 | 3.66 |
| x3 | 100 | book-reviews-a4-redis-1 | 1.0215 | 0.28 | 3.22 |
| x3 | 1000 | book-reviews-a4-redis-1 | 0.711707 | 0.29 | 2.61 |
| x3 | 5000 | book-reviews-a4-redis-1 | 1.21725 | 0.28 | 3.19 |

### opensearch

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-opensearch-1 | 0.992439 | 0.61 | 4.15 |
| single | 10 | book-reviews-a4-opensearch-1 | 0.874286 | 0.5 | 3.45 |
| single | 100 | book-reviews-a4-opensearch-1 | 4.5515 | 0.55 | 137.25 |
| single | 1000 | book-reviews-a4-opensearch-1 | 1.20975 | 0.6 | 4.81 |
| single | 5000 | book-reviews-a4-opensearch-1 | 1.08025 | 0.57 | 4.71 |
| x3 | 1 | book-reviews-a4-opensearch-1 | 1.43564 | 0.58 | 6.71 |
| x3 | 10 | book-reviews-a4-opensearch-1 | 2.25077 | 0.6 | 36.3 |
| x3 | 100 | book-reviews-a4-opensearch-1 | 0.878 | 0.58 | 5.24 |
| x3 | 1000 | book-reviews-a4-opensearch-1 | 2.15 | 0.49 | 55.25 |
| x3 | 5000 | book-reviews-a4-opensearch-1 | 0.7865 | 0.43 | 3.68 |

## Memory

### web

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-web-1 | 112.968 | 108.4 | 118.9 |
| single | 10 | book-reviews-a4-web-1 | 118.648 | 115.7 | 124.3 |
| single | 100 | book-reviews-a4-web-1 | 122.545 | 119.1 | 125.2 |
| single | 1000 | book-reviews-a4-web-1 | 130.458 | 125.2 | 133.3 |
| single | 5000 | book-reviews-a4-web-1 | 136.597 | 133.6 | 140.3 |
| x3 | 1 | book-reviews-a4-web-1 | 113.077 | 109.7 | 117.6 |
| x3 | 1 | book-reviews-a4-web-2 | 109.526 | 108.7 | 113.8 |
| x3 | 1 | book-reviews-a4-web-3 | 109.641 | 109 | 110.4 |
| x3 | 10 | book-reviews-a4-web-1 | 115.467 | 113.3 | 117 |
| x3 | 10 | book-reviews-a4-web-2 | 115.451 | 113.1 | 117.3 |
| x3 | 10 | book-reviews-a4-web-3 | 116.11 | 113.5 | 117.7 |
| x3 | 100 | book-reviews-a4-web-1 | 121.24 | 117.9 | 123.3 |
| x3 | 100 | book-reviews-a4-web-2 | 121.043 | 117.9 | 122.7 |
| x3 | 100 | book-reviews-a4-web-3 | 121.34 | 118.4 | 122.9 |
| x3 | 1000 | book-reviews-a4-web-1 | 125.644 | 122.9 | 131.4 |
| x3 | 1000 | book-reviews-a4-web-2 | 125.495 | 122.2 | 126.8 |
| x3 | 1000 | book-reviews-a4-web-3 | 124.985 | 121.9 | 126.2 |
| x3 | 5000 | book-reviews-a4-web-1 | 129.98 | 128.3 | 131.4 |
| x3 | 5000 | book-reviews-a4-web-2 | 130.838 | 129 | 135.6 |
| x3 | 5000 | book-reviews-a4-web-3 | 130.09 | 128.1 | 135 |

### static

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-static-1 | 24.6017 | 23.53 | 28.49 |
| single | 10 | book-reviews-a4-static-1 | 27.0807 | 25.89 | 31.65 |
| single | 100 | book-reviews-a4-static-1 | 28.1423 | 27 | 31.92 |
| single | 1000 | book-reviews-a4-static-1 | 28.886 | 28.24 | 29.82 |
| single | 5000 | book-reviews-a4-static-1 | 29.3813 | 28.58 | 30.26 |
| x3 | 1 | book-reviews-a4-static-1 | 30.0323 | 29.37 | 30.96 |
| x3 | 10 | book-reviews-a4-static-1 | 31.0831 | 30.21 | 35.76 |
| x3 | 100 | book-reviews-a4-static-1 | 30.7862 | 30.1 | 31.87 |
| x3 | 1000 | book-reviews-a4-static-1 | 30.1144 | 29.64 | 31.4 |
| x3 | 5000 | book-reviews-a4-static-1 | 30.1687 | 29.77 | 37.45 |

### traefik

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-traefik-1 | 113.91 | 113.2 | 114.7 |
| single | 10 | book-reviews-a4-traefik-1 | 115.338 | 114.1 | 126.6 |
| single | 100 | book-reviews-a4-traefik-1 | 117.938 | 115.9 | 127.9 |
| single | 1000 | book-reviews-a4-traefik-1 | 119.645 | 117.8 | 120.9 |
| single | 5000 | book-reviews-a4-traefik-1 | 121.343 | 119.7 | 122.2 |
| x3 | 1 | book-reviews-a4-traefik-1 | 119.41 | 118.5 | 121 |
| x3 | 10 | book-reviews-a4-traefik-1 | 120.154 | 119.1 | 121.1 |
| x3 | 100 | book-reviews-a4-traefik-1 | 121.562 | 119.5 | 123 |
| x3 | 1000 | book-reviews-a4-traefik-1 | 122.929 | 120.5 | 123.9 |
| x3 | 5000 | book-reviews-a4-traefik-1 | 124.275 | 121.4 | 140.4 |

### db

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-db-1 | 49.4744 | 48.07 | 53.35 |
| single | 10 | book-reviews-a4-db-1 | 49.1529 | 48.43 | 50.04 |
| single | 100 | book-reviews-a4-db-1 | 49.2938 | 48.58 | 50.04 |
| single | 1000 | book-reviews-a4-db-1 | 51.5307 | 49.04 | 56.52 |
| single | 5000 | book-reviews-a4-db-1 | 51.5553 | 49.09 | 52.28 |
| x3 | 1 | book-reviews-a4-db-1 | 52.9146 | 52.18 | 53.98 |
| x3 | 10 | book-reviews-a4-db-1 | 54.1782 | 52.48 | 59.11 |
| x3 | 100 | book-reviews-a4-db-1 | 55.1197 | 52.89 | 58.93 |
| x3 | 1000 | book-reviews-a4-db-1 | 56.3834 | 53.57 | 62.98 |
| x3 | 5000 | book-reviews-a4-db-1 | 56.6225 | 54.43 | 60.99 |

### redis

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-redis-1 | 8.36946 | 7.176 | 9.102 |
| single | 10 | book-reviews-a4-redis-1 | 8.4756 | 7.551 | 9.406 |
| single | 100 | book-reviews-a4-redis-1 | 9.3511 | 7.848 | 10.63 |
| single | 1000 | book-reviews-a4-redis-1 | 10.4987 | 9.516 | 14.84 |
| single | 5000 | book-reviews-a4-redis-1 | 11.9817 | 10.66 | 16.85 |
| x3 | 1 | book-reviews-a4-redis-1 | 15.3279 | 14.62 | 15.91 |
| x3 | 10 | book-reviews-a4-redis-1 | 15.2897 | 14.65 | 16.01 |
| x3 | 100 | book-reviews-a4-redis-1 | 15.591 | 14.73 | 19.9 |
| x3 | 1000 | book-reviews-a4-redis-1 | 15.8624 | 14.93 | 16.62 |
| x3 | 5000 | book-reviews-a4-redis-1 | 17.498 | 15.52 | 20.5 |

### opensearch

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-opensearch-1 | 1472.06 | 1470.46 | 1472.51 |
| single | 10 | book-reviews-a4-opensearch-1 | 1471.68 | 1470.46 | 1472.51 |
| single | 100 | book-reviews-a4-opensearch-1 | 1474.1 | 1473.54 | 1477.63 |
| single | 1000 | book-reviews-a4-opensearch-1 | 1472.26 | 1471.49 | 1476.61 |
| single | 5000 | book-reviews-a4-opensearch-1 | 1483.78 | 1482.75 | 1484.8 |
| x3 | 1 | book-reviews-a4-opensearch-1 | 1498.24 | 1498.11 | 1499.14 |
| x3 | 10 | book-reviews-a4-opensearch-1 | 1524.42 | 1500.16 | 1534.98 |
| x3 | 100 | book-reviews-a4-opensearch-1 | 1523.66 | 1522.69 | 1524.74 |
| x3 | 1000 | book-reviews-a4-opensearch-1 | 1523.64 | 1498.11 | 1529.86 |
| x3 | 5000 | book-reviews-a4-opensearch-1 | 1493.22 | 1492.99 | 1494.02 |

## Threads

### web

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-web-1 | 10.1707 | 10 | 16 |
| single | 10 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| single | 100 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| single | 1000 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| single | 5000 | book-reviews-a4-web-1 | 11.025 | 11 | 12 |
| x3 | 1 | book-reviews-a4-web-1 | 10 | 10 | 10 |
| x3 | 1 | book-reviews-a4-web-2 | 10.0513 | 10 | 12 |
| x3 | 1 | book-reviews-a4-web-3 | 10 | 10 | 10 |
| x3 | 10 | book-reviews-a4-web-1 | 10 | 10 | 10 |
| x3 | 10 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 10 | book-reviews-a4-web-3 | 10 | 10 | 10 |
| x3 | 100 | book-reviews-a4-web-1 | 11.15 | 11 | 17 |
| x3 | 100 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 100 | book-reviews-a4-web-3 | 11 | 11 | 11 |
| x3 | 1000 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| x3 | 1000 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 1000 | book-reviews-a4-web-3 | 11 | 11 | 11 |
| x3 | 5000 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| x3 | 5000 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 5000 | book-reviews-a4-web-3 | 11 | 11 | 11 |

### static

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| single | 10 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| single | 100 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| single | 1000 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| single | 5000 | book-reviews-a4-static-1 | 9.15 | 9 | 15 |
| x3 | 1 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| x3 | 10 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| x3 | 100 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| x3 | 1000 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| x3 | 5000 | book-reviews-a4-static-1 | 9 | 9 | 9 |

### traefik

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-traefik-1 | 17.1707 | 17 | 23 |
| single | 10 | book-reviews-a4-traefik-1 | 17 | 17 | 17 |
| single | 100 | book-reviews-a4-traefik-1 | 17 | 17 | 17 |
| single | 1000 | book-reviews-a4-traefik-1 | 17 | 17 | 17 |
| single | 5000 | book-reviews-a4-traefik-1 | 17.05 | 17 | 19 |
| x3 | 1 | book-reviews-a4-traefik-1 | 18 | 18 | 18 |
| x3 | 10 | book-reviews-a4-traefik-1 | 18 | 18 | 18 |
| x3 | 100 | book-reviews-a4-traefik-1 | 18 | 18 | 18 |
| x3 | 1000 | book-reviews-a4-traefik-1 | 18 | 18 | 18 |
| x3 | 5000 | book-reviews-a4-traefik-1 | 18.275 | 18 | 29 |

### db

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-db-1 | 7.14634 | 7 | 13 |
| single | 10 | book-reviews-a4-db-1 | 7.28571 | 7 | 13 |
| single | 100 | book-reviews-a4-db-1 | 7.15 | 7 | 13 |
| single | 1000 | book-reviews-a4-db-1 | 7.8 | 7 | 14 |
| single | 5000 | book-reviews-a4-db-1 | 7.975 | 7 | 9 |
| x3 | 1 | book-reviews-a4-db-1 | 9 | 9 | 9 |
| x3 | 10 | book-reviews-a4-db-1 | 9.15385 | 9 | 15 |
| x3 | 100 | book-reviews-a4-db-1 | 9.425 | 9 | 10 |
| x3 | 1000 | book-reviews-a4-db-1 | 10.2683 | 9 | 15 |
| x3 | 5000 | book-reviews-a4-db-1 | 9.925 | 9 | 11 |

### redis

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| single | 10 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| single | 100 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| single | 1000 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| single | 5000 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| x3 | 1 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| x3 | 10 | book-reviews-a4-redis-1 | 6.15385 | 6 | 12 |
| x3 | 100 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| x3 | 1000 | book-reviews-a4-redis-1 | 6.14634 | 6 | 12 |
| x3 | 5000 | book-reviews-a4-redis-1 | 6 | 6 | 6 |

### opensearch

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-opensearch-1 | 125 | 125 | 125 |
| single | 10 | book-reviews-a4-opensearch-1 | 127 | 127 | 127 |
| single | 100 | book-reviews-a4-opensearch-1 | 128.6 | 127 | 129 |
| single | 1000 | book-reviews-a4-opensearch-1 | 129 | 129 | 129 |
| single | 5000 | book-reviews-a4-opensearch-1 | 129 | 129 | 129 |
| x3 | 1 | book-reviews-a4-opensearch-1 | 129 | 129 | 129 |
| x3 | 10 | book-reviews-a4-opensearch-1 | 129.051 | 129 | 131 |
| x3 | 100 | book-reviews-a4-opensearch-1 | 129 | 129 | 129 |
| x3 | 1000 | book-reviews-a4-opensearch-1 | 130.707 | 129 | 137 |
| x3 | 5000 | book-reviews-a4-opensearch-1 | 131 | 131 | 131 |


# Search

## Response times

| Requests | single Avg ms | single P95 ms | single P99 ms | x3 Avg ms | x3 P95 ms | x3 P99 ms |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 119.888 | 119.888 | 119.888 | 182.865 | 182.865 | 182.865 |
| 10 | 30.2575 | 41.9156 | 48.0663 | 35.2302 | 84.1633 | 98.5179 |
| 100 | 25.7367 | 41.2442 | 51.573 | 19.9932 | 32.8104 | 55.3613 |
| 1000 | 17.4908 | 21.7848 | 26.269 | 11.888 | 13.7221 | 22.6221 |
| 5000 | 15.1584 | 18.8361 | 25.4553 | 11.2796 | 12.9533 | 14.6828 |

## Requests and errors

| Requests | single Completados | single Exitosos | single Fallidos | single Error % | single req/s | x3 Completados | x3 Exitosos | x3 Fallidos | x3 Error % | x3 req/s |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 1 | 0 | 0 | 0.00333346 | 1 | 1 | 0 | 0 | 0.0033335 |
| 10 | 10 | 10 | 0 | 0 | 0.0333347 | 10 | 10 | 0 | 0 | 0.033335 |
| 100 | 100 | 100 | 0 | 0 | 0.333345 | 100 | 100 | 0 | 0 | 0.333349 |
| 1000 | 1000 | 1000 | 0 | 0 | 3.33351 | 1000 | 1000 | 0 | 0 | 3.33348 |
| 5000 | 5000 | 5000 | 0 | 0 | 16.6676 | 5000 | 5000 | 0 | 0 | 16.6673 |

## CPU

### web

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-web-1 | 0.728049 | 0.01 | 4.12 |
| single | 10 | book-reviews-a4-web-1 | 0.596829 | 0.01 | 3.69 |
| single | 100 | book-reviews-a4-web-1 | 1.3605 | 0.01 | 15.83 |
| single | 1000 | book-reviews-a4-web-1 | 3.375 | 0.02 | 7.05 |
| single | 5000 | book-reviews-a4-web-1 | 12.8005 | 0.02 | 17.73 |
| x3 | 1 | book-reviews-a4-web-1 | 0.947179 | 0.01 | 4.6 |
| x3 | 1 | book-reviews-a4-web-2 | 0.824359 | 0.01 | 6.13 |
| x3 | 1 | book-reviews-a4-web-3 | 0.942308 | 0.01 | 4.19 |
| x3 | 10 | book-reviews-a4-web-1 | 0.55641 | 0.01 | 8.78 |
| x3 | 10 | book-reviews-a4-web-2 | 0.737692 | 0.01 | 3.99 |
| x3 | 10 | book-reviews-a4-web-3 | 0.877179 | 0.01 | 3.99 |
| x3 | 100 | book-reviews-a4-web-1 | 0.980256 | 0 | 4.15 |
| x3 | 100 | book-reviews-a4-web-2 | 0.863846 | 0 | 3.89 |
| x3 | 100 | book-reviews-a4-web-3 | 0.93641 | 0.01 | 5.85 |
| x3 | 1000 | book-reviews-a4-web-1 | 1.22951 | 0.01 | 4.58 |
| x3 | 1000 | book-reviews-a4-web-2 | 1.10073 | 0 | 4.14 |
| x3 | 1000 | book-reviews-a4-web-3 | 1.51512 | 0.01 | 4.03 |
| x3 | 5000 | book-reviews-a4-web-1 | 3.8875 | 0.02 | 6.71 |
| x3 | 5000 | book-reviews-a4-web-2 | 4.001 | 0.28 | 7.21 |
| x3 | 5000 | book-reviews-a4-web-3 | 3.8015 | 0.01 | 6.51 |

### static

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-static-1 | 0.496585 | 0.01 | 4.78 |
| single | 10 | book-reviews-a4-static-1 | 0.777317 | 0 | 3.94 |
| single | 100 | book-reviews-a4-static-1 | 0.8835 | 0.01 | 3.65 |
| single | 1000 | book-reviews-a4-static-1 | 0.68975 | 0 | 3.58 |
| single | 5000 | book-reviews-a4-static-1 | 0.83575 | 0.01 | 3.9 |
| x3 | 1 | book-reviews-a4-static-1 | 0.629487 | 0.01 | 3.49 |
| x3 | 10 | book-reviews-a4-static-1 | 0.760769 | 0.01 | 3.43 |
| x3 | 100 | book-reviews-a4-static-1 | 0.739744 | 0.01 | 4.2 |
| x3 | 1000 | book-reviews-a4-static-1 | 0.54 | 0 | 2.93 |
| x3 | 5000 | book-reviews-a4-static-1 | 0.58125 | 0 | 3.39 |

### traefik

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-traefik-1 | 1.20951 | 0 | 6.58 |
| single | 10 | book-reviews-a4-traefik-1 | 1.6161 | 0 | 19.51 |
| single | 100 | book-reviews-a4-traefik-1 | 1.793 | 0 | 9.95 |
| single | 1000 | book-reviews-a4-traefik-1 | 1.75925 | 0.07 | 8.76 |
| single | 5000 | book-reviews-a4-traefik-1 | 4.37 | 0.06 | 10.96 |
| x3 | 1 | book-reviews-a4-traefik-1 | 1.47974 | 0 | 10.45 |
| x3 | 10 | book-reviews-a4-traefik-1 | 1.91308 | 0 | 8.41 |
| x3 | 100 | book-reviews-a4-traefik-1 | 1.98205 | 0 | 8.12 |
| x3 | 1000 | book-reviews-a4-traefik-1 | 1.79732 | 0.34 | 7.32 |
| x3 | 5000 | book-reviews-a4-traefik-1 | 4.203 | 0.22 | 9.46 |

### db

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-db-1 | 1.6261 | 0 | 10.53 |
| single | 10 | book-reviews-a4-db-1 | 1.62366 | 0 | 3.82 |
| single | 100 | book-reviews-a4-db-1 | 1.66475 | 0 | 4.58 |
| single | 1000 | book-reviews-a4-db-1 | 1.58925 | 0.03 | 5.06 |
| single | 5000 | book-reviews-a4-db-1 | 2.83675 | 0.03 | 5.57 |
| x3 | 1 | book-reviews-a4-db-1 | 0.85 | 0 | 4.31 |
| x3 | 10 | book-reviews-a4-db-1 | 1.25256 | 0 | 3.81 |
| x3 | 100 | book-reviews-a4-db-1 | 1.95872 | 0 | 5.48 |
| x3 | 1000 | book-reviews-a4-db-1 | 1.64244 | 0 | 3.4 |
| x3 | 5000 | book-reviews-a4-db-1 | 2.14675 | 0.08 | 3.82 |

### redis

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-redis-1 | 0.90122 | 0.25 | 3.17 |
| single | 10 | book-reviews-a4-redis-1 | 0.871707 | 0.26 | 3.44 |
| single | 100 | book-reviews-a4-redis-1 | 0.9005 | 0.27 | 3.76 |
| single | 1000 | book-reviews-a4-redis-1 | 0.8925 | 0.34 | 3.47 |
| single | 5000 | book-reviews-a4-redis-1 | 0.866 | 0.33 | 3.83 |
| x3 | 1 | book-reviews-a4-redis-1 | 0.908718 | 0.28 | 4.1 |
| x3 | 10 | book-reviews-a4-redis-1 | 0.782051 | 0.31 | 3.22 |
| x3 | 100 | book-reviews-a4-redis-1 | 0.826667 | 0.29 | 3.14 |
| x3 | 1000 | book-reviews-a4-redis-1 | 0.843415 | 0.29 | 2.78 |
| x3 | 5000 | book-reviews-a4-redis-1 | 0.8475 | 0.28 | 2.88 |

### opensearch

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-opensearch-1 | 1.15707 | 0.56 | 5.31 |
| single | 10 | book-reviews-a4-opensearch-1 | 1.09927 | 0.54 | 4.2 |
| single | 100 | book-reviews-a4-opensearch-1 | 1.59025 | 0.59 | 7.92 |
| single | 1000 | book-reviews-a4-opensearch-1 | 5.29375 | 0.69 | 24.59 |
| single | 5000 | book-reviews-a4-opensearch-1 | 8.654 | 0.66 | 27.8 |
| x3 | 1 | book-reviews-a4-opensearch-1 | 1.11 | 0.61 | 5.64 |
| x3 | 10 | book-reviews-a4-opensearch-1 | 1.34846 | 0.59 | 5.8 |
| x3 | 100 | book-reviews-a4-opensearch-1 | 2.0859 | 0.57 | 23.1 |
| x3 | 1000 | book-reviews-a4-opensearch-1 | 2.23683 | 0.49 | 13.59 |
| x3 | 5000 | book-reviews-a4-opensearch-1 | 4.15625 | 0.56 | 10.1 |

## Memory

### web

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-web-1 | 114.405 | 112.4 | 119.9 |
| single | 10 | book-reviews-a4-web-1 | 118.534 | 117.6 | 123.2 |
| single | 100 | book-reviews-a4-web-1 | 123.795 | 122.7 | 128.6 |
| single | 1000 | book-reviews-a4-web-1 | 132.037 | 131.4 | 133.5 |
| single | 5000 | book-reviews-a4-web-1 | 135.583 | 134.8 | 136.6 |
| x3 | 1 | book-reviews-a4-web-1 | 113.11 | 112.3 | 114 |
| x3 | 1 | book-reviews-a4-web-2 | 111.885 | 110.1 | 112.7 |
| x3 | 1 | book-reviews-a4-web-3 | 110.405 | 109.3 | 116.4 |
| x3 | 10 | book-reviews-a4-web-1 | 116.326 | 115.7 | 117.2 |
| x3 | 10 | book-reviews-a4-web-2 | 116.226 | 115.2 | 117 |
| x3 | 10 | book-reviews-a4-web-3 | 117.487 | 116.5 | 118.9 |
| x3 | 100 | book-reviews-a4-web-1 | 121.056 | 120.1 | 122.2 |
| x3 | 100 | book-reviews-a4-web-2 | 120.787 | 119.4 | 124.7 |
| x3 | 100 | book-reviews-a4-web-3 | 120.741 | 119.3 | 125.8 |
| x3 | 1000 | book-reviews-a4-web-1 | 126.78 | 124.3 | 131.6 |
| x3 | 1000 | book-reviews-a4-web-2 | 127.171 | 125.7 | 131.5 |
| x3 | 1000 | book-reviews-a4-web-3 | 126.722 | 125 | 133.2 |
| x3 | 5000 | book-reviews-a4-web-1 | 129.567 | 128.5 | 133.7 |
| x3 | 5000 | book-reviews-a4-web-2 | 130.185 | 129 | 130.9 |
| x3 | 5000 | book-reviews-a4-web-3 | 129.285 | 128.3 | 131.2 |

### static

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-static-1 | 24.811 | 23.55 | 26.49 |
| single | 10 | book-reviews-a4-static-1 | 27.0761 | 26.49 | 27.97 |
| single | 100 | book-reviews-a4-static-1 | 28.2907 | 27.01 | 32.43 |
| single | 1000 | book-reviews-a4-static-1 | 28.906 | 28.12 | 29.84 |
| single | 5000 | book-reviews-a4-static-1 | 29.509 | 28.68 | 34.2 |
| x3 | 1 | book-reviews-a4-static-1 | 30.1623 | 29.23 | 31.42 |
| x3 | 10 | book-reviews-a4-static-1 | 31.0359 | 30.22 | 31.81 |
| x3 | 100 | book-reviews-a4-static-1 | 30.9367 | 30.12 | 32.06 |
| x3 | 1000 | book-reviews-a4-static-1 | 30.2237 | 29.79 | 31.14 |
| x3 | 5000 | book-reviews-a4-static-1 | 30.1052 | 29.9 | 31.11 |

### traefik

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-traefik-1 | 114.102 | 113.2 | 123.9 |
| single | 10 | book-reviews-a4-traefik-1 | 115.849 | 114.7 | 126.7 |
| single | 100 | book-reviews-a4-traefik-1 | 117.715 | 117 | 119 |
| single | 1000 | book-reviews-a4-traefik-1 | 120.02 | 118.1 | 129.1 |
| single | 5000 | book-reviews-a4-traefik-1 | 121.86 | 119 | 133.4 |
| x3 | 1 | book-reviews-a4-traefik-1 | 119.487 | 118.5 | 120.5 |
| x3 | 10 | book-reviews-a4-traefik-1 | 120.415 | 118.9 | 136.2 |
| x3 | 100 | book-reviews-a4-traefik-1 | 121.826 | 120 | 132.3 |
| x3 | 1000 | book-reviews-a4-traefik-1 | 122.995 | 120.9 | 133 |
| x3 | 5000 | book-reviews-a4-traefik-1 | 124.255 | 121.6 | 135.3 |

### db

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-db-1 | 49.5095 | 48.63 | 54.91 |
| single | 10 | book-reviews-a4-db-1 | 49.309 | 47.98 | 54.11 |
| single | 100 | book-reviews-a4-db-1 | 49.8477 | 48.97 | 55.39 |
| single | 1000 | book-reviews-a4-db-1 | 52.012 | 51.16 | 52.58 |
| single | 5000 | book-reviews-a4-db-1 | 51.7335 | 50.37 | 56.59 |
| x3 | 1 | book-reviews-a4-db-1 | 53.2551 | 52.07 | 53.75 |
| x3 | 10 | book-reviews-a4-db-1 | 54.5297 | 53.37 | 59.39 |
| x3 | 100 | book-reviews-a4-db-1 | 54.4515 | 53.16 | 58.84 |
| x3 | 1000 | book-reviews-a4-db-1 | 55.9151 | 52.86 | 62.23 |
| x3 | 5000 | book-reviews-a4-db-1 | 55.1303 | 53.68 | 58.8 |

### redis

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-redis-1 | 8.55044 | 7.68 | 9.188 |
| single | 10 | book-reviews-a4-redis-1 | 8.48088 | 7.941 | 9.129 |
| single | 100 | book-reviews-a4-redis-1 | 9.97225 | 9.418 | 10.59 |
| single | 1000 | book-reviews-a4-redis-1 | 10.5326 | 9.594 | 11.14 |
| single | 5000 | book-reviews-a4-redis-1 | 13.4025 | 11.95 | 14.87 |
| x3 | 1 | book-reviews-a4-redis-1 | 15.38 | 14.82 | 15.94 |
| x3 | 10 | book-reviews-a4-redis-1 | 15.4946 | 14.77 | 16.27 |
| x3 | 100 | book-reviews-a4-redis-1 | 15.3679 | 14.71 | 16.32 |
| x3 | 1000 | book-reviews-a4-redis-1 | 16.0551 | 15.21 | 20.56 |
| x3 | 5000 | book-reviews-a4-redis-1 | 18.5733 | 17.43 | 19.48 |

### opensearch

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-opensearch-1 | 1475.03 | 1471.49 | 1476.61 |
| single | 10 | book-reviews-a4-opensearch-1 | 1471.59 | 1470.46 | 1474.56 |
| single | 100 | book-reviews-a4-opensearch-1 | 1473.36 | 1472.51 | 1474.56 |
| single | 1000 | book-reviews-a4-opensearch-1 | 1478.04 | 1472.51 | 1483.78 |
| single | 5000 | book-reviews-a4-opensearch-1 | 1493.4 | 1472.51 | 1533.95 |
| x3 | 1 | book-reviews-a4-opensearch-1 | 1517.41 | 1498.11 | 1533.95 |
| x3 | 10 | book-reviews-a4-opensearch-1 | 1526.65 | 1524.74 | 1531.9 |
| x3 | 100 | book-reviews-a4-opensearch-1 | 1521.14 | 1517.57 | 1524.74 |
| x3 | 1000 | book-reviews-a4-opensearch-1 | 1504.91 | 1494.02 | 1536 |
| x3 | 5000 | book-reviews-a4-opensearch-1 | 1518.23 | 1492.99 | 1536 |

## Threads

### web

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-web-1 | 10.9756 | 10 | 11 |
| single | 10 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| single | 100 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| single | 1000 | book-reviews-a4-web-1 | 11.15 | 11 | 17 |
| single | 5000 | book-reviews-a4-web-1 | 11.05 | 11 | 12 |
| x3 | 1 | book-reviews-a4-web-1 | 10.1538 | 10 | 16 |
| x3 | 1 | book-reviews-a4-web-2 | 10.9744 | 10 | 11 |
| x3 | 1 | book-reviews-a4-web-3 | 10 | 10 | 10 |
| x3 | 10 | book-reviews-a4-web-1 | 10.8974 | 10 | 11 |
| x3 | 10 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 10 | book-reviews-a4-web-3 | 11.1282 | 10 | 17 |
| x3 | 100 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| x3 | 100 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 100 | book-reviews-a4-web-3 | 11 | 11 | 11 |
| x3 | 1000 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| x3 | 1000 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 1000 | book-reviews-a4-web-3 | 11 | 11 | 11 |
| x3 | 5000 | book-reviews-a4-web-1 | 11.175 | 11 | 17 |
| x3 | 5000 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 5000 | book-reviews-a4-web-3 | 11 | 11 | 11 |

### static

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| single | 10 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| single | 100 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| single | 1000 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| single | 5000 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| x3 | 1 | book-reviews-a4-static-1 | 9.15385 | 9 | 15 |
| x3 | 10 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| x3 | 100 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| x3 | 1000 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| x3 | 5000 | book-reviews-a4-static-1 | 9 | 9 | 9 |

### traefik

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-traefik-1 | 17 | 17 | 17 |
| single | 10 | book-reviews-a4-traefik-1 | 17.1463 | 17 | 23 |
| single | 100 | book-reviews-a4-traefik-1 | 17.225 | 17 | 26 |
| single | 1000 | book-reviews-a4-traefik-1 | 17 | 17 | 17 |
| single | 5000 | book-reviews-a4-traefik-1 | 17 | 17 | 17 |
| x3 | 1 | book-reviews-a4-traefik-1 | 18 | 18 | 18 |
| x3 | 10 | book-reviews-a4-traefik-1 | 18.2564 | 18 | 28 |
| x3 | 100 | book-reviews-a4-traefik-1 | 18.3333 | 18 | 25 |
| x3 | 1000 | book-reviews-a4-traefik-1 | 18 | 18 | 18 |
| x3 | 5000 | book-reviews-a4-traefik-1 | 18.125 | 18 | 23 |

### db

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-db-1 | 7 | 7 | 7 |
| single | 10 | book-reviews-a4-db-1 | 7.14634 | 7 | 13 |
| single | 100 | book-reviews-a4-db-1 | 7 | 7 | 7 |
| single | 1000 | book-reviews-a4-db-1 | 8.15 | 8 | 14 |
| single | 5000 | book-reviews-a4-db-1 | 8 | 8 | 8 |
| x3 | 1 | book-reviews-a4-db-1 | 9.02564 | 9 | 10 |
| x3 | 10 | book-reviews-a4-db-1 | 9.15385 | 9 | 10 |
| x3 | 100 | book-reviews-a4-db-1 | 9.20513 | 9 | 10 |
| x3 | 1000 | book-reviews-a4-db-1 | 9.90244 | 9 | 11 |
| x3 | 5000 | book-reviews-a4-db-1 | 9.175 | 9 | 10 |

### redis

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| single | 10 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| single | 100 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| single | 1000 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| single | 5000 | book-reviews-a4-redis-1 | 6.15 | 6 | 12 |
| x3 | 1 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| x3 | 10 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| x3 | 100 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| x3 | 1000 | book-reviews-a4-redis-1 | 6.14634 | 6 | 12 |
| x3 | 5000 | book-reviews-a4-redis-1 | 6 | 6 | 6 |

### opensearch

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-opensearch-1 | 126.976 | 125 | 128 |
| single | 10 | book-reviews-a4-opensearch-1 | 127 | 127 | 127 |
| single | 100 | book-reviews-a4-opensearch-1 | 129 | 129 | 129 |
| single | 1000 | book-reviews-a4-opensearch-1 | 129 | 129 | 129 |
| single | 5000 | book-reviews-a4-opensearch-1 | 129.125 | 129 | 131 |
| x3 | 1 | book-reviews-a4-opensearch-1 | 129 | 129 | 129 |
| x3 | 10 | book-reviews-a4-opensearch-1 | 129.026 | 129 | 130 |
| x3 | 100 | book-reviews-a4-opensearch-1 | 129.026 | 129 | 130 |
| x3 | 1000 | book-reviews-a4-opensearch-1 | 131.049 | 131 | 133 |
| x3 | 5000 | book-reviews-a4-opensearch-1 | 131.35 | 131 | 133 |


# Cheap Dynamic Read

## Response times

| Requests | single Avg ms | single P95 ms | single P99 ms | x3 Avg ms | x3 P95 ms | x3 P99 ms |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 178.367 | 178.367 | 178.367 | 223.536 | 223.536 | 223.536 |
| 10 | 25.3108 | 59.3906 | 79.1833 | 64.3926 | 185.728 | 194.837 |
| 100 | 15.5167 | 25.0519 | 33.6473 | 16.7157 | 27.3601 | 45.9083 |
| 1000 | 11.231 | 13.6233 | 18.5688 | 8.90968 | 10.3933 | 17.826 |
| 5000 | 10.5441 | 12.7211 | 16.4423 | 8.96435 | 10.5911 | 13.6326 |

## Requests and errors

| Requests | single Completados | single Exitosos | single Fallidos | single Error % | single req/s | x3 Completados | x3 Exitosos | x3 Fallidos | x3 Error % | x3 req/s |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 1 | 0 | 0 | 0.00333346 | 1 | 1 | 0 | 0 | 0.00333352 |
| 10 | 10 | 10 | 0 | 0 | 0.0333346 | 10 | 10 | 0 | 0 | 0.033335 |
| 100 | 100 | 100 | 0 | 0 | 0.333345 | 100 | 100 | 0 | 0 | 0.333349 |
| 1000 | 1000 | 1000 | 0 | 0 | 3.33351 | 1000 | 1000 | 0 | 0 | 3.33349 |
| 5000 | 5000 | 5000 | 0 | 0 | 16.6675 | 5000 | 5000 | 0 | 0 | 16.6673 |

## CPU

### web

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-web-1 | 0.98 | 0.01 | 5.31 |
| single | 10 | book-reviews-a4-web-1 | 0.960732 | 0.01 | 3.68 |
| single | 100 | book-reviews-a4-web-1 | 1.26375 | 0.01 | 5.99 |
| single | 1000 | book-reviews-a4-web-1 | 2.97575 | 0.01 | 6.96 |
| single | 5000 | book-reviews-a4-web-1 | 10.3935 | 0.01 | 14.45 |
| x3 | 1 | book-reviews-a4-web-1 | 0.902821 | 0.01 | 4.21 |
| x3 | 1 | book-reviews-a4-web-2 | 0.666667 | 0 | 4.62 |
| x3 | 1 | book-reviews-a4-web-3 | 0.54641 | 0.01 | 3.9 |
| x3 | 10 | book-reviews-a4-web-1 | 0.967436 | 0 | 4.95 |
| x3 | 10 | book-reviews-a4-web-2 | 0.624872 | 0 | 3.78 |
| x3 | 10 | book-reviews-a4-web-3 | 0.841282 | 0 | 4.15 |
| x3 | 100 | book-reviews-a4-web-1 | 1.11615 | 0.01 | 4.69 |
| x3 | 100 | book-reviews-a4-web-2 | 1.01359 | 0 | 5.38 |
| x3 | 100 | book-reviews-a4-web-3 | 0.796923 | 0.01 | 4.75 |
| x3 | 1000 | book-reviews-a4-web-1 | 1.213 | 0.01 | 3.86 |
| x3 | 1000 | book-reviews-a4-web-2 | 1.1555 | 0.01 | 4.17 |
| x3 | 1000 | book-reviews-a4-web-3 | 1.21875 | 0.01 | 4.07 |
| x3 | 5000 | book-reviews-a4-web-1 | 3.49366 | 0.01 | 6.26 |
| x3 | 5000 | book-reviews-a4-web-2 | 3.25146 | 0.01 | 6.16 |
| x3 | 5000 | book-reviews-a4-web-3 | 3.21146 | 0.01 | 6.64 |

### static

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-static-1 | 0.518293 | 0.01 | 3.27 |
| single | 10 | book-reviews-a4-static-1 | 0.618537 | 0.01 | 3.77 |
| single | 100 | book-reviews-a4-static-1 | 0.612 | 0.01 | 3.69 |
| single | 1000 | book-reviews-a4-static-1 | 0.84825 | 0.01 | 4.31 |
| single | 5000 | book-reviews-a4-static-1 | 0.694 | 0 | 3.72 |
| x3 | 1 | book-reviews-a4-static-1 | 0.893333 | 0.01 | 3.84 |
| x3 | 10 | book-reviews-a4-static-1 | 0.64641 | 0.01 | 3.76 |
| x3 | 100 | book-reviews-a4-static-1 | 0.814359 | 0.01 | 4.44 |
| x3 | 1000 | book-reviews-a4-static-1 | 0.67325 | 0.01 | 2.94 |
| x3 | 5000 | book-reviews-a4-static-1 | 0.607805 | 0 | 3.07 |

### traefik

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-traefik-1 | 1.42244 | 0 | 7.11 |
| single | 10 | book-reviews-a4-traefik-1 | 1.39 | 0 | 7.74 |
| single | 100 | book-reviews-a4-traefik-1 | 1.59375 | 0 | 9.54 |
| single | 1000 | book-reviews-a4-traefik-1 | 1.79475 | 0.03 | 9.18 |
| single | 5000 | book-reviews-a4-traefik-1 | 4.0545 | 0 | 10.19 |
| x3 | 1 | book-reviews-a4-traefik-1 | 1.52333 | 0 | 8.24 |
| x3 | 10 | book-reviews-a4-traefik-1 | 0.921282 | 0 | 7.7 |
| x3 | 100 | book-reviews-a4-traefik-1 | 2.26744 | 0 | 9.87 |
| x3 | 1000 | book-reviews-a4-traefik-1 | 1.54325 | 0.23 | 6.38 |
| x3 | 5000 | book-reviews-a4-traefik-1 | 3.53268 | 0.19 | 9.43 |

### db

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-db-1 | 1.56049 | 0 | 3.58 |
| single | 10 | book-reviews-a4-db-1 | 1.46829 | 0 | 5.52 |
| single | 100 | book-reviews-a4-db-1 | 1.4745 | 0 | 4.45 |
| single | 1000 | book-reviews-a4-db-1 | 2.5985 | 0 | 4.41 |
| single | 5000 | book-reviews-a4-db-1 | 3.555 | 0.01 | 5.63 |
| x3 | 1 | book-reviews-a4-db-1 | 1.18436 | 0 | 8.32 |
| x3 | 10 | book-reviews-a4-db-1 | 1.28231 | 0 | 3.99 |
| x3 | 100 | book-reviews-a4-db-1 | 2.64231 | 0 | 3.91 |
| x3 | 1000 | book-reviews-a4-db-1 | 1.84975 | 0.07 | 3.84 |
| x3 | 5000 | book-reviews-a4-db-1 | 3.08244 | 1.41 | 4.6 |

### redis

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-redis-1 | 0.963659 | 0.26 | 2.95 |
| single | 10 | book-reviews-a4-redis-1 | 0.756585 | 0.25 | 3.05 |
| single | 100 | book-reviews-a4-redis-1 | 0.89325 | 0.3 | 3.65 |
| single | 1000 | book-reviews-a4-redis-1 | 1.02775 | 0.33 | 3.34 |
| single | 5000 | book-reviews-a4-redis-1 | 1.2615 | 0.32 | 4.95 |
| x3 | 1 | book-reviews-a4-redis-1 | 0.996923 | 0.29 | 3.41 |
| x3 | 10 | book-reviews-a4-redis-1 | 0.918205 | 0.3 | 3.12 |
| x3 | 100 | book-reviews-a4-redis-1 | 1.01513 | 0.29 | 4.46 |
| x3 | 1000 | book-reviews-a4-redis-1 | 0.744 | 0.29 | 2.57 |
| x3 | 5000 | book-reviews-a4-redis-1 | 1.09561 | 0.3 | 3.81 |

### opensearch

| Deployment | Requests | Contenedor | Promedio (%) | Mínimo (%) | Máximo (%) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-opensearch-1 | 1.16683 | 0.55 | 5.73 |
| single | 10 | book-reviews-a4-opensearch-1 | 1.08195 | 0.51 | 4.15 |
| single | 100 | book-reviews-a4-opensearch-1 | 1.40525 | 0.67 | 6.14 |
| single | 1000 | book-reviews-a4-opensearch-1 | 1.32 | 0.61 | 5.82 |
| single | 5000 | book-reviews-a4-opensearch-1 | 1.06625 | 0.6 | 4.82 |
| x3 | 1 | book-reviews-a4-opensearch-1 | 0.910769 | 0.6 | 5.05 |
| x3 | 10 | book-reviews-a4-opensearch-1 | 1.03333 | 0.61 | 4.29 |
| x3 | 100 | book-reviews-a4-opensearch-1 | 0.784872 | 0.58 | 4.61 |
| x3 | 1000 | book-reviews-a4-opensearch-1 | 0.945 | 0.45 | 4.27 |
| x3 | 5000 | book-reviews-a4-opensearch-1 | 1.00463 | 0.45 | 3.58 |

## Memory

### web

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-web-1 | 116.154 | 113.9 | 117.1 |
| single | 10 | book-reviews-a4-web-1 | 119.295 | 118.4 | 120.3 |
| single | 100 | book-reviews-a4-web-1 | 124.463 | 122.7 | 125.5 |
| single | 1000 | book-reviews-a4-web-1 | 131.678 | 131.2 | 132.3 |
| single | 5000 | book-reviews-a4-web-1 | 133.743 | 133 | 136.4 |
| x3 | 1 | book-reviews-a4-web-1 | 113.446 | 112.7 | 114.4 |
| x3 | 1 | book-reviews-a4-web-2 | 112.238 | 111.2 | 112.8 |
| x3 | 1 | book-reviews-a4-web-3 | 112.885 | 109.9 | 114 |
| x3 | 10 | book-reviews-a4-web-1 | 118.274 | 115.8 | 119.2 |
| x3 | 10 | book-reviews-a4-web-2 | 117.236 | 115.4 | 118.9 |
| x3 | 10 | book-reviews-a4-web-3 | 118.177 | 116.8 | 119.5 |
| x3 | 100 | book-reviews-a4-web-1 | 121.354 | 120.5 | 126.3 |
| x3 | 100 | book-reviews-a4-web-2 | 121.303 | 120.4 | 122.3 |
| x3 | 100 | book-reviews-a4-web-3 | 120.769 | 120 | 121.8 |
| x3 | 1000 | book-reviews-a4-web-1 | 127.38 | 126.3 | 132 |
| x3 | 1000 | book-reviews-a4-web-2 | 127.5 | 126.3 | 131.8 |
| x3 | 1000 | book-reviews-a4-web-3 | 126.787 | 126 | 127.8 |
| x3 | 5000 | book-reviews-a4-web-1 | 128.561 | 127.3 | 133 |
| x3 | 5000 | book-reviews-a4-web-2 | 129.19 | 127.9 | 134.3 |
| x3 | 5000 | book-reviews-a4-web-3 | 128.551 | 127.5 | 129.3 |

### static

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-static-1 | 25.0702 | 23.69 | 29.45 |
| single | 10 | book-reviews-a4-static-1 | 27.2602 | 26.03 | 27.93 |
| single | 100 | book-reviews-a4-static-1 | 28.3367 | 27.35 | 29.58 |
| single | 1000 | book-reviews-a4-static-1 | 29.629 | 28.49 | 34.07 |
| single | 5000 | book-reviews-a4-static-1 | 29.75 | 29.18 | 30.5 |
| x3 | 1 | book-reviews-a4-static-1 | 30.9244 | 30.07 | 32 |
| x3 | 10 | book-reviews-a4-static-1 | 31.0436 | 30.36 | 34.62 |
| x3 | 100 | book-reviews-a4-static-1 | 30.8582 | 30.13 | 35.23 |
| x3 | 1000 | book-reviews-a4-static-1 | 30.664 | 30.04 | 31.95 |
| x3 | 5000 | book-reviews-a4-static-1 | 30.3756 | 30.07 | 31.29 |

### traefik

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-traefik-1 | 113.629 | 112.7 | 115.1 |
| single | 10 | book-reviews-a4-traefik-1 | 115.978 | 115.1 | 123 |
| single | 100 | book-reviews-a4-traefik-1 | 117.903 | 117.2 | 118.9 |
| single | 1000 | book-reviews-a4-traefik-1 | 120.308 | 119.1 | 125.3 |
| single | 5000 | book-reviews-a4-traefik-1 | 122.635 | 120.5 | 135.6 |
| x3 | 1 | book-reviews-a4-traefik-1 | 119.495 | 118.3 | 123.7 |
| x3 | 10 | book-reviews-a4-traefik-1 | 119.849 | 118.6 | 120.7 |
| x3 | 100 | book-reviews-a4-traefik-1 | 121.397 | 119.5 | 122.9 |
| x3 | 1000 | book-reviews-a4-traefik-1 | 122.757 | 121.1 | 124 |
| x3 | 5000 | book-reviews-a4-traefik-1 | 124.483 | 120.9 | 135.7 |

### db

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-db-1 | 51.58 | 49.33 | 56.43 |
| single | 10 | book-reviews-a4-db-1 | 49.4434 | 48.76 | 50.24 |
| single | 100 | book-reviews-a4-db-1 | 49.5808 | 48.77 | 54.09 |
| single | 1000 | book-reviews-a4-db-1 | 52.621 | 51.79 | 58.31 |
| single | 5000 | book-reviews-a4-db-1 | 52.0727 | 50.61 | 56.43 |
| x3 | 1 | book-reviews-a4-db-1 | 54.3379 | 53.03 | 56 |
| x3 | 10 | book-reviews-a4-db-1 | 56.5082 | 53.96 | 62.31 |
| x3 | 100 | book-reviews-a4-db-1 | 56.1851 | 53.91 | 57.31 |
| x3 | 1000 | book-reviews-a4-db-1 | 55.8242 | 53.17 | 61.46 |
| x3 | 5000 | book-reviews-a4-db-1 | 60.1951 | 54.11 | 66.68 |

### redis

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-redis-1 | 8.80176 | 7.684 | 13.33 |
| single | 10 | book-reviews-a4-redis-1 | 8.37498 | 7.797 | 8.984 |
| single | 100 | book-reviews-a4-redis-1 | 9.9622 | 9.023 | 10.59 |
| single | 1000 | book-reviews-a4-redis-1 | 10.8483 | 10.14 | 11.56 |
| single | 5000 | book-reviews-a4-redis-1 | 14.829 | 13.63 | 16.07 |
| x3 | 1 | book-reviews-a4-redis-1 | 15.2926 | 14.68 | 16.31 |
| x3 | 10 | book-reviews-a4-redis-1 | 15.5095 | 14.78 | 21 |
| x3 | 100 | book-reviews-a4-redis-1 | 15.5762 | 14.97 | 20.24 |
| x3 | 1000 | book-reviews-a4-redis-1 | 16.3335 | 15.49 | 17.07 |
| x3 | 5000 | book-reviews-a4-redis-1 | 20.9383 | 19.14 | 25.32 |

### opensearch

| Deployment | Requests | Contenedor | Promedio (MiB) | Mínimo (MiB) | Máximo (MiB) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-opensearch-1 | 1474.31 | 1470.46 | 1475.58 |
| single | 10 | book-reviews-a4-opensearch-1 | 1473.76 | 1473.54 | 1474.56 |
| single | 100 | book-reviews-a4-opensearch-1 | 1472.26 | 1471.49 | 1473.54 |
| single | 1000 | book-reviews-a4-opensearch-1 | 1483.52 | 1482.75 | 1484.8 |
| single | 5000 | book-reviews-a4-opensearch-1 | 1496.86 | 1495.04 | 1512.45 |
| x3 | 1 | book-reviews-a4-opensearch-1 | 1526.76 | 1525.76 | 1527.81 |
| x3 | 10 | book-reviews-a4-opensearch-1 | 1525.68 | 1523.71 | 1530.88 |
| x3 | 100 | book-reviews-a4-opensearch-1 | 1521.56 | 1498.11 | 1530.88 |
| x3 | 1000 | book-reviews-a4-opensearch-1 | 1493.71 | 1492.99 | 1495.04 |
| x3 | 5000 | book-reviews-a4-opensearch-1 | 1501.23 | 1500.16 | 1502.21 |

## Threads

### web

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| single | 10 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| single | 100 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| single | 1000 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| single | 5000 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| x3 | 1 | book-reviews-a4-web-1 | 10 | 10 | 10 |
| x3 | 1 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 1 | book-reviews-a4-web-3 | 10.0256 | 10 | 11 |
| x3 | 10 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| x3 | 10 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 10 | book-reviews-a4-web-3 | 11.0256 | 11 | 12 |
| x3 | 100 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| x3 | 100 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 100 | book-reviews-a4-web-3 | 11 | 11 | 11 |
| x3 | 1000 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| x3 | 1000 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 1000 | book-reviews-a4-web-3 | 11.025 | 11 | 12 |
| x3 | 5000 | book-reviews-a4-web-1 | 11 | 11 | 11 |
| x3 | 5000 | book-reviews-a4-web-2 | 11 | 11 | 11 |
| x3 | 5000 | book-reviews-a4-web-3 | 11 | 11 | 11 |

### static

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-static-1 | 9.29268 | 9 | 15 |
| single | 10 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| single | 100 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| single | 1000 | book-reviews-a4-static-1 | 9.15 | 9 | 15 |
| single | 5000 | book-reviews-a4-static-1 | 9.15 | 9 | 15 |
| x3 | 1 | book-reviews-a4-static-1 | 9.15385 | 9 | 15 |
| x3 | 10 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| x3 | 100 | book-reviews-a4-static-1 | 9 | 9 | 9 |
| x3 | 1000 | book-reviews-a4-static-1 | 9.175 | 9 | 15 |
| x3 | 5000 | book-reviews-a4-static-1 | 9 | 9 | 9 |

### traefik

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-traefik-1 | 17 | 17 | 17 |
| single | 10 | book-reviews-a4-traefik-1 | 17 | 17 | 17 |
| single | 100 | book-reviews-a4-traefik-1 | 17.275 | 17 | 23 |
| single | 1000 | book-reviews-a4-traefik-1 | 17.15 | 17 | 23 |
| single | 5000 | book-reviews-a4-traefik-1 | 17.175 | 17 | 23 |
| x3 | 1 | book-reviews-a4-traefik-1 | 18.1538 | 18 | 24 |
| x3 | 10 | book-reviews-a4-traefik-1 | 18 | 18 | 18 |
| x3 | 100 | book-reviews-a4-traefik-1 | 18 | 18 | 18 |
| x3 | 1000 | book-reviews-a4-traefik-1 | 18 | 18 | 18 |
| x3 | 5000 | book-reviews-a4-traefik-1 | 18 | 18 | 18 |

### db

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-db-1 | 7.97561 | 7 | 8 |
| single | 10 | book-reviews-a4-db-1 | 7 | 7 | 7 |
| single | 100 | book-reviews-a4-db-1 | 7 | 7 | 7 |
| single | 1000 | book-reviews-a4-db-1 | 8 | 8 | 8 |
| single | 5000 | book-reviews-a4-db-1 | 8 | 8 | 8 |
| x3 | 1 | book-reviews-a4-db-1 | 9.5641 | 9 | 15 |
| x3 | 10 | book-reviews-a4-db-1 | 9.89744 | 9 | 10 |
| x3 | 100 | book-reviews-a4-db-1 | 9.89744 | 9 | 10 |
| x3 | 1000 | book-reviews-a4-db-1 | 9.675 | 9 | 15 |
| x3 | 5000 | book-reviews-a4-db-1 | 11.2195 | 9 | 12 |

### redis

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| single | 10 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| single | 100 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| single | 1000 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| single | 5000 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| x3 | 1 | book-reviews-a4-redis-1 | 6 | 6 | 6 |
| x3 | 10 | book-reviews-a4-redis-1 | 6.15385 | 6 | 12 |
| x3 | 100 | book-reviews-a4-redis-1 | 6.15385 | 6 | 12 |
| x3 | 1000 | book-reviews-a4-redis-1 | 6.025 | 6 | 7 |
| x3 | 5000 | book-reviews-a4-redis-1 | 6 | 6 | 6 |

### opensearch

| Deployment | Requests | Contenedor | Promedio (número) | Mínimo (número) | Máximo (número) |
| --- | --- | --- | --- | --- | --- |
| single | 1 | book-reviews-a4-opensearch-1 | 127 | 127 | 127 |
| single | 10 | book-reviews-a4-opensearch-1 | 127 | 127 | 127 |
| single | 100 | book-reviews-a4-opensearch-1 | 129.05 | 129 | 130 |
| single | 1000 | book-reviews-a4-opensearch-1 | 129.025 | 129 | 130 |
| single | 5000 | book-reviews-a4-opensearch-1 | 129 | 129 | 129 |
| x3 | 1 | book-reviews-a4-opensearch-1 | 129 | 129 | 129 |
| x3 | 10 | book-reviews-a4-opensearch-1 | 129 | 129 | 129 |
| x3 | 100 | book-reviews-a4-opensearch-1 | 129.026 | 129 | 130 |
| x3 | 1000 | book-reviews-a4-opensearch-1 | 131 | 131 | 131 |
| x3 | 5000 | book-reviews-a4-opensearch-1 | 132.585 | 132 | 133 |
