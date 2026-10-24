# Auditoría de campos — Módulo de Solicitudes (FideiNexus)

> Alcance: `vg-web-fideinexus-develop` · módulo `(tenant)/solicitudes`
> Fecha: 20/10/2026 · Mock activo (`environment.mockApi = true`) hasta conectar los microservicios.

---

## 1. Tabla `services` (solicitudes)

| Campo BD | Tipo | Dónde se consume | Estado | Nota |
|---|---|---|---|---|
| `id` | BIGSERIAL | lista, detalle, actas, calendario, reportes PDF/Excel | ✅ en uso | — |
| `tenant_id` | BIGINT | filtros de lista, creación, participantes | ✅ en uso | — |
| `service_type_id` | BIGINT | JOIN interno con `service_types` | ✅ en uso (backend) | El front lee `serviceTypeCode`, nunca el id |
| `church_id` | UUID | **solo Misa Especial** (lugar de la misa). Para sacramentos va en `celebration.church_id` | ✅ correcto | Los valores `church-uuid-001` se limpiaron; para sacramentos queda `NULL` |
| `description` | TEXT | form, detalle, lista, reportes | ✅ en uso | Límite backend: 2000 chars |
| `document_url` | TEXT | form (JSON de URLs) + galería del detalle | ✅ en uso | Límite backend subido de 1000 → **8000** chars |
| `scheduled_date` | DATE | form, detalle, lista, filtros, calendario, actas, reportes | ✅ en uso | — |
| `status` | VARCHAR(30) | todo el flujo | ✅ en uso | — |
| `request_date` | TIMESTAMP | lista, detalle, reportes | ✅ en uso | — |
| `certificate_id` | BIGINT | **no lo lee el front** (el acta se resuelve con `GET /certificates/service/{id}`) | ⚠️ lo usa el backend | Se mantiene |
| `response_data` | TEXT | **nadie la llenaba ni la leía** | 🗑️ **eliminada** (código + columna) | — |
| `created_at` / `updated_at` | TIMESTAMP | "Última Actualización", auditoría | ✅ en uso | — |

## 2. Campos virtuales de la interfaz `Service`

`Service` es la interfaz del **módulo de Solicitudes** y está limpia: solo campos
reales. Los que usaban Feligrés/Finanzas viven en `Request`, que la extiende.

| Campo (`Service`) | Estado | Nota |
|---|---|---|
| `serviceTypeCode` | ✅ **canónico** | `ServiceResponse` ya lo devuelve y el request lo acepta (también con el alias `serviceType`) |
| `serviceType` | 🗑️ eliminado del response | El front solo manda `serviceTypeCode` en el payload |
| `userId` | ✅ **corregido** | El backend lo calcula con `CHILD / CONFIRMED / GROOM / BRIDE` |
| `userName` | 🗑️ eliminado | El nombre se resuelve en el front con `/users/my-tenant` |
| `documentUrls` | ✅ virtual | Array parseado de `documentUrl` |
| `peopleId`, `priority`, `sacrament`, `mass`, `requestType` | ➡️ movidos a `Request` | **Los usan Finanzas y Feligrés**; Solicitudes no los usa (0 referencias) |

## 3. Tabla `service_participants`

| Campo | Estado | Nota |
|---|---|---|
| `id`, `tenant_id`, `service_id`, `user_id` | ✅ en uso | — |
| **`role`** | ✅ **en uso** | Identifica **qué papel tiene cada participante**: `CHILD`, `CONFIRMED`, `GROOM`, `BRIDE`, `FATHER`, `MOTHER`, `GODFATHER`, `GODMOTHER`, `GODPARENT`, `GROOMS_FATHER`, `GROOMS_MOTHER`, `BRIDES_FATHER`, `BRIDES_MOTHER`, `TITULAR`. El reporte de actas busca por este campo (`FATHER`, `MOTHER`, `GODFATHER`…) para escribir "Padre: X, Madre: Y" |
| `user_id` | ✅ **en uso** | Es el **id de la persona**: con él se trae el nombre desde `/users/feligreses` (`users` ⟕ `persons`) |
| `document_url` | ❌ **nadie la llenaba ni la leía** | 🗑️ **eliminada** (código + columna) |

> Resumen: `role` dice **qué papel tiene** (madre, padre, padrino) y `user_id` dice
> **quién es** (el nombre se resuelve con el servicio de usuarios).

