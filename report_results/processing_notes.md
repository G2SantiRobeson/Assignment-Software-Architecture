# Notas de procesamiento

## Estructura y selección

Se inspeccionaron los 912 archivos de results, incluyendo el contenido de JSON, JSONL, CSV, logs y marcadores. El inventario registra formato, codificación, cantidad de registros, campos, tamaño y SHA-256. Se reconoce el BOM UTF-16 de los 57 access logs Traefik; nueve históricos incluyen el prefijo `traefik-1 |`, que se retira únicamente en memoria para validar cada JSON. No son archivos corruptos. `samples.json` contiene JSONL pese a su extensión. Hay 61 run.json: 40 casos de la matriz principal, 8 smoke de 3 s y 13 ejecuciones históricas (10 de 10 s, una de 3 s y dos de 300 s). Las fuentes auxiliares sin run.json (verificación, Kubernetes y comprobaciones de recolector) no se asignan a escenarios por nombre.

Matriz seleccionada: `results/matrix-20260916-2305`, según matrix.json (40 casos, 300 s). Las identidades de servicio web y expectedReplicas confirman full=single (1) y scaled=x3 (3). El campo deployment de matrix.json describe la última configuración, no todos los casos; prevalece run.json por escenario. Las URL se conservan y se cotejan contra las muestras. Los cuatro endpoints se mantienen separados. Las ejecuciones históricas de 5000 requests son repeticiones del mismo objetivo, no muestras adicionales de la matriz. Las rutas absolutas antiguas de matrix.json corresponden al equipo de origen; se usan rutas relativas verificadas en este repositorio.

## Formatos y semántica

- run.json: objetivo, URL, duración configurada, deployment y endpoint. completed.json y matrix.json: metadatos de finalización, no métricas HTTP.
- summary.json: resumen k6; samples.json: puntos y definiciones de métricas. Se cuenta http_reqs una sola vez; no se suman contadores personalizados o iterations como requests adicionales.
- requests.csv: exportación de response_time_by_instance; reconciliada con los puntos originales por timestamp, endpoint, deployment, instancia, status y duración.
- containers.jsonl: Docker stats + threads totales recolectados de procesos; containers.csv es su exportación. PIDs no se utiliza como sustituto de threads.
- processes.jsonl: CPU por intervalo, RSS/virtual en bytes, threads, PID y start_ticks; processes.csv es su exportación. La primera CPU de cada proceso es null por falta de intervalo previo y se excluye del promedio, no se convierte a cero.
- threads.jsonl: en la matriz son totales por contenedor/timestamp, cotejados contra la suma de threads de procesos. Formatos históricos contienen líneas de docker top o /proc; se inventarían por separado, sin mezclarlos con la matriz.
- container-identities.jsonl: ID, nombre, servicio, imagen y límites. metrics-metadata.json: unidades y base de CPU. Se conservan IDs además de nombres y PID/start_ticks para distinguir procesos.
- kubernetes-usage.jsonl: texto de kubectl top, CPU en millicores y memoria en Mi; evidencia histórica/auxiliar, no usada para los 40 casos Docker.
- traefik.jsonl: access log del proxy (Duration en ns), no se mezcla con latencias k6 en ms ni se suman sus requests a los del cliente.
- comparison.csv: exportación de resumen; cotejada contra summary.json. collector.log y runner logs contienen salida operativa; un nombre runner-errors.log no prueba fallos. stop, collector-ready y load-matrix.lock son marcadores, no mediciones.

## VALUE READ DIRECTLY

Objetivo, duración configurada y URL de run.json. Completados y throughput de http_reqs.values.count/rate; tiempo promedio/mínimo/máximo/mediana/p90/p95 de http_req_duration.values; duración real de state.testRunDurationMs. http_req_failed es un Rate de fallos: passes cuenta valores true (requests fallidos), fails cuenta valores false (requests sin fallo según k6). Estos nombres no se interpretan como éxito/fallo del test. La comprobación HTTP 200 y los thresholds se validan aparte. Los códigos específicos provienen de tags.status de puntos http_reqs. CPU%, memoria original y threads provienen de sus respectivas fuentes. RSS, virtual_bytes y CPU por proceso están explícitos en JSONL.

## VALUE CALCULATED

