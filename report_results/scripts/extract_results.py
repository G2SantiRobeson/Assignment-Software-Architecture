"""Read-only extraction of Assignment 4 evidence; writes only report_results.

Run: python report_results/scripts/extract_results.py
Requires Python 3.10+ and matplotlib. No application or benchmark execution.
"""
import csv
import hashlib
import json
import math
import re
from collections import Counter, defaultdict
from pathlib import Path
from statistics import mean
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'report_results'
SRC = ROOT / 'results'
LOADS = [1, 10, 100, 1000, 5000]
EPS = {'static': 'Static Asset', 'aggregation': 'Expensive Aggregation', 'search': 'Search', 'book': 'Cheap Dynamic Read'}
DEP = {'full': 'single', 'scaled': 'x3'}
issues = []
def rel(p): return p.relative_to(ROOT).as_posix()
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def lines(p):
    if p.exists():
        with p.open(encoding='utf-8-sig') as f:
            for n, line in enumerate(f, 1):
                if line.strip():
                    try: yield json.loads(line)
                    except ValueError: issues.append((rel(p), 'JSON inválido', str(n)))
def csvread(p):
    with p.open(encoding='utf-8-sig', newline='') as f: return list(csv.DictReader(f))
def savecsv(name, rows, fields=None):
    if fields is None: fields = list(dict.fromkeys(k for row in rows for k in row))
    with (OUT/name).open('w', encoding='utf-8-sig', newline='') as f:
        w = csv.DictWriter(f, fieldnames=fields); w.writeheader(); w.writerows(rows)
def write(name, text): (OUT/name).write_text(text, encoding='utf-8')
def table(headers, rows):
    def fmt(v):
        if v is None or v == '': return '—'
        if isinstance(v, float): return f'{v:.6g}'
        return str(v).replace('|', '\\|').replace('\n', ' ')
    return '\n'.join(['| ' + ' | '.join(map(fmt, headers)) + ' |', '| ' + ' | '.join(['---']*len(headers)) + ' |'] + ['| ' + ' | '.join(map(fmt, r)) + ' |' for r in rows]) + '\n'
def check(ok, path, name, detail=''):
    if not ok: issues.append((rel(path), name, str(detail)))
def close(a,b): return a is not None and b is not None and math.isclose(float(a),float(b), rel_tol=1e-8, abs_tol=1e-7)
def quantile(vals, q):
    s=sorted(vals); i=(len(s)-1)*q; lo=math.floor(i); hi=math.ceil(i)
    return s[lo]+(s[hi]-s[lo])*(i-lo)
def mib(s):
    m=re.fullmatch(r'\s*([\d.]+)\s*([A-Za-z]+)\s*', s.split('/')[0])
    if not m: return None
    factors={'B':1,'kB':1000,'KB':1000,'MB':1e6,'GB':1e9,'KiB':1024,'MiB':1024**2,'GiB':1024**3,'TiB':1024**4}
    return float(m[1])*factors[m[2]]/1024**2 if m[2] in factors else None
def stats(row, prefix, values):
    v=[float(x) for x in values if x is not None and x != '']
    unit={'cpu':'pct','memory':'mib','threads':''}[prefix]
    for op,fn in [('avg',mean),('min',min),('max',max)]: row[f'{prefix}_{op}'+('_'+unit if unit else '')]=fn(v) if v else None
    row[prefix+'_samples']=len(v)