## 4. Tabla `preparation`

| Campo | Estado | Nota |
|---|---|---|
| `id`, `tenant_id`, `service_id`, `type`, `session_date`, `status`, `attendance_status`, `notes`, `created_at`, `updated_at` | ✅ en uso | `type` ahora es `TITULAR \| EXAM` |
| `exam_score` | ✅ en uso, **escala 0-20** | Aprueba con 14 o más. Backend actualizado (dominio, DTO, comentarios) |
| `exam_passed` | 🗑️ **eliminado del front** | Se deriva de `exam_score >= 14`; el backend no lo guarda |
| **`attendance`** (asistencia por persona) | ✅ **creado** | Columna **JSONB** + DTO request/response + mapper + persistencia. Guarda quién asistió a cada sesión |
| readiness | ✅ **completo** | En **Confirmación** exige examen aprobado (≥ 14/20) para habilitar la celebración |
| `PUT /preparations/{id}` | ✅ **corregido** | Ya no pierde `status`, `attendance` ni `examScore` |

## 5. Tabla `celebration`

| Campo | Estado | Nota |
|---|---|---|
| `id`, `tenant_id`, `service_id`, `event_date`, `event_time`, `status`, `created_at`, `updated_at` | ✅ en uso | — |
| `church_id` | ✅ en uso | **Única** fuente de la iglesia del sacramento (se quitó del formulario). `String` para que coincida con la columna real |
| **`shift`** | ✅ **creado y aplicado** | Turno `MORNING \| AFTERNOON` (mañana/tarde). `ALTER TABLE` + backfill de las filas existentes |
| choque de horario | ✅ **validado** | `CelebrationScheduleConflictException` si se superpone con otra celebración |

## 6. Tabla `certificate` (actas)

| Campo | Estado | Nota |
|---|---|---|
| `id`, `service_id`, `celebration_id`, `signed`, `signed_at`, `issued_at`, `created_at`, `updated_at` | ✅ en uso | — |
| `tenant_id` | ✅ **corregido** | `generate()` ya lo setea |
| `signed_by_user_id` | ✅ **corregido** | `sign()` lo setea. El `sub` de Keycloak es un UUID (no numérico), así que el id lo manda el frontend (se busca por correo entre los feligreses de la parroquia) y el backend lo usa solo si es válido |
| **`certificate_number`, `book`, `folio`** | 🗑️ **eliminados** (código + columnas). Eran la referencia de "dónde quedó anotada la firma" en el libro parroquial, pero **nadie la entendía ni la usaba**: el Párroco firma a mano y el sistema solo deja constancia de que la firma se registró. El acta impresa (PDF/Excel) **tampoco** lleva esos huecos: solo las **líneas de firma** de quien tiene que firmar (párroco, padres, padrinos, contrayentes y testigos) |
| `certificate_type`, `main_person_id`, `main_person_name`, `certificate_data` | ✅ **eliminados** | No existían en la tabla; se sacaron del entity/mapper |
| Generar el acta | ✅ **automático** | Se genera sola al marcar la celebración como **Realizada** (lo hace el servicio de celebraciones). `generate()` es **idempotente**: si la solicitud ya tiene acta, devuelve la misma en vez de crear otra (antes se generaban 2 y el actuator se rompía al buscar por `serviceId`) |

## 7. Campos de persona que consume este módulo (auth 8100)

> El servicio de usuarios (`vg-ms-auth-develop`) **es de otro equipo y no se toca**.
>
> En la base que usa (`login`), la tabla `users` solo tiene la cuenta
> (`id`, `tenant_id`, `email`, `role_id`, `status`, `created_at`, `updated_at`) y
> los datos de persona (`name`, `lastname`, `phone`, `number_document`) están en
> la tabla `persons`, enlazada por `persons.user_id = users.id`.
>
> **Problema actual (del auth, no de este módulo):** su entidad `User` mapea
> `name/lastname/phone/dni/password_hash` sobre `users`, columnas que no existen
> → `GET /users/my-tenant` responde **500** (`column users.name does not exist`).
> Lo tiene que arreglar quien owns ese servicio, de una de estas dos formas:
> 1. Que su entidad haga `JOIN persons` (lo que hace falta de verdad), o
> 2. Que su base agregue esas 5 columnas a `users`.
>
> Mientras tanto este módulo **no se rompe**: si la carga de personas falla,
> `getUserName()` devuelve `ID: <userId>` y las listas, el detalle, las actas y
> los reportes siguen funcionando con los demás datos reales.

