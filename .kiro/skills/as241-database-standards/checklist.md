# Checklist de Control y Auditoría PRS241 — DatabaseStorage

Usar durante la revisión de Pull Requests antes de fusionar a rama principal.

## Categoría 1 — Arquitectura Hexagonal y DDD

- [ ] **HEX-01 · CRÍTICA** — El modelo de negocio en `domain.model` es un POJO limpio. Cero anotaciones `@Table`, `@Document`, `@Id` o `@Column`.
- [ ] **HEX-02 · ALTA** — La capa de aplicación/dominio únicamente conoce el puerto de salida (`RepositoryPort`). No importa Spring Data ni MongoDB directamente.
- [ ] **HEX-03 · ALTA** — La entidad técnica y el repositorio Spring Data residen exclusivamente dentro de `infrastructure.adapters.out.persistence`.
- [ ] **HEX-04 · MEDIA** — Se implementa un mapper para la conversión bidireccional entre `Model` (dominio) y `Entity/Document` (infraestructura).

## Categoría 2 — Stack Reactivo No Bloqueante

- [ ] **REC-01 · CRÍTICA** — No existen dependencias JDBC ni JPA en el `pom.xml` (`spring-boot-starter-data-jpa`, `hibernate-core`, `mysql-connector-java`, `spring-boot-starter-jdbc`).
- [ ] **REC-02 · CRÍTICA** — Se utilizan `ReactiveCrudRepository`, `ReactiveMongoRepository` o `DatabaseClient`. El `pom.xml` tiene `spring-data-mongodb-reactive` o `spring-data-r2dbc` + `webflux`.
- [ ] **REC-03 · CRÍTICA** — Todos los métodos de repositorio retornan `Mono<T>` o `Flux<T>`. No se hace uso de `.block()` ni `.toStream()` fuera de tests.

## Categoría 3 — Nomenclatura Estricta (Strictly English)

- [ ] **NOM-01 · MEDIA** — Tablas y colecciones en plural o semántica en minúsculas en inglés: `tenants`, `organization`, `organization_modules`, `users`. Sin nombres en español.
- [ ] **NOM-02 · MEDIA** — Columnas en `snake_case` singular en inglés: `first_name`, `created_at`, `organization_id`. Sin: `fechaCreacion`, `estaActivo`.
- [ ] **NOM-03 · MEDIA** — Código Java (clases, atributos, métodos, variables) 100% en inglés y con nombres semánticos. Sin: `obtenerTodo()`, `guardarAlerta()`.

## Categoría 4 — Integridad, Multi-Tenancy y Soft Delete

- [ ] **TEN-01 · CRÍTICA** — La tabla/colección cuenta con columna de tenant (`tenant_id`, `institucion_id` u `organization_id`) debidamente indexada.
- [ ] **TEN-02 · ALTA** — Todas las consultas de negocio filtran por el tenant/organización. No existen `findAll()` sin filtro de tenant.
- [ ] **TEN-03 · ALTA** — No se realizan borrados físicos (`DELETE`). Soft delete implementado: `active = false`, `deleted_at = now()`, o `status = 'INACTIVE'`.
- [ ] **TEN-04 · MEDIA** — Se registran marcas de tiempo de auditoría en UTC: `created_at` y `updated_at` con tipo `LocalDateTime` o `Instant`.

## Categoría 5 — Seguridad y Storage Offloading

- [ ] **SEC-01 · ALTA** — No se guardan binarios ni Base64 en la base de datos. Archivos delegados a Cloudinary o MinIO; solo se guarda la URL HTTPS.
- [ ] **SEC-02 · ALTA** — Conexiones a BD exigen TLS/SSL: `mongodb+srv://` o `sslmode=require` o `ssl=true` en `application.yml`.
- [ ] **SEC-03 · CRÍTICA** — No existen credenciales en texto plano en `application.yml`. Todo se inyecta con `${VAR_NAME:default}`.

---

## Severidades

| Severidad | Criterios |
|---|---|
| CRÍTICA | HEX-01, REC-01, REC-02, REC-03, TEN-01, SEC-03 |
| ALTA | HEX-02, HEX-03, TEN-02, TEN-03, SEC-01, SEC-02 |
| MEDIA | HEX-04, NOM-01, NOM-02, NOM-03, TEN-04 |

**Un criterio CRÍTICO fallando = NO CUMPLE → bloquea el PR.**
