# Segunda entrega: Docker, Kubernetes y HashiCorp Nomad

Este documento describe la infraestructura añadida para la segunda entrega, cómo ejecutarla y cómo demostrar cada requisito. La aplicación funcional (modelos, CRUD, reportes, búsqueda y semillas) no fue modificada. La configuración existente de Docker Compose se conservó porque ya separaba correctamente Rails y PostgreSQL y persistía la base de datos.

## 1. Resumen de lo implementado

La entrega dispone de tres formas de ejecución:

1. **Docker Compose:** un contenedor `web` para Rails y otro `db` para PostgreSQL. `docker compose up --build` construye y levanta todo el sistema.
2. **Kubernetes local:** manifiestos bajo `k8s/` para Minikube o k3d. Incluyen Deployments, Services, ConfigMap, Secret y un PersistentVolumeClaim.
3. **HashiCorp Nomad:** el archivo `nomad/book-reviews.nomad.hcl` ejecuta Rails y PostgreSQL como tareas Docker separadas. Usa service discovery nativo de Nomad, Nomad Variables para los secretos y un host volume para PostgreSQL.

También se hizo configurable el HTTPS de producción mediante `RAILS_FORCE_SSL` y `RAILS_ASSUME_SSL`. Ambos continúan activados por defecto. Los despliegues locales los desactivan explícitamente porque exponen HTTP y no incluyen un proxy TLS.

## 2. Archivos de infraestructura

| Archivo | Responsabilidad |
| --- | --- |
| `Dockerfile.dev` | Imagen Ruby/Rails usada por Docker Compose. |
| `Dockerfile` | Imagen de producción, multi-stage y con usuario no privilegiado, usada por Kubernetes y Nomad. |
| `compose.yaml` | Orquesta Rails y PostgreSQL, espera el health check de la base y crea el volumen `postgres_data`. |
| `bin/docker-entrypoint-dev` | Elimina un PID antiguo, ejecuta `db:prepare` y luego inicia Rails. |
| `k8s/namespace.yaml` | Aísla todos los recursos en el namespace `book-reviews`. |
| `k8s/configmap.yaml` | Configuración no sensible de Rails y de la conexión PostgreSQL. |
| `k8s/secret.yaml` | Credenciales locales de PostgreSQL y secreto compartido de Rails. |
| `k8s/postgres-pvc.yaml` | Solicita 2 GiB persistentes para PostgreSQL. |
| `k8s/postgres-deployment.yaml` | Ejecuta una réplica de PostgreSQL y monta el PVC. |
| `k8s/postgres-service.yaml` | Proporciona el nombre DNS interno `book-reviews-postgres`. |
| `k8s/app-deployment.yaml` | Ejecuta Rails con probes de inicio, disponibilidad y vida. |
| `k8s/app-service.yaml` | Expone Rails mediante un NodePort en el puerto `30080`. |
| `k8s/kustomization.yaml` | Permite aplicar todos los manifiestos con un solo comando. |
| `nomad/agent.hcl` | Registra el host volume local de PostgreSQL en un cliente Nomad. |
| `nomad/book-reviews.nomad.hcl` | Job completo con los grupos `database` y `web`. |

## 3. Docker Compose

### Ejecución

Requisito: Docker Desktop iniciado. Desde la raíz del repositorio:

```text
docker compose up --build
```

La aplicación queda disponible en <http://localhost:3000>. No es necesario ejecutar `db:create` ni `db:migrate` por separado: el entrypoint ejecuta `bin/rails db:prepare` en cada arranque y el servicio web espera que el health check `pg_isready` de PostgreSQL sea exitoso.

La carga de datos mock es opcional y reinicia el conjunto de datos de la entrega:

```text
docker compose exec web bin/rails db:seed
```

Para detener los contenedores sin borrar la base:

```text
docker compose down
```

No usar `docker compose down --volumes` si se necesita conservar la información, porque esa opción elimina el volumen de PostgreSQL.

### Estado persistente en Docker

- **Base de datos:** vive en el volumen nombrado `postgres_data`, montado en `/var/lib/postgresql/data` dentro del contenedor PostgreSQL. Sobrevive a la eliminación o recreación de los contenedores.
- **Archivos subidos:** la aplicación no carga Active Storage (`active_storage/engine` está deshabilitado), por lo que actualmente no existen uploads que deban persistirse.
- **Sesiones:** Rails usa sesiones de cookie firmadas del lado del cliente; no hay un almacén de sesiones local en el contenedor.
- **Código y temporales en Compose:** el código se monta desde el directorio del host para desarrollo. Los logs y archivos temporales no son estado de negocio.

## 4. Despliegue local en Kubernetes

### Recursos y decisiones