- Error % = rate de http_req_failed × 100. Distribución de códigos = suma de value de http_reqs por status; porcentaje sobre el total observado. Familias 2xx/3xx/4xx/5xx en archivo separado para evitar doble conteo; ceros solo cuando una distribución completa demuestra ausencia. Status 0, de existir, no es un código HTTP y se clasifica other.
- P99: solo con todas las muestras http_req_duration; interpolación lineal h=(n−1)×0.99, entre floor(h) y ceil(h). Con una muestra, todos los percentiles coinciden con ella. Promedio, extremos y p50/p90/p95 crudos se calculan solo para reconciliar los valores existentes, con tolerancia relativa 1e−8 y absoluta 1e−7 ms.
- CPU/memoria/threads: promedio aritmético, mínimo y máximo de muestras disponibles por identidad. No son promedios ponderados por tiempo. Se agregan todos los puntos del archivo de la ejecución; el recolector inicia antes de k6 y termina después. first_timestamp/last_timestamp y conteos permiten revisar el alcance. No se afirma que sean exclusivamente la ventana exacta de tráfico.
- Memoria Docker: se usa el término anterior a `/` (uso, no límite). MiB=bytes/1048576; unidades SI con potencias de 1000 e IEC con potencias de 1024. Valor original íntegro conservado en memory_samples.csv. RSS de procesos/1048576; no se suma RSS entre procesos porque puede incluir páginas compartidas.
- CPU ya viene en porcentaje; 100 % representa un CPU lógico. No se divide por cantidad de CPUs. Threads es número, y su promedio puede ser fraccional.

## Ausencias y límites

No existe contador independiente de requests enviados/iniciados: requests_sent queda vacío, sin equipararlo a objetivo o completados. P99 no venía en summary.json, pero las muestras completas permiten calcularlo. No se imputan CPUs iniciales null. Las capturas discretas no demuestran cobertura continua de procesos que nacen y terminan entre capturas. El resumen por proceso presenta RSS; la memoria virtual original sigue disponible en processes.jsonl/CSV de origen. Las métricas históricas no se combinan con las tablas de los 40 escenarios. Los hashes duplicados de marcadores, metadatos y exportaciones se documentan en duplicate_files.md; no se eliminan fuentes.

En la matriz principal hay 280 filas por escenario/contenedor y 664 identidades de proceso. Los 40 escenarios tienen métricas HTTP y de contenedor completas; 75 identidades de proceso, repartidas en 33 escenarios, solo tienen una captura sin CPU calculable: 43 runc:[2:INIT], 14 traefik, 12 curl, 3 pg_isready, 2 postgres y 1 redis-server (nombres literales del recolector). Por eso la cobertura estricta de contenedores Y procesos es 7 OK y 33 PARTIAL. Memoria RSS y threads sí existen para esos procesos. No se descartan para elevar artificialmente la cobertura.

## Validaciones e incidencias

Los 40 escenarios se validan antes de escribir las tablas finales. Se cotejan objetivos/conteos, URL/etiquetas, tiempos/percentiles, errores, CSV exportados, threads agregados, réplicas y comparison.csv. SHA-256 de todos los originales se verifica nuevamente al finalizar. Detalle de cobertura y muestras en coverage.csv y validation_details.csv.

No hay archivos samples.json idénticos por SHA-256 entre ejecuciones. Hay diez grupos de archivos no vacíos idénticos (además de los marcadores vacíos), listados en duplicate_files.md. La ejecución histórica results/20260915-223228-full-aggregation-10 tiene 11 requests observados frente a 10 configurados y el correspondiente threshold fallido; es una discrepancia objetivo/observado, no una contradicción entre muestras y summary.json. No se detectaron discrepancias numéricas en las exportaciones de la matriz principal.

| Archivo | Incidencia | Detalle |
| --- | --- | --- |
| results/20260915-223228-full-aggregation-10/run.json | Requests observados/objetivo | 11 |
| results/20260915-223228-full-aggregation-10/summary.json | Threshold no cumplido | http_reqs: count==10 |

Incidencias detectadas en todas las ejecuciones: 2. Completo significa disponibilidad y reconciliación de las métricas exigidas; no implica éxito de todos los requests ni rendimiento adecuado.
