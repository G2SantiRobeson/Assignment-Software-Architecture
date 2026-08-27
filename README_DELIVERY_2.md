# Entrega 2: Docker Compose y Kubernetes

Esta guía describe la infraestructura de la segunda entrega. La aplicación usa
Ruby on Rails 8.0.5.1, Ruby 3.3.8 y PostgreSQL 16. Docker Compose permite
ejecutarla localmente y los manifiestos de `k8s/` permiten desplegar la misma
imagen en un clúster Kubernetes local con Minikube o k3d.

Para el Grupo 7, HashiCorp Nomad es exclusivamente material de investigación.
No sustituye Kubernetes y no se implementan jobs, servicios ni volúmenes Nomad.
La investigación está en `docs/nomad_research.md`.

## 1. Arquitectura

Docker Compose:

```text
Browser -> localhost:3000 -> Rails (web) -> db:5432 -> PostgreSQL
                                                   -> named volume postgres_data
```

Kubernetes:

```text
Browser
   |
   v
Service book-reviews-web (NodePort 30080)
   |
   v
Deployment book-reviews-web
   |
   v
Service book-reviews-postgres (ClusterIP)
   |
   v
Deployment book-reviews-postgres
   |
   v
PersistentVolumeClaim book-reviews-postgres-data
```

Rails y PostgreSQL se ejecutan siempre en contenedores separados.

## 2. Archivos de infraestructura

| Archivo | Responsabilidad |
| --- | --- |
| `Dockerfile` | Imagen Rails de producción, multistage y con usuario sin privilegios. |
| `Dockerfile.dev` | Imagen Rails de desarrollo utilizada por Compose. |
| `compose.yaml` | Servicios `web` y `db`, healthcheck y volumen PostgreSQL. |
| `.env.example` | Plantilla de variables locales para Compose. |
| `k8s/namespace.yaml` | Namespace `book-reviews`. |
| `k8s/configmap.yaml` | Configuración no sensible de Rails y PostgreSQL. |
| `k8s/secret.example.yaml` | Plantilla versionada del Secret; no contiene credenciales utilizables. |
| `k8s/secret.yaml` | Copia local ignorada por Git y Docker; se crea antes del despliegue. |
| `k8s/postgres-pvc.yaml` | Solicitud de 2 GiB de almacenamiento persistente. |
| `k8s/postgres-deployment.yaml` | Deployment PostgreSQL con el PVC montado. |
| `k8s/postgres-service.yaml` | DNS interno estable para PostgreSQL. |
| `k8s/app-deployment.yaml` | Deployment Rails, init container y probes. |
| `k8s/app-service.yaml` | Service NodePort para exponer Rails. |
| `k8s/kustomization.yaml` | Agrupa todos los manifiestos. |

Los entrypoints ejecutan `rails db:prepare` antes de iniciar Rails. En
Compose se usa el entorno development; Kubernetes utiliza production.

## 3. Docker Compose

### Configuración

Desde PowerShell, copiar la plantilla y reemplazar la contraseña local:

```powershell
Copy-Item .env.example .env
notepad .env
```

`.env` está ignorado por Git. No se deben guardar credenciales reales en
`.env.example`.

### Inicio

```powershell
docker compose config --quiet
docker compose up --build -d
```

El comando levanta todo el sistema. Rails queda disponible en
<http://localhost:3000>.

```powershell
docker compose ps
docker compose logs --tail 100 db
docker compose logs --tail 100 web
Invoke-WebRequest http://localhost:3000/up -UseBasicParsing
```

Rails usa `DB_HOST=db`, donde `db` es el nombre DNS del servicio Compose.
El healthcheck de PostgreSQL usa `pg_isready` y Rails no comienza hasta que
la base esté saludable. `OPEN_LIBRARY_ENABLED=false` hace que un primer
arranque sea reproducible sin depender de la API externa.

Para reconstruir explícitamente el dataset de la tarea:

```powershell
docker compose exec -e OPEN_LIBRARY_ENABLED=false web bin/rails db:seed
```