| Campo | Dónde vive | Uso en Solicitudes |
|---|---|---|
| `id` | `users.id` | `userId` de participantes, selección de personas |
| `tenant_id` | `users.tenant_id` | filtros |
| `name`, `lastname` | `persons.name`, `persons.lastname` | nombres en tablas, detalle y reportes PDF/Excel |
| **`dni`** | `persons.number_document` | Detalle de participantes, modal de actas, filtros |
| `phone` | `persons.phone` | datos de contacto en el detalle |
| `email` | `users.email` | módulo Personas (no en Solicitudes) |
| `role` | `roles.name` (vía `users.role_id`) | rol del sistema (PÁRROCO/SECRETARIO/FELIGRES) — **distinto** del rol en la solicitud (`service_participants.role`) |
| `status` | `users.status` | filtro |
| `documentType`, `birthdate`, `gender`, `civilStatus`, `address` | `persons.*` | **No se usan** en el módulo de Solicitudes |

> Conclusión sobre el DNI: el campo **sí existe** y se llama `dni`. Se consume correctamente en `solicitud-detail` y en el modal de actas.

## 8. Endpoints consumidos y su estado real

> **Verificado end-to-end el 21/10/2026** con los 3 usuarios reales del Keycloak
> (`prs-realm`) contra el gateway local (`http://localhost:8765/api/v1`).
> Los tokens expiran a los 5 minutos, hay que re-loguearse para repetir la prueba.

| Endpoint | Servicio | Puerto | Qué hace | Estado |
|---|---|---|---|---|
| `GET /service-types` | requests | 8087 | Catálogo de sacramentos (`code` + `sacramentId`) | ✅ 200 |
| `GET /services?tenantId=9` | requests | 8087 | Lista las solicitudes del tenant con `serviceTypeCode`, `sacramentId` y `userId` | ✅ 200 |
| `GET /services/{id}` | requests | 8087 | Detalle de una solicitud | ✅ 200 |
| `PATCH /services/{id}/status` | requests | 8087 | Aprobar / rechazar una solicitud | ✅ 200 |
| `GET /service-participants/service/{id}` | requests | 8087 | Participantes de la solicitud (rol TITULAR/CHILD/PADRINO…) | ✅ 200 |
| `POST /service-participants` | requests | 8087 | Alta de participante | ✅ 200 |
| `GET /preparations/service/{id}` | preparation | 8097 | Ficha de preparación (asistencia, examen, requisitos) | ✅ 200 |
| `POST /preparations` | preparation | 8097 | Crea la preparación | ✅ 200 |
| `PUT /preparations/{id}` | preparation | 8097 | Actualiza **sin perder** `status`, `attendance`, `examScore` | ✅ 200 |
| `GET /preparations/service/{id}/readiness` | preparation | 8097 | ¿Se puede celebrar? (en Confirmación exige examen ≥ 14/20) | ✅ 200 |
| `GET /preparations/service/{id}/tariff` | preparation | 8097 | Tarifa del sacramento (join con `tarifario.idServicio`) | ✅ 200 |
| `GET /celebrations/service/{id}` | celebration | 8098 | Celebración (iglesia, fecha, turno) | ✅ 200 |
| `GET /celebrations/status/{status}` | celebration | 8098 | Celebraciones por estado | ✅ 200 |
| `POST /celebrations` | celebration | 8098 | Crea la celebración (valida choque de horario) | ✅ 200 |
| `PUT /celebrations/{id}` | celebration | 8098 | **Edita** la celebración (iglesia, fecha, hora y turno); no toca el estado | ✅ 200 (nuevo en uso) |
| `PATCH /celebrations/{id}/status` | celebration | 8098 | Cambia el estado de la celebración; al marcar **REALIZED** genera el acta | ✅ 200 |
| `GET /certificates?signed=true` | certificate | 8099 | Actas firmadas / pendientes de firma | ✅ 200 |
| `GET /certificates/service/{id}` | certificate | 8099 | Acta de una solicitud | ✅ 200 |
| `POST /certificates` | certificate | 8099 | Genera el acta. **Idempotente**: si ya existe, devuelve la misma | ✅ 200 |
| `PATCH /certificates/{id}/sign` | certificate | 8099 | Registra la **firma manual** (`signedByUserId`); `certificateNumber`/`book`/`folio` son opcionales | ✅ 200 |
| `GET /users/my-tenant` | auth | 8100 | Personas de la parroquia (todas, con su rol). **Sin parámetros**: el tenant va en el token | ✅ 200 |
| `GET /v1/users/feligreses?tenantId=9` | auth | 8100 | **Feligreses de la parroquia** (FELIGRES/PADRINO/MADRINA) con rol, DNI y teléfono; el personal (párroco/secretario/superadmin) queda fuera. Valida el tenant contra el token → **403** si es otra parroquia | ✅ 200 |
| `GET /tenants/9` | tenants | 8081 | Nombre y diócesis de la parroquia | ✅ 200 |
| `GET /tenant-details/9` | tenants | 8081 | **`logoUrl`**, dirección, teléfono → logo de los reportes | ✅ 200 |
| `GET /tarifario?tipoServicio=SACRAMENTO&estado=A` | tenants | 8081 | Tarifario vigente | ✅ 200 |
| `GET /churches/active?tenantId=9` | churches | 8085 | Iglesias del tenant (para la celebración) | ✅ 200 |
| `GET /masses/active` | mass | 8091 | Misas para el calendario | ✅ 200 (403 para SUPERADMIN, es diseño de ese servicio) |