def main():
    OUT.mkdir(exist_ok=True); (OUT/'figures').mkdir(exist_ok=True)
    # Inspect every file, not merely its filename; maintain immutable source manifest.
    inventory=[]; hashes=defaultdict(list)
    for p in sorted(SRC.rglob('*')):
        if not p.is_file(): continue
        data=p.read_bytes(); digest=hashlib.sha256(data).hexdigest(); hashes[digest].append(rel(p))
        encoding='utf-16' if data.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig'
        txt=data.decode(encoding, errors='replace'); count=0; schema=''; kind='text'; valid=True
        if txt.strip():
            if p.suffix == '.jsonl' or p.name == 'samples.json':
                kind='JSONL'; keys=set()
                for line in txt.splitlines():
                    if not line.strip(): continue
                    if p.name=='traefik.jsonl' and re.match(r'^traefik-\d+\s+\|\s*\{',line):
                        kind='JSONL con prefijo Docker Compose'
                        line=line.split('|',1)[1].lstrip()
                    try: obj=json.loads(line); keys.update(obj.keys() if isinstance(obj,dict) else []); count+=1
                    except ValueError: valid=False
                schema=', '.join(sorted(keys))
            elif p.suffix == '.json':
                kind='JSON'
                try:
                    obj=json.loads(txt); count=len(obj) if isinstance(obj,(list,dict)) else 1
                    schema=', '.join(obj.keys()) if isinstance(obj,dict) else type(obj).__name__
                except ValueError: valid=False
            elif p.suffix == '.csv':
                kind='CSV'; rows=csvread(p); count=len(rows); schema=', '.join(rows[0]) if rows else txt.splitlines()[0]
            else: count=len(txt.splitlines()); schema=txt.splitlines()[0][:160]
        else: kind='empty'
        if not valid: issues.append((rel(p),'Formato inválido',''))
        inventory.append(dict(source_file=rel(p),bytes=len(data),format=kind,encoding=encoding,records=count,valid=valid,fields_or_first_line=schema,sha256=digest))
    savecsv('file_inventory.csv',inventory)
    print('Inventario:',len(inventory),'archivos',flush=True)
    matrices=[]
    for p in SRC.rglob('matrix.json'):
        m=read(p)
        if m.get('durationSeconds')==300 and m.get('totalCases')==40: matrices.append((m.get('startedUtc',''),p.parent))
    if not matrices: raise RuntimeError('No se encontró una matriz de 40 escenarios y 300 s; revisar selección manualmente')
    selected=max(matrices)[1]
    http=[]; allhttp=[]; infra=[]; processes=[]; rawmem=[]; statuses=[]; classes=[]; coverage=[]; runindex=[]; mapping=[]; checks=[]
    for rp in sorted(SRC.rglob('run.json')):
        run=read(rp); d=rp.parent; chosen=d.parent==selected
        base=dict(deployment=DEP.get(run.get('deployment'),run.get('deployment')),endpoint=run.get('endpoint'),requests_target=run.get('requests'))
        summary=read(d/'summary.json'); metrics=summary.get('metrics',{})
        val=lambda n: metrics.get(n,{}).get('values',{})
        h=dict(base,requests_sent=None,requests_completed=val('http_reqs').get('count'),successful_requests=val('http_req_failed').get('fails'),failed_requests=val('http_req_failed').get('passes'),error_rate_pct=100*val('http_req_failed')['rate'] if 'rate' in val('http_req_failed') else None)
        for out, key in [('response_time_avg_ms','avg'),('response_time_min_ms','min'),('response_time_max_ms','max'),('p50_ms','med'),('p90_ms','p(90)'),('p95_ms','p(95)')]: h[out]=val('http_req_duration').get(key)
        h.update(p99_ms=None,throughput_rps=val('http_reqs').get('rate'),duration_target_seconds=run.get('durationSeconds'),duration_actual_seconds=summary.get('state',{}).get('testRunDurationMs',0)/1000 or None,url=run.get('url'),source_file=rel(d/'summary.json')+';'+rel(d/'samples.json')+';'+rel(rp))
        points=defaultdict(list)
        for x in lines(d/'samples.json'):
            if x.get('type')=='Point' and x.get('metric') in ('http_reqs','http_req_duration','http_req_failed','response_time_by_instance'):
                points[x['metric']].append(x['data'])
        counts=Counter()
        for x in points['http_reqs']: counts[x.get('tags',{}).get('status','unknown')]+=x['value']
        durations=[x['value'] for x in points['http_req_duration']]
        startissues=len(issues)
        check(sum(counts.values())==h['requests_completed'],rp,'Conteo HTTP resumen/muestras',dict(counts))
        check(len(durations)==h['requests_completed'],rp,'Conteo de tiempos/resumen')
        check(h['requests_completed']==run['requests'],rp,'Requests observados/objetivo',h['requests_completed'])
        for xs in points.values():
            check(all(x.get('tags',{}).get('deployment')==run['deployment'] and x.get('tags',{}).get('endpoint')==run['endpoint'] for x in xs),rp,'Etiquetas de escenario')
        check(all(x.get('tags',{}).get('url')==run.get('url') for x in points['http_reqs']),rp,'URL de muestras/run')
        failed=sum(x['value'] for x in points['http_req_failed'])
        check(failed==h['failed_requests'],rp,'Fallos crudos/resumen',failed)
        if durations and len(durations)==h['requests_completed']:
            h['p99_ms']=quantile(durations,.99)
            for col,v in [('response_time_avg_ms',mean(durations)),('response_time_min_ms',min(durations)),('response_time_max_ms',max(durations)),('p50_ms',quantile(durations,.5)),('p90_ms',quantile(durations,.9)),('p95_ms',quantile(durations,.95))]: check(close(h[col],v),rp,col+' resumen/crudo')
        if (d/'requests.csv').exists():
            rows=csvread(d/'requests.csv'); ps=points['response_time_by_instance']
            check(len(rows)==len(ps),rp,'requests.csv cantidad')
            check(all(r['timestamp']==x['time'] and r['status']==x['tags']['status'] and r['endpoint']==x['tags']['endpoint'] and r['deployment']==x['tags']['deployment'] and r['instance']==x['tags']['instance'] and close(r['response_time_ms'],x['value']) for r,x in zip(rows,ps)),rp,'requests.csv contenido')
        for name,m in metrics.items():
            for threshold,t in m.get('thresholds',{}).items():
                if not t.get('ok'): issues.append((rel(d/'summary.json'),'Threshold no cumplido',name+': '+threshold))
        allhttp.append(dict(h,selected=chosen))
        runindex.append(dict(base,raw_deployment=run.get('deployment'),duration_seconds=run.get('durationSeconds'),expected_replicas=run.get('expectedReplicas'),selected=chosen,url=run.get('url'),directory=rel(d),reason='Matriz principal 300 s' if chosen else ('Duración distinta de 300 s' if run.get('durationSeconds')!=300 else 'Ejecución histórica separada; sin expectedReplicas ni métricas de CPU/RSS por proceso')))
        if not chosen: continue
        http.append(h)
        for code,count in sorted(counts.items()): statuses.append(dict(base,status_code=code,count=count,percentage=100*count/sum(counts.values()),source_file=rel(d/'samples.json')))
        for family in ['2xx','3xx','4xx','5xx','other']:
            count=sum(n for c,n in counts.items() if (c[0]+'xx' if len(c)==3 and c[0] in '2345' else 'other')==family)
            classes.append(dict(base,status_class=family,count=count,percentage=100*count/sum(counts.values()),source_file=rel(d/'samples.json')))
        identities=list(lines(d/'container-identities.jsonl')); ids={x['id']:x for x in identities}
        check(sum(x.get('service')=='web' for x in identities)==run.get('expectedReplicas'),rp,'Número de réplicas')
        cs=list(lines(d/'containers.jsonl')); ps=list(lines(d/'processes.jsonl')); ts=list(lines(d/'threads.jsonl'))
        if (d/'containers.csv').exists():
            rows=csvread(d/'containers.csv')
            check(len(rows)==len(cs) and all(r['container']==x['stats']['ID'] and r['name']==x['stats']['Name'] and r['timestamp']==x['timestamp'] and r['memory_usage']==x['stats']['MemUsage'] and close(r['cpu_percent'],x['stats']['CPUPerc'].rstrip('%')) and close(r['threads'],x.get('threads')) for r,x in zip(rows,cs)),rp,'containers.csv/JSONL')
        if (d/'processes.csv').exists():
            rows=csvread(d/'processes.csv')
            check(len(rows)==len(ps) and all(all((r[k]=='' if x.get(k) is None else str(x[k])==r[k] if k not in ['cpu_percent','cpu_interval_seconds'] else close(r[k],x[k])) for k in r) for r,x in zip(rows,ps)),rp,'processes.csv/JSONL')
        cg=defaultdict(list); pg=defaultdict(list)
        for x in cs:
            cg[x['stats']['ID']].append(x)
            rawmem.append(dict(base,timestamp=x['timestamp'],container=x['stats']['Name'],container_id=x['stats']['ID'],memory_original=x['stats']['MemUsage'],memory_usage_mib=mib(x['stats']['MemUsage']),source_file=rel(d/'containers.jsonl')))
        for x in ps: pg[(x['container'],x['pid'],x['start_ticks'],x['command'])].append(x)
        container_rows=[]; process_rows=[]
        for cid in sorted(set(ids)|set(cg)):
            xs=cg[cid]; row=dict(base,container=ids.get(cid,{}).get('name',xs[0]['stats']['Name'] if xs else cid),container_id=cid,service=ids.get(cid,{}).get('service'))
            stats(row,'cpu',[float(x['stats']['CPUPerc'].rstrip('%')) for x in xs]); stats(row,'memory',[mib(x['stats']['MemUsage']) for x in xs]); stats(row,'threads',[x.get('threads') for x in xs])
            row.update(first_timestamp=min((x['timestamp'] for x in xs),default=None),last_timestamp=max((x['timestamp'] for x in xs),default=None),source_file=rel(d/'containers.jsonl')+';'+rel(d/'container-identities.jsonl'))
            container_rows.append(row)
        for (cid,pid,start,cmd),xs in sorted(pg.items()):
            row=dict(base,container=xs[0]['name'],container_id=cid,process=cmd,pid=pid,start_ticks=start)
            stats(row,'cpu',[x.get('cpu_percent') for x in xs]); stats(row,'memory',[x['rss_bytes']/1024**2 for x in xs]); stats(row,'threads',[x.get('threads') for x in xs])
            row.update(first_timestamp=min(x['timestamp'] for x in xs),last_timestamp=max(x['timestamp'] for x in xs),source_file=rel(d/'processes.jsonl'))
            process_rows.append(row)
        totals=defaultdict(int)
        for x in ps: totals[x['container'],x['timestamp']]+=x['threads']
        check(all(totals[x['container'],x['timestamp']]==x['threads'] for x in ts),rp,'Threads de contenedor/suma procesos')
        infra+=container_rows; processes+=process_rows
        cov=dict(base)
        cov['HTTP data']='OK' if len(issues)==startissues and h['requests_completed']==run['requests'] else 'PARTIAL'
        for label,prefix in [('CPU','cpu'),('Memory','memory'),('Threads','threads')]:
            ok=bool(container_rows) and all(r[prefix+'_samples']>0 for r in container_rows) and set(ids)<=set(cg) and set(ids)<={x['container'] for x in ps} and all(r[prefix+'_samples']>0 for r in process_rows)
            cov[label]='OK' if ok else 'PARTIAL'
        cov['containers_status']='OK' if container_rows and all(r[p+'_samples']>0 for r in container_rows for p in ['cpu','memory','threads']) else 'PARTIAL'
        cov['processes_without_cpu']=sum(r['cpu_samples']==0 for r in process_rows)
        cov['status']='OK' if all(cov[k]=='OK' for k in ['HTTP data','CPU','Memory','Threads']) else 'PARTIAL'
        cov['Raw source']=rel(d); coverage.append(cov)
        checks.append(dict(base,container_count=len(ids),container_records=len(cs),process_records=len(ps),process_cpu_null=sum(x.get('cpu_percent') is None for x in ps),http_samples=len(durations),status=cov['status']))
        for p in sorted(d.iterdir()): mapping.append((f"{base['deployment']} / {base['endpoint']} / {base['requests_target']}",rel(p)))
        print('Procesado',d.name,flush=True)
    # Missing expected scenarios remain explicit, with empty numeric fields.
    keys={(r['deployment'],r['endpoint'],r['requests_target']) for r in coverage}
    for dep in DEP.values():
        for ep in EPS:
            for n in LOADS:
                if (dep,ep,n) not in keys:
                    b=dict(deployment=dep,endpoint=ep,requests_target=n)
                    http.append(b); coverage.append(dict(b,**{'HTTP data':'MISSING','CPU':'MISSING','Memory':'MISSING','Threads':'MISSING','status':'MISSING','Raw source':''}))
    # Reconcile the pre-existing comparison CSV against selected summaries.
    for r in csvread(selected/'comparison.csv'):
        match=[h for h in http if h['deployment']==DEP[r['deployment']] and h['endpoint']==r['endpoint'] and h['requests_target']==int(r['requested'])]
        check(len(match)==1,selected/'comparison.csv','Identidad de fila',r['directory'])
        if match:
            for col,key in [('observed','requests_completed'),('avg_ms','response_time_avg_ms'),('median_ms','p50_ms'),('p95_ms','p95_ms'),('min_ms','response_time_min_ms'),('max_ms','response_time_max_ms')]: check(close(r[col],match[0][key]),selected/'comparison.csv',col,r['directory'])
    for name,rows in [('load_test_summary.csv',http),('all_runs_http_summary.csv',allhttp),('infrastructure_summary.csv',infra),('process_summary.csv',processes),('memory_samples.csv',rawmem),('status_codes.csv',statuses),('status_classes.csv',classes),('run_inventory.csv',runindex),('coverage.csv',coverage),('validation_details.csv',checks)]: savecsv(name,rows)
    savecsv('validation_issues.csv',[dict(source_file=a,issue=b,detail=c) for a,b,c in issues],['source_file','issue','detail'])
    duplicates=[(digest,len(paths),'; '.join(paths)) for digest,paths in hashes.items() if len(paths)>1]
    write('duplicate_files.md','# Archivos idénticos por SHA-256\n\nLa igualdad de archivos auxiliares, metadatos o marcadores no implica que dos ejecuciones completas sean duplicadas.\n\n'+table(['SHA-256','Copias','Archivos'],duplicates))
    summarycounts=Counter(c['status'] for c in coverage)
    write('coverage.md','# Cobertura de los 40 escenarios\n\n'+f"Completos: {summarycounts['OK']}; parciales: {summarycounts['PARTIAL']}; faltantes: {summarycounts['MISSING']}.\n\n"+'OK: HTTP reconciliado con muestras y métricas CPU/memoria/threads presentes para todos los contenedores identificados y sus procesos observados. No certifica muestreo continuo de procesos transitorios. Requests enviados no tiene contador independiente. CPU PARTIAL identifica procesos sin un intervalo de CPU válido, no ausencia de CPU del contenedor. El detalle por proceso está en process_summary.csv (cpu_samples=0); coverage.csv incluye containers_status y processes_without_cpu.\n\n'+table(['Deployment','Endpoint','Requests','HTTP data','CPU','Memory','Threads','Estado','Raw source'],[[c[k] for k in ['deployment','endpoint','requests_target','HTTP data','CPU','Memory','Threads','status','Raw source']] for c in coverage]))
    write('raw_file_mapping.md','# Trazabilidad\n\nFuentes seleccionadas por escenario; el inventario completo incluye las ejecuciones adicionales. Rutas relativas a la raíz del repositorio.\n\n'+table(['Scenario','Raw file'],mapping)+'\n## Todas las ejecuciones\n\n'+table(['Directorio','Deployment original','Endpoint','Requests','Duración s','Selección'],[[r['directory'],r['raw_deployment'],r['endpoint'],r['requests_target'],r['duration_seconds'],r['reason']] for r in runindex]))
    tables=['# Tablas de resultados\n\nVentana configurada: 300 s. `single` = full con 1 réplica web; `x3` = scaled con 3. Tiempos en ms; CPU en % (100 % = un CPU lógico); memoria en MiB; threads en número. Promedios de infraestructura aritméticos por muestra, sin ponderación temporal. `—` = dato ausente. Las tablas redondean a 6 cifras significativas; los CSV conservan precisión.\n']
    for ep,title in EPS.items():
        tables.append(f'\n# {title}\n')
        hs={(r['deployment'],r['requests_target']):r for r in http if r['endpoint']==ep}
        for title2,cols in [('Response times',[('response_time_avg_ms','Avg ms'),('p95_ms','P95 ms'),('p99_ms','P99 ms')]),('Requests and errors',[('requests_completed','Completados'),('successful_requests','Exitosos'),('failed_requests','Fallidos'),('error_rate_pct','Error %'),('throughput_rps','req/s')])]:
            tables.append('## '+title2+'\n\n'+table(['Requests']+[dep+' '+lab for dep in DEP.values() for _,lab in cols],[[n]+[hs.get((dep,n),{}).get(k) for dep in DEP.values() for k,_ in cols] for n in LOADS]))
        for metric,label,unit in [('cpu','CPU','%'),('memory','Memory','MiB'),('threads','Threads','número')]:
            tables.append('## '+label+'\n')
            suffix={'cpu':'_pct','memory':'_mib','threads':''}[metric]
            for service in ['web','static','traefik','db','redis','opensearch']:
                rs=[r for r in infra if r['endpoint']==ep and r['service']==service]
                tables.append('### '+service+'\n\n'+table(['Deployment','Requests','Contenedor',f'Promedio ({unit})',f'Mínimo ({unit})',f'Máximo ({unit})'],[[r['deployment'],r['requests_target'],r['container'],r[metric+'_avg'+suffix],r[metric+'_min'+suffix],r[metric+'_max'+suffix]] for r in rs]))
        # Five figures per endpoint, components in separate panels.
        for key,ylabel,slug in [('response_time_avg_ms','Response time promedio (ms)','response_time'),('error_rate_pct','Error rate (%)','error_rate')]:
            fig,ax=plt.subplots(figsize=(8,4.6))
            for dep in DEP.values(): ax.plot(LOADS,[hs.get((dep,n),{}).get(key,float('nan')) for n in LOADS],marker='o',label=dep)
            ax.set(xscale='log',xlabel='Cantidad de requests en 300 s (escala log)',ylabel=ylabel,title=EPS[ep]+' — '+ylabel); ax.set_xticks(LOADS,[str(n) for n in LOADS]); ax.grid(alpha=.25); ax.legend(); fig.tight_layout(); fig.savefig(OUT/'figures'/f'{ep}_{slug}.png',dpi=170); plt.close(fig)
        for metric,unit in [('cpu','%'),('memory','MiB'),('threads','número')]:
            fig,axes=plt.subplots(3,2,figsize=(12,10)); suffix={'cpu':'_pct','memory':'_mib','threads':''}[metric]
            for ax,service in zip(axes.flat,['web','static','traefik','db','redis','opensearch']):
                rs=[r for r in infra if r['endpoint']==ep and r['service']==service]
                for dep,name in sorted({(r['deployment'],r['container']) for r in rs}):
                    series={r['requests_target']:r[metric+'_avg'+suffix] for r in rs if r['deployment']==dep and r['container']==name}
                    ax.plot(LOADS,[series.get(n,float('nan')) for n in LOADS],marker='o',label=dep+' / '+name.replace('book-reviews-a4-',''))
                ax.set(xscale='log',title=service,xlabel='Requests en 300 s (escala log)',ylabel=f'{metric} promedio ({unit})'); ax.set_xticks(LOADS,[str(n) for n in LOADS]); ax.grid(alpha=.25); ax.legend(fontsize=8)
            fig.suptitle(EPS[ep]+' — '+metric+' por contenedor',fontsize=15); fig.tight_layout(rect=(0,0,1,.96)); fig.savefig(OUT/'figures'/f'{ep}_{metric}.png',dpi=150); plt.close(fig)
    write('report_tables.md','\n'.join(tables))
    write('figures/README.md','# Figuras\n\nCinco PNG por endpoint. CPU, memoria y threads muestran promedios por muestra y separan los seis servicios en paneles. El eje X es logarítmico con las cinco cargas explícitas. Las líneas unen valores observados, sin modelar cargas intermedias.\n\n'+table(['Endpoint','Métrica','PNG'],[(title,slug,f'[{ep}_{slug}.png]({ep}_{slug}.png)') for ep,title in EPS.items() for slug in ['response_time','error_rate','cpu','memory','threads']]))
    write('processing_notes.md',notes(selected,inventory,runindex,issues,summarycounts))
    write('README.md',f'''# Resultados objetivos — Assignment 4

Tablas principales: [report_tables.md](report_tables.md). Cobertura: [coverage.md](coverage.md).

- `load_test_summary.csv`: 40 escenarios HTTP de 300 s; `status_codes.csv` y `status_classes.csv`: distribución de códigos y familias.
- `infrastructure_summary.csv`: CPU, memoria y threads por contenedor; `process_summary.csv`: CPU, RSS y threads por proceso identificado por contenedor/PID/start_ticks.
- `memory_samples.csv`: memoria original de Docker y conversión a MiB, con timestamp.
- `figures/`: 20 PNG, cinco por endpoint. Infraestructura dividida por componente; cada réplica conserva su identidad.
- `raw_file_mapping.md`, `file_inventory.csv`, `run_inventory.csv`: trazabilidad e inventario completo.
- `all_runs_http_summary.csv`: 61 ejecuciones separadas, incluidas las históricas y smoke; no se combinan con la matriz principal.
- `processing_notes.md`, `validation_issues.csv`, `validation_details.csv`, `duplicate_files.md`: reglas, validaciones y limitaciones.

Cobertura: {summarycounts['OK']} completos, {summarycounts['PARTIAL']} parciales, {summarycounts['MISSING']} faltantes. Los 40 tienen HTTP y CPU/memoria/threads por contenedor; 33 son parciales por CPU ausente en algún proceso observado una sola vez (75 identidades de proceso en total). Ver cobertura para detalle. El contador independiente de requests enviados no existe; se deja vacío. P99 se calcula de las muestras completas, no de percentiles resumidos.

Reejecutar desde la raíz: `python report_results/scripts/extract_results.py` (Python 3.10+ y matplotlib; entorno usado: Python 3.14, matplotlib 3.10.9). El script selecciona la matriz de 40 casos y 300 s más reciente por startedUtc, valida, extrae y genera CSV/Markdown/PNG. Solo escribe dentro de report_results, no ejecuta benchmarks ni modifica fuentes. Los archivos propios generados se sobrescriben.
''')
    # Verify original bytes still match the initial inventory after all processing.
    assert all(hashlib.sha256((ROOT/r['source_file']).read_bytes()).hexdigest()==r['sha256'] for r in inventory), 'Las fuentes cambiaron durante el procesamiento'
    assert len(http)==40 and len(coverage)==40
    print(json.dumps(dict(files=len(inventory),runs=len(runindex),coverage=dict(summarycounts),containers=len(infra),processes=len(processes),issues=len(issues),figures=len(list((OUT/'figures').glob('*.png')))),ensure_ascii=False),flush=True)

