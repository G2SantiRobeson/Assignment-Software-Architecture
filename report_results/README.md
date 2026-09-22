# Resultados objetivos — Assignment 4

Tablas principales: [report_tables.md](report_tables.md). Cobertura: [coverage.md](coverage.md).

- `load_test_summary.csv`: 40 escenarios HTTP de 300 s; `status_codes.csv` y `status_classes.csv`: distribución de códigos y familias.
- `infrastructure_summary.csv`: CPU, memoria y threads por contenedor; `process_summary.csv`: CPU, RSS y threads por proceso identificado por contenedor/PID/start_ticks.
- `memory_samples.csv`: memoria original de Docker y conversión a MiB, con timestamp.
- `figures/`: 20 PNG, cinco por endpoint. Infraestructura dividida por componente; cada réplica conserva su identidad.
- `raw_file_mapping.md`, `file_inventory.csv`, `run_inventory.csv`: trazabilidad e inventario completo.
- `all_runs_http_summary.csv`: 61 ejecuciones separadas, incluidas las históricas y smoke; no se combinan con la matriz principal.
- `processing_notes.md`, `validation_issues.csv`, `validation_details.csv`, `duplicate_files.md`: reglas, validaciones y limitaciones.

Cobertura: 7 completos, 33 parciales, 0 faltantes. Los 40 tienen HTTP y CPU/memoria/threads por contenedor; 33 son parciales por CPU ausente en algún proceso observado una sola vez (75 identidades de proceso en total). Ver cobertura para detalle. El contador independiente de requests enviados no existe; se deja vacío. P99 se calcula de las muestras completas, no de percentiles resumidos.

Reejecutar desde la raíz: `python report_results/scripts/extract_results.py` (Python 3.10+ y matplotlib; entorno usado: Python 3.14, matplotlib 3.10.9). El script selecciona la matriz de 40 casos y 300 s más reciente por startedUtc, valida, extrae y genera CSV/Markdown/PNG. Solo escribe dentro de report_results, no ejecuta benchmarks ni modifica fuentes. Los archivos propios generados se sobrescriben.