> Nota de ruta: el microservicio de usuarios expone `/api/users/**` (no `/api/v1/users/**`),
> por eso el frontend llama a `${apiBaseUrl}/users` y no a `${apiUrl}/users`.

### 8.1 Matriz de roles (verificada)

| | PARROCO | SECRETARIO | SUPERADMIN |
|---|---|---|---|
| Los 4 microservicios de Solicitudes | ✅ 200 | ✅ 200 | ✅ 200 |
| `users/my-tenant` | ✅ 200 | ✅ 200 | 403 (diseño del auth) |
| `tenants`, `tenant-details`, `tarifario` | ✅ 200 | ✅ 200 | ✅ 200 |
| `churches/active` | ✅ 200 | ✅ 200 | ✅ 200 |
| `masses/active` | ✅ 200 | ✅ 200 | 403 (diseño del mass) |
| **Crear solicitud** (`POST /services`) | ✅ | ✅ | — |
| **Registrar participantes** | ✅ | ✅ | — |
| **Editar solicitud PENDIENTE** | ✅ | ✅ | — |
| **Editar solicitud APROBADA** | ❌ 409 | ❌ 409 | ❌ 409 |

> Los 4 microservicios de Solicitudes aceptan `SECRETARIO`, `PARROCO` y `SUPERADMIN`.
> El `403` (y no `500`) lo devuelve el `GlobalExceptionHandler` de cada servicio.
> Los **participantes** también los puede registrar el `PARROCO` (antes solo
> `SECRETARIO`/`ADMIN`/`SUPERADMIN`, y el frontend se tragaba el 403).
> **Regla de estados**: una solicitud solo se edita mientras está `PENDING`;
> desde que se aprueba, el expediente ya no se toca (ni la solicitud ni sus
> participantes) → **409**.

### 8.2 Logo institucional en PDF y Excel

| Paso | Dónde | Qué hace |
|---|---|---|
| 1 | `tenant.service.ts` → `GET /tenant-details/{id}` | Trae `logoUrl` (`tenant_details.logo_url`) |
| 2 | `solicitud-list.ts`, `solicitud-detail.ts` | Pasan el `logoUrl` al contexto del reporte |
| 3 | `solicitudes-report.service.ts` → `loadLogo()` | Descarga la imagen y la **normaliza a PNG** (el logo real del tenant 9 es `.webp`; jsPDF/ExcelJS no lo aceptan) |
| 4 | `solicitudes-report.service.ts` → `fitLogo()` | Escala el logo dentro del recuadro **sin deformarlo** (el logo real es 1280×720) |
| 5 | `actas-report.service.ts` → `loadLogoFromUrl()` | Mismo proceso para las actas (Bautismo/Confirmación/Matrimonio) |

> Verificado: el PDF generado pesa 2,7 MB y contiene **1 XObject de imagen** (el logo);
> el `.xlsx` contiene **`xl/media/image1.png` (708 KB, PNG válido)**.