- Rails y PostgreSQL tienen Deployments separados.
- `book-reviews-web` es el Service externo de la aplicación.
- `book-reviews-postgres` es un Service `ClusterIP`, accesible solo dentro del clúster.
- El hostname de base de datos se obtiene desde el ConfigMap; usuario, contraseña y `SECRET_KEY_BASE` provienen del Secret.
- El PVC tiene modo `ReadWriteOnce`. PostgreSQL usa una sola réplica y estrategia `Recreate` para no montar simultáneamente un volumen local de escritura en dos pods.
- Rails comienza con una réplica. Luego del primer arranque puede escalarse porque los pods web no almacenan estado de negocio local.
- Un init container ejecuta `pg_isready` y evita que Rails intente preparar la base antes de que PostgreSQL esté disponible.
- Los probes consultan `/up`. Kubernetes solo envía tráfico a pods web disponibles y reinicia un contenedor si falla repetidamente.

`k8s/secret.yaml` contiene valores exclusivamente locales para que la entrega sea reproducible. Un Secret de Kubernetes evita introducir credenciales en la imagen, pero un valor guardado en Git no constituye un secreto de producción. Antes de un despliegue real se debe reemplazar ese manifiesto por un gestor de secretos o por un Secret creado fuera del repositorio.

### Opción A: Minikube

```text
minikube start --driver=docker
minikube image build -t book-reviews:local .
kubectl apply -k k8s
kubectl -n book-reviews rollout status deployment/book-reviews-postgres --timeout=5m
kubectl -n book-reviews rollout status deployment/book-reviews-web --timeout=5m
minikube service book-reviews-web -n book-reviews --url
```

El último comando imprime la URL accesible de la aplicación.

### Opción B: k3d

```text
k3d cluster create book-reviews --agents 1 -p "30080:30080@server:0"
docker build -t book-reviews:local .
k3d image import book-reviews:local -c book-reviews
kubectl apply -k k8s
kubectl -n book-reviews rollout status deployment/book-reviews-postgres --timeout=5m
kubectl -n book-reviews rollout status deployment/book-reviews-web --timeout=5m
```

La aplicación queda disponible en <http://localhost:30080>.

### Poblar la base en Kubernetes

El contenedor prepara automáticamente las bases y migraciones. Para crear los datos mock requeridos:

```text
kubectl -n book-reviews exec deployment/book-reviews-web -- env OPEN_LIBRARY_ENABLED=false ./bin/rails db:seed
```

El seed es destructivo para los registros existentes y solo debe ejecutarse cuando se desea reconstruir el dataset.

### Verificación exigida por el enunciado

#### A. La aplicación es accesible mediante su Service

```text
kubectl -n book-reviews get service book-reviews-web
kubectl -n book-reviews get endpoints book-reviews-web
kubectl -n book-reviews port-forward service/book-reviews-web 8080:80
```

Con `port-forward` activo, abrir <http://localhost:8080/up> y <http://localhost:8080>. El endpoint `/up` debe responder exitosamente y el Service debe tener al menos un endpoint.

#### B. Kubernetes recrea un pod de la aplicación

```text
kubectl -n book-reviews get pods -l app.kubernetes.io/component=web
kubectl -n book-reviews delete pod -l app.kubernetes.io/component=web
kubectl -n book-reviews rollout status deployment/book-reviews-web --timeout=5m
kubectl -n book-reviews get pods -l app.kubernetes.io/component=web
```

El nombre o la edad del pod cambia porque el Deployment mantiene la cantidad deseada de réplicas.

#### C. Los datos sobreviven al reinicio de PostgreSQL

Primero guardar un dato mediante la interfaz o ejecutar el seed. Registrar el conteo:

```text
kubectl -n book-reviews exec deployment/book-reviews-web -- ./bin/rails runner "puts Author.count"
kubectl -n book-reviews get pvc book-reviews-postgres-data
kubectl -n book-reviews delete pod -l app.kubernetes.io/component=database
kubectl -n book-reviews rollout status deployment/book-reviews-postgres --timeout=5m
kubectl -n book-reviews exec deployment/book-reviews-web -- ./bin/rails runner "puts Author.count"
```

El PVC debe continuar en estado `Bound` y el conteo anterior y posterior debe ser igual. El pod se reemplaza, pero el volumen no se elimina.

### Escalar la aplicación web

Después del primer arranque:

```text
kubectl -n book-reviews scale deployment/book-reviews-web --replicas=2
kubectl -n book-reviews rollout status deployment/book-reviews-web --timeout=5m
kubectl -n book-reviews get pods -l app.kubernetes.io/component=web
```

