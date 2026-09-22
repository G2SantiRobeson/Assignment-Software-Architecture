"""Build a compact, source-traceable 5000-request infrastructure table.

Run: python report_results/scripts/make_report_resource_table.py
This selects the component named by the assignment for each endpoint. It does
not assert which component is a bottleneck. The complete per-container and
per-process observations remain in infrastructure_summary.csv and
process_summary.csv.
"""
import csv
from pathlib import Path

REPORT = Path(__file__).resolve().parents[1]
SELECT = {'static': 'static', 'aggregation': 'web', 'search': 'opensearch', 'book': 'web'}
LABELS = {'static': 'Static asset', 'aggregation': 'Aggregation',
          'search': 'Search', 'book': 'Book detail'}

with (REPORT/'infrastructure_summary.csv').open(encoding='utf-8-sig', newline='') as f:
    source = list(csv.DictReader(f))
rows = []
for ep, service in SELECT.items():
    for dep in ('single', 'x3'):
        matches = sorted((r for r in source if r['endpoint'] == ep and
                          r['deployment'] == dep and r['requests_target'] == '5000' and
                          r['service'] == service), key=lambda r:r['container'])
        assert len(matches) == (3 if dep == 'x3' and service == 'web' else 1)
        for r in matches:
            assert all(r[k] for k in ['cpu_avg_pct','cpu_max_pct','memory_max_mib','threads_max','source_file'])
            rows.append({'endpoint': LABELS[ep], 'deployment': dep,
                         'container': r['container'].removeprefix('book-reviews-a4-'),
                         'cpu_avg_pct': round(float(r['cpu_avg_pct']), 2),
                         'cpu_max_pct': round(float(r['cpu_max_pct']), 2),
                         'memory_max_mib': round(float(r['memory_max_mib']), 1),
                         'threads_max': int(float(r['threads_max'])),
                         'source_file': r['source_file']})
assert len(rows) == 12

with (REPORT/'report_resource_table_5000.csv').open('w', encoding='utf-8-sig', newline='') as f:
    writer=csv.DictWriter(f, fieldnames=list(rows[0])); writer.writeheader(); writer.writerows(rows)
headers=['Endpoint','Deployment','Container','CPU avg (%)','CPU max (%)','Memory max (MiB)','Threads max']
body=['| '+' | '.join(headers)+' |', '| '+' | '.join(['---']*len(headers))+' |']
for r in rows:
    body.append('| '+' | '.join(str(r[k]) for k in ['endpoint','deployment','container','cpu_avg_pct','cpu_max_pct','memory_max_mib','threads_max'])+' |')
text='''# Resource measurements at 5000 requests

Each test lasted 300 seconds. Components shown: static origin for static assets; Rails application for aggregation and book details; OpenSearch for search. Each application replica is a separate row. This selection follows the endpoint roles in the assignment and does not identify a bottleneck.

CPU average and maximum, memory maximum, and thread maximum are descriptive statistics of the container samples collected during each run. The collector also ran briefly before and after k6. Full measurements for all containers and individual processes are in `infrastructure_summary.csv` and `process_summary.csv`. The companion CSV retains the raw source path for every row.

'''+ '\n'.join(body)+'\n'
(REPORT/'report_resource_table_5000.md').write_text(text,encoding='utf-8')
print('Wrote 12 rows to report_resource_table_5000.md and .csv')