### 8.3 Tarjeta "Acta Sacramental" (cómo queda)

| Momento | Qué muestra | Qué puede hacer el párroco |
|---|---|---|
| Celebración **Programada** | Sección de celebración con fecha, hora, turno, iglesia | "Editar celebración" (abre el formulario **con los datos guardados**), "Marcar como Realizada", "Cancelar celebración" |
| Al marcar **Realizada** | El acta se genera sola | Aparece la tarjeta del acta con el botón **"Descargar acta"** (para imprimir y firmar a mano) |
| Acta sin firmar | "Generada — pendiente de registrar la firma" + aviso "Acta lista para imprimir y firmar" | **"Descargar acta"** y **"Registrar firma"** (un solo botón: la firma se hace en el libro, no hay datos que escribir) |
| Acta firmada | "Firmada y registrada en el libro parroquial" | "Descargar acta" |

> La firma es **manual**: el Párroco y los demás firmantes firman en el libro
> parroquial. El sistema solo deja constancia de que la firma se registró (quién y
> cuándo). El PDF/Excel del acta sale con los huecos en blanco para anotar a mano.

---

## 9. Campos / pantallas eliminados en esta pasada

| Elemento | Motivo |
|---|---|
| `priority` (interfaz, reportes PDF y Excel) | No existe en BD; el backend la quitó. Salía siempre `—` |
| `Resumen por Prioridad` (PDF y Excel) | Dependía de `priority` → ahora "Resumen por Tipo de Sacramento" |
| `ID Parroquia: PSA-T1` | Identificador inventado |
| `PARROQUIA SAN PEDRO APÓSTOL`, `IGLESIA CRISTIANA NUEVA VIDA`, `"Mushuj Kausai"`, `Personería Jurídica Especial 7742 de 2013` | Datos de otras parroquias hardcodeados → ahora salen del tenant |
| `M.I.SR. CANGO. ERNESTO REYNOSO Y VALLE` | Nombre de párroco inventado |
| `Sede: Avenida B No. 14-99, ... El Páramo` | Dirección inventada |
| `Diócesis de Cañete y Yauyos` fijo | Ahora sale de `tenant.diocese` / `tenantDetails` |
| `FIDEI NEXUS v2.0` | Versión inventada |
| Emojis `⛪ 📋 ✅ ⚠️ 📅 📊 ⭐ 💡` | Sustituidos por iconos SVG |
| Campo **Iglesia** del formulario de solicitud | La iglesia se define en la celebración |
| **Iglesia** en "Información de la Solicitud" | Idem (solo se muestra como "Lugar de la Misa" en Misa Especial) |
| Columna `#SOL-1` de la tabla de actas | Ahora muestra el tipo de sacramento (Bautismo/Confirmación/Matrimonio) |
| Columna "ID Acta" (`ACT-1`) | Ruido técnico; se conserva el dato en el modal |
| Pestaña **Archivo Histórico** | El microservicio de libros parroquiales ya no existe; la búsqueda por nombre quedó en el buscador principal sobre los 3 sacramentos |
| Examen `55/100` | Ahora `11/20` (escala de 20, aprueba con 14) |
| `effectivePriority` del contexto de reportes | Campo inexistente |
| `font-extrabold` sin tracking en títulos | Se ve deformado con la fuente de sistema → `Inter` + `font-bold tracking-tight` |

## 10. Pendientes / fuera del frontend (estado a 21/10/2026)