Las réplicas comparten PostgreSQL mediante el Service interno y reciben el mismo `SECRET_KEY_BASE`, por lo que pueden validar las mismas cookies firmadas. El Service web distribuye solicitudes entre los pods disponibles. La capacidad de conexiones debe calcularse aproximadamente como `réplicas × RAILS_MAX_THREADS`, además de conexiones administrativas y otros procesos.

## 5. Despliegue asignado: HashiCorp Nomad

HashiCorp recomienda usar Nomad desde WSL2 cuando Docker Desktop se ejecuta en Windows. El agente debe poder acceder al socket de Docker. Los siguientes comandos se ejecutan en una terminal Linux/WSL2 desde el repositorio.

### Preparar el agente y la imagen

```text
sudo mkdir -p /opt/nomad/volumes/book-reviews-postgres
sudo nomad agent -dev -bind=0.0.0.0 -config=nomad/agent.hcl
```

Mantener el agente activo. En otra terminal:

```text
export NOMAD_ADDR=http://127.0.0.1:4646
docker build -t book-reviews:local .
nomad node status
```

El nodo debe mostrar el driver `docker` disponible. El modo `-dev` es solo para evaluación local; un clúster real separaría servidores y clientes y habilitaría ACLs.

### Registrar las credenciales con Nomad Variables

```text
nomad var put nomad/jobs/book-reviews \
  DB_USERNAME=postgres \
  DB_PASSWORD=book-reviews-local-password \
  SECRET_KEY_BASE="$(openssl rand -hex 64)"
```

El job no contiene credenciales. Sus templates leen la variable `nomad/jobs/book-reviews` y generan archivos de entorno bajo el directorio privado `secrets/` de cada tarea. En un clúster real se deben habilitar ACLs; para requisitos más estrictos se puede integrar HashiCorp Vault.

### Ejecutar y verificar el job

```text
nomad job plan nomad/book-reviews.nomad.hcl
nomad job run nomad/book-reviews.nomad.hcl
nomad job status book-reviews
nomad service info book-reviews-postgres
nomad service info book-reviews-web
```

La aplicación queda en <http://localhost:3000>. El grupo `database` publica PostgreSQL en el catálogo nativo de Nomad usando un puerto de host asignado dinámicamente, evitando conflictos con instalaciones locales de PostgreSQL. El template del grupo `web` utiliza `nomadService` para obtener ese puerto y reinicia Rails si cambia el endpoint. En Docker Desktop/WSL2, Rails alcanza el puerto publicado a través de `host.docker.internal`; usar el `127.0.0.1` anunciado por el agente apuntaría al propio contenedor Rails. El entorno Nomad también desactiva la consulta a Open Library durante el seed inicial para que el primer health check sea reproducible y no dependa de acceso externo.

El health check TCP supervisa PostgreSQL y el health check HTTP consulta `/up` en Rails. Las políticas `restart` y `check_restart` permiten que Nomad reemplace tareas que fallen.

### Persistencia y recuperación en Nomad

Buscar los allocations:

```text
nomad job status book-reviews
```

Después de crear datos, reiniciar únicamente PostgreSQL usando el ID del allocation del grupo `database`:

```text
nomad alloc restart -task postgres <database-allocation-id>
```

Al volver a consultar la aplicación, los registros deben seguir presentes. El directorio `/opt/nomad/volumes/book-reviews-postgres` está fuera del allocation, por lo que sobrevive al reinicio de la tarea. Este host volume es adecuado para una demostración de un solo nodo, pero depende de ese nodo; en producción se usaría almacenamiento CSI o almacenamiento de red con copias de respaldo.

## 6. Respuesta sobre estado y múltiples instancias

El estado persistente actual vive en PostgreSQL. Docker Compose lo coloca en un named volume, Kubernetes en un PVC y Nomad en un host volume. La aplicación no implementa uploads y las sesiones están en cookies firmadas, de modo que los contenedores Rails son esencialmente stateless.

Para ejecutar múltiples instancias web se mantiene una única base de datos compartida, un mismo secreto de firma y una capa de distribución de tráfico. Kubernetes ya proporciona esa distribución con el Service. No se debe copiar la base dentro de cada réplica. Si en el futuro se agregan uploads, deben moverse a almacenamiento compartido u object storage; si se cambian las sesiones a almacenamiento servidor, debe utilizarse un almacén compartido, por ejemplo Redis o PostgreSQL. Las migraciones deberían ejecutarse una vez mediante un Job o pipeline antes de ampliar a muchas réplicas.

La base PostgreSQL del ejemplo sigue siendo una instancia única. Para alta disponibilidad real se necesitaría replicación administrada por un operador o un servicio PostgreSQL gestionado, además de copias de seguridad y un diseño de failover.

## 7. Texto breve en inglés para el informe

### Persistent state and multiple application instances

