"""Create a compact four-endpoint P95 figure from the existing validated CSV.

Run from the repository: python report_results/scripts/plot_p95_overview.py
Requires matplotlib. Does not run benchmarks or alter source results.
Each P95 is checked against its original k6 summary before plotting.
"""
import csv
import json
import math
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator, NullLocator, ScalarFormatter

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'report_results'
LOADS = [1, 10, 100, 1000, 5000]
ENDPOINTS = [('static', 'Static asset'), ('aggregation', 'Expensive aggregation'),
             ('search', 'Search'), ('book', 'Cheap dynamic read')]

with (REPORT / 'load_test_summary.csv').open(encoding='utf-8-sig', newline='') as f:
    rows = list(csv.DictReader(f))
values = {}
for row in rows:
    key = row['deployment'], row['endpoint'], int(row['requests_target'])
    if key in values:
        raise ValueError(f'Duplicate scenario: {key}')
    value = float(row['p95_ms'])
    assert math.isfinite(value) and value >= 0
    assert float(row['duration_target_seconds']) == 300
    sources = [p for p in row['source_file'].split(';') if p.endswith('/summary.json')]
    assert len(sources) == 1
    original = json.loads((ROOT / sources[0]).read_text(encoding='utf-8-sig'))
    assert math.isclose(value, original['metrics']['http_req_duration']['values']['p(95)'], rel_tol=1e-12)
    values[key] = value
expected = {(d, ep, n) for d in ['single', 'x3'] for ep, _ in ENDPOINTS for n in LOADS}
assert set(values) == expected

plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 10,
                     'axes.titlesize': 11, 'axes.labelsize': 10,
                     'xtick.labelsize': 9, 'ytick.labelsize': 9})
fig, axes = plt.subplots(2, 2, figsize=(8.4, 5.65))
for ax, (ep, title) in zip(axes.flat, ENDPOINTS):
    for dep, label, color, marker, style in [
        ('single', 'Single instance', '#0072B2', 'o', '-'),
        ('x3', 'Load-balanced x3', '#D55E00', 's', '--')]:
        ax.plot(LOADS, [values[dep, ep, n] for n in LOADS], label=label,
                color=color, marker=marker, linestyle=style, linewidth=1.8,
                markersize=4.7, markerfacecolor='white', markeredgewidth=1.3)
    ax.set_title(title, loc='left', fontweight='bold', pad=8)
    ax.set_xscale('log')
    ax.set_xticks(LOADS)
    ax.xaxis.set_major_formatter(ScalarFormatter())
    ax.xaxis.set_minor_locator(NullLocator())
    ax.set_ylabel('P95 response time (ms)')
    ax.set_ylim(bottom=0)
    ax.yaxis.set_major_locator(MaxNLocator(nbins=4))
    ax.grid(axis='y', color='#dce1e5', linewidth=.7)
    ax.set_axisbelow(True)
    ax.spines[['top', 'right']].set_visible(False)
    ax.spines[['left', 'bottom']].set_color('#b1b8bf')

fig.suptitle('Response-time P95 by endpoint', fontsize=14, fontweight='bold', y=.985)
handles, labels = axes[0, 0].get_legend_handles_labels()
fig.legend(handles, labels, loc='upper center', bbox_to_anchor=(.5, .94),
           ncol=2, frameon=False, fontsize=10)
fig.subplots_adjust(left=.09, right=.985, top=.81, bottom=.17, wspace=.28, hspace=.48)
fig.supxlabel('Total requests per 300-second test (logarithmic x-axis)', y=.085, fontsize=10)
fig.text(.5, .027, 'Independent y-scales. P95 from k6 summaries; at 1 request, P95 is that single observation.',
         ha='center', fontsize=8, color='#444444')
output = REPORT / 'figures' / 'p95_endpoints_comparison.png'
fig.savefig(output, dpi=300, facecolor='white')
plt.close(fig)
print(f'Validated 40 P95 values against source summaries. Saved: {output}')