| # | Tema | Estado |
|---|---|---|
| 1 | `ServiceResponse` devuelve **`serviceTypeCode`** (único nombre; `serviceType` acepta como alias) | ✅ resuelto |
| 2 | `ServiceResponse.userId` calcula el titular con `CHILD/CONFIRMED/GROOM/BRIDE` | ✅ resuelto |
| 3 | `preparation`: columna `attendance` (JSONB), `PUT` que no pierde `status`/`attendance`/`examScore`, `readiness` con examen ≥ 14/20 | ✅ resuelto (3 ALTER en tu BD) |
| 4 | `certificate`: columnas inexistentes fuera, `tenantId` al generar, `signedByUserId` al firmar | ✅ resuelto |
| 5 | `requests`: límite de `document_url` subido a 8000 caracteres | ✅ resuelto |
| 6 | Gateway: enrutar `/api/v1/users` y `/api/v1/admin` hacia auth | ✅ resuelto (1 archivo, default intacto) |
| 7 | `payments`: `GET /payments/service/{serviceId}` | ❌ sigue sin existir → la llamada de pago del detalle es inútil (no bloquea Solicitudes) |
| 8 | `service_participants.document_url` | ✅ **eliminada** (código + columna). Los adjuntos están en `services.document_url` |
| 9 | `services.response_data` | ✅ **eliminada** (código + columna): nadie la llenaba ni la leía |
| 10 | `celebration.shift` (`MORNING`/`AFTERNOON`) | ✅ resuelto (ALTER + backfill) |
| 11 | `users` del auth sin `name/lastname/phone/dni` | ✅ **resuelto**: el auth ahora hace `JOIN persons` y `/users/my-tenant` responde 200 con los nombres reales |
| 12 | Tablas ajenas en tu base (`events`, `event_reactions`, `organizations`, `audit_logs`, `payments`) | ✅ **eliminadas**. Venían del stack del lab (event/organization/payments apuntando a tu base); el respaldo quedó en el TEMP. Vuelven si en el `environment:` del Compose esas variables no apuntan a su propio proyecto |
| 13 | `SELECT s.*` en las consultas con JOIN | ✅ **corregido**: ahora se listan las columnas una por una. Con `s.*` el texto de la consulta no cambia, Postgres reutiliza el plan cacheado y al quitar una columna falla con *"cached plan must not change result type"* |
| 14 | `GlobalExceptionHandler` se tragaba la excepción (500 genérico sin log) | ✅ **corregido en los 4**: ahora loguea el error real |
| 15 | Keycloak del lab | ✅ arriba (200) — ya se puede iniciar sesión con las 3 credenciales |
| 16 | **"Ver Actas" mandaba al inicio** | ✅ **corregido**: el botón leía el `tenantId` del snapshot **propio** (que no lo tiene) y caía en `org-1`, una ruta inexistente → el guard redirigía al inicio. Ahora usa la ruta padre y, si no está, el tenant del token |
| 17 | **El PÁRROCO no podía registrar participantes** (403) | ✅ **corregido**: los endpoints de participantes soloaban a `SECRETARIO/ADMIN/SUPERADMIN`. El frontend se tragaba el error (`catchError`) y la solicitud quedaba **sin titular ni padrinos** — de ahí el "se guardó pero está vacío". Ahora el párroco sí puede y, si algún participante falla, se avisa con un aviso en vez de fallar en silencio |
| 18 | **Actas duplicadas** | ✅ **corregido**: al marcar la celebración como Realizada, el backend genera el acta y el frontend la generaba otra vez (2 actas para la misma solicitud → `GET /certificates/service/{id}` fallaba). Ahora el frontend solo recarga y `generate()` es idempotente |
| 19 | **"Firmar Acta" daba 500** | ✅ **corregido**: el `sub` del token de Keycloak es un UUID y `Long.valueOf(sub)` reventaba. Ahora el id del usuario llega desde el frontend (se busca por correo) y, si no hay, se guarda `null` en vez de `0` |
| 20 | **Editar la celebración** | ✅ **nuevo**: el botón "Editar celebración" abre el formulario **con los datos guardados** (iglesia, fecha, hora y turno) y los actualiza con `PUT /celebrations/{id}` |
| 21 | **"Descargar mi acta" exigía la firma** | ✅ **corregido**: el acta se descarga para imprimir y firmar a mano; ya no pide la firma registrada |
| 22 | **Tarifario sin tarifa activa para Bautismo y Matrimonio** | 🔴 **del tarifario (otro servicio)**: `canProceed` de la preparación exige tarifa vigente y solo hay para **Confirmación** y **Misa especial**. Con una Confirmación el flujo va completo; con Bautismo o Matrimonio el servicio de celebraciones responde *"Preparation is not completed"* |
| 23 | **"Editar solicitud" abría el formulario vacío** | ✅ **corregido**: el formulario ahora carga lo ya guardado (tipo de sacramento, fecha, descripción, adjuntos y **participantes con su nombre**). Antes solo cargaba el tipo y la fecha |
| 24 | El botón **"Editar"** solo aparecía en estado PENDING | ✅ **regla final**: la solicitud **solo se puede editar mientras está PENDIENTE**. Al aprobarla ya no se toca. Se aplicó **también en el backend** (`PUT /services/{id}` y los endpoints de participantes devuelven **409** si la solicitud no está pendiente), no solo escondiendo el botón |
| 25 | Botón **"Restaurar"** | 🗑️ **eliminado**: el backend borra la solicitud en firme (`DELETE /services/{id}`), no hay nada que restaurar y el botón solo sacaba un error |
| 26 | Participantes que apuntaban a **personas inexistentes** (`userId` 33, 34, 36) | ✅ **corregido en los datos**: en las actas salía "ID: 33". Ahora cada rol apunta a una persona que sí existe en la base del auth y las descripciones coinciden |
| 27 | `payments`: `GET /payments/service/{serviceId}` | ❌ sigue sin existir → la llamada de pago del detalle es inútil (no bloquea Solicitudes) |
| 28 | Servicio de iglesias (`locations`, 8085) y de misas (`mass`, 8091) devuelven **500 a ratos** | 🔴 **de otros servicios**: su pool de conexiones no retira las conexiones inactivas (Neon las cierra a los ~5 min) → la primera consulta tras la inactividad falla y la siguiente ya funciona. Se arregla con `max-idle-time: 30s` en su `application.yml` (los 4 micros de Solicitudes ya lo tienen) |