> The application's durable business state is stored in PostgreSQL. Docker Compose stores the PostgreSQL data directory in the named `postgres_data` volume, Kubernetes mounts a PersistentVolumeClaim into the PostgreSQL pod, and the local Nomad deployment mounts a host volume outside the allocation. Therefore, replacing an application or database container does not remove the database files. The application does not currently enable Active Storage, so it has no persistent uploaded files. Rails uses signed client-side cookies for sessions, which means that session data is not stored in a specific application container.
>
> To run multiple application instances, all Rails instances must connect to the same PostgreSQL service and use the same `SECRET_KEY_BASE` so that every instance can verify signed cookies. A Kubernetes Service distributes requests among healthy Rails pods. If file uploads are added later, they should be moved to shared or object storage. A server-side session implementation would also require a shared session store. Database connection limits must be sized for the number of replicas, and schema migrations should be executed once before scaling the application.

### Kubernetes configuration

> The Kubernetes deployment uses separate Deployments for Rails and PostgreSQL. A ClusterIP Service provides stable internal database discovery, while a NodePort Service exposes the web application. Non-sensitive values are supplied by a ConfigMap, and PostgreSQL credentials and the Rails secret key are supplied by a Secret instead of being embedded in the image. PostgreSQL mounts a ReadWriteOnce PersistentVolumeClaim, so its data survives pod replacement. Startup, readiness, and liveness probes monitor both containers. The Rails Deployment maintains the desired replica count and automatically creates a replacement when a web pod is deleted.

### HashiCorp Nomad configuration

> The assigned HashiCorp Nomad deployment defines separate `database` and `web` task groups using the Docker driver. PostgreSQL data is mounted from a Nomad host volume, while credentials are read from Nomad Variables through task templates. PostgreSQL and Rails are registered with Nomad's native service provider and monitored with TCP and HTTP health checks. The Rails template uses `nomadService` to discover the current PostgreSQL address. Restart policies recover failed tasks, while the external host volume preserves the database across allocation or task restarts.

## 8. Limpieza

Kubernetes:

```text
kubectl delete -k k8s
```

El comando elimina también el PVC y, dependiendo de la política del storage class local, puede borrar los datos asociados. Usarlo solamente al terminar la demostración.

Nomad:

```text
nomad job stop book-reviews
```

Detener el job no elimina el directorio host de PostgreSQL. Su eliminación manual es destructiva y no es necesaria para volver a desplegar.

## 9. Consideraciones fuera del alcance local

- Los valores de `k8s/secret.yaml` son credenciales de demostración, no de producción.
- El clúster de un solo nodo y el agente Nomad `-dev` no proporcionan alta disponibilidad.
- El NodePort no incluye TLS ni un nombre de dominio; un entorno real usaría un Ingress o load balancer con certificados.
- Los volúmenes protegen contra el reinicio de contenedores/pods, pero no reemplazan una estrategia de backups.
- El seed puede depender de Open Library; `OPEN_LIBRARY_ENABLED=false` ofrece una ejecución local reproducible.

## 10. Validaciones realizadas sobre los archivos

Se ejecutaron las siguientes comprobaciones offline sobre el árbol final:

- `docker compose config --quiet`: Compose válido, con servicios `db` y `web` y volumen `postgres_data`.
- `kubectl kustomize k8s`: render exitoso de ocho recursos (Namespace, ConfigMap, Secret, PVC, dos Deployments y dos Services).
- Nomad 2.0.4 `nomad fmt -check`: formato HCL válido para el job y la configuración del agente.
- Nomad 2.0.4 `nomad job run -output`: parseo exitoso del job `book-reviews`, sus grupos `database`/`web`, las tareas Docker y el host volume.
- `git diff --check` y revisión de espacios finales/codificación de los archivos nuevos.

En el equipo donde se preparó esta entrega Docker Desktop no estaba iniciado y no estaban instalados Minikube, k3d ni Nomad como comandos permanentes. Por ello no se afirma una prueba viva de pods, allocations o persistencia. Las secuencias de las secciones 4 y 5 constituyen el procedimiento reproducible que debe ejecutarse con Docker y el clúster activos antes de presentar la demostración.

## 11. Referencias oficiales

- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/) y [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Nomad Docker task driver](https://developer.hashicorp.com/nomad/docs/deploy/task-driver/docker)
- [Nomad service block](https://developer.hashicorp.com/nomad/docs/job-specification/service)
- [Nomad host volumes](https://developer.hashicorp.com/nomad/docs/architecture/storage/host-volumes)
- [Nomad Variables](https://developer.hashicorp.com/nomad/docs/concepts/variables)
- [Nomad template functions for services and variables](https://developer.hashicorp.com/nomad/docs/job-specification/template)