def notes(selected,inventory,runindex,issues,counts):
    return '''# Notas de procesamiento

## Estructura y selección

Se inspeccionaron los '''+str(len(inventory))+''' archivos de results, incluyendo el contenido de JSON, JSONL, CSV, logs y marcadores. El inventario registra formato, codificación, cantidad de registros, campos, tamaño y SHA-256. Se reconoce el BOM UTF-16 de los 57 access logs Traefik; nueve históricos incluyen el prefijo `traefik-1 |`, que se retira únicamente en memoria para validar cada JSON. No son archivos corruptos. `samples.json` contiene JSONL pese a su extensión. Hay 61 run.json: 40 casos de la matriz principal, 8 smoke de 3 s y 13 ejecuciones históricas (10 de 10 s, una de 3 s y dos de 300 s). Las fuentes auxiliares sin run.json (verificación, Kubernetes y comprobaciones de recolector) no se asignan a escenarios por nombre.

Matriz seleccionada: `'''+rel(selected)+'''`, según matrix.json (40 casos, 300 s). Las identidades de servicio web y expectedReplicas confirman full=single (1) y scaled=x3 (3). El campo deployment de matrix.json describe la última configuración, no todos los casos; prevalece run.json por escenario. Las URL se conservan y se cotejan contra las muestras. Los cuatro endpoints se mantienen separados. Las ejecuciones históricas de 5000 requests son repeticiones del mismo objetivo, no muestras adicionales de la matriz. Las rutas absolutas antiguas de matrix.json corresponden al equipo de origen; se usan rutas relativas verificadas en este repositorio.

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

'''+table(['Archivo','Incidencia','Detalle'],issues)+f'\nIncidencias detectadas en todas las ejecuciones: {len(issues)}. Completo significa disponibilidad y reconciliación de las métricas exigidas; no implica éxito de todos los requests ni rendimiento adecuado.\n'

if __name__=='__main__': main()