## 11. Cumplimiento de los estándares PRS241 (auditado con los skills oficiales)

| Estándar | requests | preparation | celebration | certificate | Frontend |
|---|---|---|---|---|---|
| **ProjectArchitecture** (arquitectura hexagonal, 14 reglas del checklist de PR) | ✅ 14/14 | ✅ 14/14 | ✅ 14/14 | ✅ 14/14 | ✅ |
| **DatabaseStorage** (17 criterios) | ✅ **100%** | ✅ **100%** | ✅ **100%** | ✅ **100%** | — |
| **Backend AS241S6** (12 criterios) | ✅ **CUMPLE** (4.6/5) | ✅ **CUMPLE** (4.7/5) | ✅ **CUMPLE** (4.7/5) | ✅ **CUMPLE** (4.7/5) | — |
| **Security** (SEC-001..022) | ✅ **100%** | ✅ **100%** | ✅ **100%** | ✅ **100%** | ⚠️ 81,8% |
| **Frontend** (16.1–16.6) | — | — | — | — | ✅ **100%** (el módulo) |
| **Reports PRS3** (reportes 100% client-side) | ✅ | ✅ | ✅ | ✅ | ✅ |

**Lo que se hizo para llegar ahí:**

| Hallazgo | Corrección |
|---|---|
| **TEN-03**: borrado físico | Baja lógica: la solicitud queda con `status = DELETED` (y el listado la excluye); participantes y sesiones usan la columna `deleted_at` |
| **NOM-01**: tablas en singular | `preparations`, `celebrations`, `certificates` (migración `ALTER TABLE ... RENAME`) |
| **SEC-017**: validaciones en 400 | Ahora devuelven **422** (401/403/404/409/422 diferenciados) |
| **SEC-012**: swagger/actuator abiertos | Cerrados en el perfil de producción |
| **SEC-019**: sin bitácora de auditoría | Tabla `audit_log` (tenant, actor, acción, recurso, resultado, fecha) + registro en CREATE/UPDATE/STATUS/DELETE/SIGN/REALIZE de los 4 micros |
| **SEC-022**: sin control de concurrencia | `@Version` (versionado optimista) + índices únicos por clave natural (una celebración y un acta por solicitud) |
| **Backend**: rutas fuera de `/api/v1` | Retirados los alias `/api/services` y `/api/requests` (que ya no usaba nadie; el gateway enruta a `/api/v1/requests`) |
| **ProjectArchitecture**: faltaba `.gitlab-ci.yml` | Creado en los 4 con el job `standards-check` |
| **ProjectArchitecture**: Postman desactualizado | Carpeta `ServiceRest`, `ParishBookRest` eliminada, `GET /service/{serviceId}` agregado |

> **SEC-015** (TLS en producción) queda como *REQUIERE_REVISION_MANUAL* en los 4 micros: la configuración de producción se inyecta por variables de entorno y no es inspeccionable desde el repositorio. En la base local la URL sí lleva `sslmode=require`.
