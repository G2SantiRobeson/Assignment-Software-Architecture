# Investigación: HashiCorp Nomad (Grupo 7)

```text
Orquestador asignado al Grupo 7: HashiCorp Nomad
Estado en la Entrega 2: INVESTIGACIÓN SOLAMENTE
Implementación requerida: NO
Despliegues implementados: Docker Compose y Kubernetes local
```

Este documento proporciona la base técnica solicitada sin definir jobs,
agentes, servicios ni volúmenes Nomad. La aclaración del profesor prevalece:
Nomad no reemplaza el despliegue Kubernetes de este repositorio.

## Qué es Nomad

Nomad es un planificador y orquestador de cargas de trabajo. El usuario declara
un estado deseado como un *job* y los servidores Nomad deciden en qué clientes
ejecutar sus tareas. Puede ejecutar contenedores y también otras cargas mediante
drivers, por lo que su alcance no está limitado a Docker.

## Conceptos centrales

- **Servidor:** acepta jobs, mantiene el estado del clúster, administra clientes,
  crea evaluaciones y calcula ubicaciones. En una región, los servidores forman
  un grupo de consenso y eligen un líder.
- **Cliente:** agente que registra recursos y drivers disponibles, envía
  *heartbeats* y ejecuta las allocations asignadas.
- **Job:** declaración de estado deseado y unidad superior de una carga.
- **Task group:** conjunto de tareas que deben ubicarse juntas en un mismo
  cliente; es la unidad de scheduling.
- **Task:** unidad mínima de ejecución. Declara driver, configuración, recursos y
  restricciones.
- **Allocation:** asociación creada por el scheduler entre un task group y un
  cliente concreto.
- **Scheduler:** procesa evaluaciones cuando cambia el estado deseado o real,
  filtra y puntúa clientes y genera un plan de allocations. Nomad utiliza
  *bin-packing* y considera restricciones y afinidades.
- **Driver:** mecanismo que ejecuta una tarea. Docker es un driver incluido;
  también existen drivers para Java, QEMU y procesos, además de plugins.