El seed elimina y vuelve a crear los registros de autores, libros, reviews y
ventas; debe ejecutarse solamente cuando se quiera reiniciar ese dataset.

### Persistencia de Compose

PostgreSQL monta `postgres_data` en `/var/lib/postgresql/data`.

```powershell
docker compose config --volumes
docker volume ls
```

Prueba de persistencia:

1. Crear un libro llamado `COMPOSE_PERSISTENCE_MARKER`.
2. Confirmar que aparece en la aplicación.
3. Reemplazar los contenedores:

```powershell
docker compose down
docker compose up -d
```

4. Confirmar que el libro todavía existe.

No usar `docker compose down -v` durante esta prueba porque `-v` elimina
intencionalmente el volumen.

## 4. Kubernetes local

Se puede usar Minikube o k3d. Los ejemplos siguientes utilizan Minikube con el
driver Docker.

### Requisitos

```powershell
docker version
minikube version
kubectl version --client
```

Iniciar el clúster:

```powershell
minikube start --driver=docker --cpus=4 --memory=6144
kubectl get nodes
```

El nodo debe aparecer como `Ready`.

### Construcción de la imagen

La imagen debe estar disponible dentro del runtime de Minikube:

```powershell
minikube image build -t book-reviews:local .
minikube image ls | Select-String book-reviews
```

No se utiliza el flag `--no-cache` porque no está disponible en todas las
versiones de `minikube image build`. Si se necesita invalidar capas, primero
puede borrarse la imagen local del clúster o utilizarse un tag nuevo.

### Configuración y secretos

`k8s/configmap.yaml` contiene solamente configuración no sensible:

- `RAILS_ENV=production`.
- hostname interno `book-reviews-postgres`.
- puerto PostgreSQL 5432.
- configuración HTTP local.

El repositorio no guarda credenciales utilizables. Crear la copia local:

```powershell
Copy-Item k8s/secret.example.yaml k8s/secret.yaml
notepad k8s/secret.yaml
```

Reemplazar los tres valores `REPLACE_WITH_...`. Un `SECRET_KEY_BASE` local se
puede generar sin imprimirlo en el historial del shell con:

```powershell
docker compose run --rm --no-deps --entrypoint bin/rails web secret
```

Copiar la salida al archivo local. `k8s/secret.yaml` está ignorado por Git y
por el contexto Docker. Kubernetes Secrets separan credenciales de la imagen y
del ConfigMap, pero no cifran de forma segura un manifiesto guardado en Git;
base64 es solamente codificación.

### Despliegue

Validar el render de Kustomize y aplicar después de crear `k8s/secret.yaml`:

```powershell
kubectl kustomize k8s
kubectl apply -k k8s
```

Esperar los Deployments:

```powershell
kubectl -n book-reviews rollout status deployment/book-reviews-postgres --timeout=5m
kubectl -n book-reviews rollout status deployment/book-reviews-web --timeout=5m
kubectl get pods,services,pvc -n book-reviews
```

Estado esperado:

- Los pods PostgreSQL y Rails aparecen `Running` y `1/1 Ready`.
- El PVC `book-reviews-postgres-data` aparece `Bound`.
- El Service web publica `80:30080/TCP`.

Si Rails muestra `0/1 Running`, todavía puede estar ejecutando
`db:prepare`. Revisar eventos y logs antes de asumir que falló:

```powershell
kubectl -n book-reviews describe pod -l app.kubernetes.io/component=web
kubectl -n book-reviews logs deployment/book-reviews-web -c rails
kubectl -n book-reviews logs deployment/book-reviews-web -c wait-for-postgres
```

## 5. Acceso a la aplicación

Obtener la URL administrada por Minikube:

```powershell
minikube service book-reviews-web -n book-reviews --url
```

Mantener ese comando activo si el driver necesita un túnel. También puede
utilizarse port-forward:

```powershell
kubectl -n book-reviews port-forward service/book-reviews-web 8080:80
```

Con el port-forward activo:

```powershell
Invoke-WebRequest http://localhost:8080/up -UseBasicParsing
```

El endpoint debe responder HTTP 200.

## 6. Recuperación automática

Obtener el nombre del pod Rails:

```powershell
kubectl get pods -n book-reviews -l app.kubernetes.io/component=web
```

Eliminarlo y observar el reemplazo:

```powershell
kubectl delete pod -n book-reviews -l app.kubernetes.io/component=web
kubectl get pods -n book-reviews -l app.kubernetes.io/component=web -w
```

El Deployment conserva `replicas: 1`, por lo que Kubernetes crea un pod
nuevo. El nombre/UID debe cambiar y el reemplazo debe volver a `1/1 Ready`.
Después se debe comprobar nuevamente `/up`.

## 7. Persistencia de PostgreSQL en Kubernetes

El Deployment PostgreSQL monta el PVC
`book-reviews-postgres-data` en `/var/lib/postgresql/data`. La estrategia
`Recreate` evita que dos pods intenten montar simultáneamente el volumen
`ReadWriteOnce`.

Prueba:

1. Crear un libro llamado `KUBERNETES_PERSISTENCE_MARKER`.
2. Registrar el nombre del pod PostgreSQL actual:

```powershell
kubectl get pods -n book-reviews -l app.kubernetes.io/component=database
```

3. Eliminar el pod:

```powershell
kubectl delete pod -n book-reviews -l app.kubernetes.io/component=database
kubectl get pods -n book-reviews -l app.kubernetes.io/component=database -w
```

4. Esperar que el reemplazo esté `1/1 Ready`.
5. Verificar que `KUBERNETES_PERSISTENCE_MARKER` todavía existe.

No eliminar el PVC durante la prueba. El objetivo es reemplazar el pod y
volver a montar el mismo volumen.

## 8. Estado persistente y múltiples instancias

| Estado | Ubicación actual | Persistente | Estrategia con varias réplicas |
| --- | --- | --- | --- |
| Datos de negocio | PostgreSQL | Sí | Todas las réplicas Rails comparten el mismo Service PostgreSQL. |
| Sesiones | Cookie cifrada/firmada del cliente | Fuera del contenedor | Todas las réplicas comparten `SECRET_KEY_BASE`. |
| Uploads | No aplicable; Active Storage está deshabilitado | No aplicable | Si se agrega, usar S3, MinIO u object storage compartido. |
| Cache | Memoria de proceso en Compose; `tmp/cache` local al pod en production/Kubernetes | No | Usar un cache compartido, por ejemplo Redis, si se necesita coherencia entre réplicas. |
| Trabajos en segundo plano | Adaptador `async` dentro del proceso Rails | No | Usar una cola compartida y workers separados si los trabajos deben sobrevivir reinicios. |
| Logs y temporales | STDOUT/filesystem del contenedor | No | Centralizar logs; no depender de temporales locales. |

Rails no conserva estado de negocio en su filesystem. Por eso eliminar un pod
web no pierde datos importantes. Para probar más de una réplica después de que
la base esté preparada:

```powershell
kubectl -n book-reviews scale deployment/book-reviews-web --replicas=2
kubectl -n book-reviews rollout status deployment/book-reviews-web --timeout=5m
kubectl get pods -n book-reviews -l app.kubernetes.io/component=web
```

El Service distribuye tráfico entre los pods disponibles. Restaurar el valor
de entrega:

```powershell
kubectl -n book-reviews scale deployment/book-reviews-web --replicas=1
```

En un despliegue de mayor escala, las migraciones deberían ejecutarse una sola
vez mediante un Job o una etapa de release antes de escalar Rails.

## 9. Limpieza y límites

Eliminar los recursos:

```powershell
kubectl delete -k k8s
minikube stop
```

`kubectl delete -k k8s` elimina también el PVC y puede borrar sus datos. Debe
usarse solamente cuando la demostración haya terminado y ya no se necesite la
base.

Límites del entorno:

- Minikube es un clúster local y no proporciona alta disponibilidad real.
- El PVC protege frente al reemplazo de pods, pero no sustituye backups.
- NodePort no incluye TLS ni dominio.
- PostgreSQL usa una sola réplica.
- `k8s/secret.yaml` es local, no se versiona y debe contener solamente valores
  para el clúster de demostración.