Fuentes oficiales: [arquitectura de Nomad](https://developer.hashicorp.com/nomad/docs/architecture),
[glosario](https://developer.hashicorp.com/nomad/docs/glossary) y
[scheduling](https://developer.hashicorp.com/nomad/docs/concepts/scheduling/how-scheduling-works).

## Contenedores

Con el driver Docker, una tarea indicaría conceptualmente la imagen, red,
puertos, variables, recursos y política de reinicio. El cliente necesita Docker
disponible y habilitado. Nomad programa la allocation; el driver crea y supervisa
el contenedor. Esto permite usar la misma imagen Rails que Docker/Kubernetes,
pero ese jobspec no forma parte de esta entrega.

Fuente oficial: [task drivers de Nomad](https://developer.hashicorp.com/nomad/docs/deploy/task-driver).

## Servicios y red

Un bloque de servicio puede registrar una carga mediante el proveedor nativo de
Nomad o mediante Consul, y puede asociar checks HTTP o TCP. Consul aporta un
catálogo y capacidades más amplias para descubrimiento, DNS, health-based routing
y service mesh; es una integración común, pero no es obligatorio para todo uso de
Nomad porque existe service discovery nativo.

Fuentes oficiales: [service discovery](https://developer.hashicorp.com/nomad/docs/networking/service-discovery) y
[declaración de service discovery](https://developer.hashicorp.com/nomad/docs/job-declare/service-discovery).

## Almacenamiento persistente

Nomad admite varias opciones conceptuales para cargas con estado:

- volúmenes CSI administrados mediante plugins de terceros;
- volúmenes host dinámicos o estáticos;
- volúmenes proporcionados por el driver, como drivers de volumen Docker.

La ubicación y el modo de acceso condicionan el scheduling. PostgreSQL no debe
depender del filesystem efímero de una allocation: requeriría almacenamiento
persistente y una estrategia operativa de respaldo/recuperación.

Fuentes oficiales: [stateful workloads](https://developer.hashicorp.com/nomad/docs/stateful-workloads) y
[plugins CSI](https://developer.hashicorp.com/nomad/docs/architecture/storage/csi).

## Configuración y secretos

- **Nomad Variables** almacena configuración o secretos cifrados en el state
  store, replicados entre servidores y protegidos mediante ACL.
- Un bloque **template** puede renderizar archivos o variables de entorno y
  reaccionar a cambios de configuración.
- **Vault** puede entregar secretos estáticos o dinámicos usando identidades de
  workload y políticas de mínimo privilegio. Vault es una opción para necesidades
  avanzadas, no un requisito para este proyecto académico.

Fuentes oficiales: [Nomad Variables](https://developer.hashicorp.com/nomad/docs/concepts/variables),
[template block](https://developer.hashicorp.com/nomad/docs/job-specification/template) y
[workload identity con Vault](https://developer.hashicorp.com/nomad/docs/secure/workload-identity/vault).

## Self-healing y escalamiento

Nomad compara el estado real con el deseado. Ante una tarea fallida puede
reiniciarla localmente según la política `restart`; si la allocation falla, una
política de rescheduling permite crear otra allocation, incluso en otro cliente.
Para un servicio, aumentar el `count` del task group crea múltiples allocations.
Un bloque de scaling puede definir mínimos/máximos para escalamiento manual o
para un autoscaler externo.

Fuentes oficiales: [restart](https://developer.hashicorp.com/nomad/docs/job-declare/failure/restart),
[declaración de jobs](https://developer.hashicorp.com/nomad/docs/job-declare) y
[scaling block](https://developer.hashicorp.com/nomad/docs/job-specification/scaling).

## Comparación concisa: Nomad y Kubernetes

| Aspecto | Nomad | Kubernetes |
| --- | --- | --- |
| Complejidad | API y modelo operativo más pequeños | Más componentes y abstracciones |
| Ecosistema | Integraciones fuertes con herramientas HashiCorp; menor extensión | Ecosistema cloud-native y de operadores muy amplio |
| Scheduling | Jobs, groups, tasks, evaluations y allocations; varias clases de carga | Pods y controladores declarativos como Deployments, Jobs y StatefulSets |
| Networking | Flexible pero requiere seleccionar/proveer la solución de red | Modelo de red y Services estandarizados; implementación mediante CNI |
| Service discovery | Proveedor nativo ligero o Consul | Services y DNS integrados normalmente mediante CoreDNS |
| Storage | Host volumes, drivers y CSI | PV/PVC, StorageClasses y CSI |
| Configuración | Variables y templates | ConfigMaps y Secrets |
| Secretos | Variables; Vault opcional | Secrets; gestores externos opcionales |
| Curva de aprendizaje | Menor superficie inicial | Mayor superficie, con más patrones ya estandarizados |
| Operación | Servidores/clientes Nomad; integraciones se eligen aparte | Control plane/nodes; distribuciones empaquetan componentes comunes |

La elección depende del contexto. Kubernetes ofrece el modelo que exige esta
entrega y una portabilidad/ecosistema mayores. Nomad puede ser atractivo cuando
se valora un scheduler general y una superficie operativa compacta.

## Mapeo conceptual de Rails + PostgreSQL

Sin constituir una implementación, la arquitectura podría razonarse así:

```text
Nomad cluster
   |
   +-- Rails service job
   |     +-- N allocations (Docker image Rails)
   |     +-- HTTP service registration and health check
   |     +-- shared database endpoint and common Rails secrets
   |
   +-- PostgreSQL stateful workload
         +-- one database allocation
         +-- stable service registration
         +-- persistent volume
```

Todas las allocations Rails compartirían PostgreSQL y el mismo secreto
criptográfico. Los uploads, una caché coherente y las sesiones server-side (si
se agregaran) necesitarían servicios compartidos. Las migraciones deberían
ejecutarse una sola vez antes de aumentar el número de instancias. Este mapeo es
solo arquitectura conceptual: no se crean archivos `*.nomad`, jobs ni agentes.
