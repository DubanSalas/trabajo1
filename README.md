# FideiNexus — PRS Microservices
### Sistema de Gestión Parroquial — AS241S6

---

## Descripción del Proyecto

FideiNexus es un sistema de gestión parroquial desarrollado bajo una arquitectura de microservicios desacoplados. Cada microservicio es independiente, tiene su propia base de datos y se comunica con los demás mediante HTTP reactivo (WebClient). Todo el sistema corre en el VPS del Instituto Valle Grande, orquestado con Docker Compose, Nginx y Dokploy, con base de datos PostgreSQL serverless en Neon Cloud.

---

## Microservicios del PRS

| Microservicio | Responsable | Tipo | Puerto |
|---|---|---|---|
| vg-web-fideinexus | Equipo PRS | Frontend | — |
| vg-ms-peopleservice | Jennifer C.C. | Maestro | 8082 |
| vg-ms-booksservice | Jennifer C.C. | Maestro | 8088 |
| vg-ms-authservice | Leonardo | Maestro | 8080 |
| vg-ms-massesservice | Kevin H.V. | Transaccional | 8091 |
| vg-ms-scheduleservice | Jeanpier V.L. | Transaccional | 8094 |
| vg-ms-eventservice | Jeanpier V.L. | Transaccional | 8092 |
| vg-ms-organizationservice | Jeanpier V.L. | Maestro | 8093 |
| vg-ms-requestsservice | Duban S.N. | Transaccional | 8087 |
| vg-ms-tenantservice | Carlos Tomi | Maestro | 8081 |
| vg-ms-paymentservice | Carlos Tomi / Luis H. | Transaccional | 8086 |
| vg-ms-sacramentservice | (responsable) | Maestro | 8083 |
| vg-ms-sacramentrecords | (responsable) | Transaccional | — |

---

## 1. Denominación de Repositorios

### Convención de nombres

Todos los repositorios siguen esta convención:

```
vg-ms-{nombre-del-servicio}     → microservicios backend
vg-web-{nombre-del-proyecto}    → aplicación frontend
```

### Ejemplos correctos

```
vg-ms-requestsservice
vg-ms-peopleservice
vg-ms-massesservice
vg-ms-tenantservice
vg-ms-paymentservice
vg-web-fideinexus
```

### Reglas de denominación

- Todo en minúsculas sin excepción
- Sin espacios, tildes ni caracteres especiales
- Usar guión medio `-` como único separador
- El prefijo `vg-ms-` identifica microservicio backend del proyecto Valle Grande
- El prefijo `vg-web-` identifica aplicación web frontend
- El nombre del servicio debe ser descriptivo y en inglés

### Errores de denominación que NO se deben cometer

```
VG-MS-RequestsService       ← no usar mayúsculas
vg ms requestsservice       ← no usar espacios
vg_ms_requestsservice       ← no usar guión bajo
vg-ms-servicio_solicitudes  ← no mezclar español e inglés
ms-requests                 ← falta el prefijo vg-
requestsservice             ← falta el prefijo vg-ms-
```

---

##  2. Estrategia de Ramas — Trunk Based Development

### ¿Qué es Trunk Based Development?

Trunk Based Development (TBD) es una estrategia de versionamiento donde todos los desarrolladores integran su trabajo frecuentemente en una sola rama principal llamada `main` (el trunk). Las ramas de trabajo son de corta duración (máximo 1-2 días) y se eliminan después de fusionarse. Esto evita conflictos grandes, facilita la integración continua y permite despliegues frecuentes y seguros.

### Diferencia con GitFlow

| Característica | GitFlow | Trunk Based Development |
|---|---|---|
| Ramas principales | `main` + `develop` + `release` | Solo `main` |
| Duración de ramas | Semanas o meses | 1 a 2 días máximo |
| Merges | Poco frecuentes y complejos | Diarios y pequeños |
| CI/CD | Difícil de automatizar | Ideal para automatización |
| Conflictos | Frecuentes y grandes | Raros y pequeños |
| Despliegue | Por versiones | Continuo |

### Estructura de ramas

```
main                              ← rama principal (SIEMPRE desplegable)
├── feature/nombre-corto          ← nueva funcionalidad (máx 1-2 días)
├── fix/descripcion-del-bug       ← corrección de un error específico
├── hotfix/descripcion-urgente    ← corrección urgente en producción
└── refactor/descripcion          ← mejora de código sin cambio funcional
```

### Reglas obligatorias de ramas

- `main` siempre debe estar en estado desplegable y sin errores
- Nunca hacer commits directamente sobre `main`
- Las ramas `feature/` duran máximo 1 o 2 días antes de fusionarse a `main`
- Toda rama se elimina localmente y remotamente después del merge
- Se requiere mínimo 1 aprobación (code review) para hacer merge a `main`
- Siempre hacer `git pull origin main` antes de empezar a trabajar
- Una rama = una funcionalidad o corrección, nunca mezclar temas

### Nomenclatura de ramas

```
feature/nombre-en-kebab-case
fix/nombre-del-bug
hotfix/descripcion-urgente
refactor/descripcion
```

### Ejemplos correctos de nombres de ramas

```
feature/crud-solicitudes
feature/calendar-semanal
feature/subida-cloudinary
feature/auto-prioridad-alta
feature/filtro-fecha-lista
feature/buscador-persona-form
fix/busqueda-por-nombre
fix/dropdown-persona-form
fix/neon-connection
hotfix/neon-connection-timeout
refactor/filter-computed-signal
```

### Ejemplo aplicado a vg-ms-peopleservice (Jennifer C.C.)

```
main
├── feature/crud-personas
├── feature/filtro-por-funcion
├── feature/busqueda-por-documento
├── feature/paginacion-lista
├── feature/filtro-por-tenant
├── fix/estado-activo-inactivo
├── fix/validacion-dni-duplicado
└── refactor/persona-repository-query
```

### Ejemplo aplicado a vg-ms-booksservice (Jennifer C.C.)

```
main
├── feature/crud-libros
├── feature/control-inventario
├── feature/filtro-por-nivel
├── feature/integracion-finanzas
├── feature/busqueda-por-titulo
├── fix/stock-negativo-validation
├── fix/categoria-libros-filter
└── refactor/books-service-layer
```

### Errores de ramas que NO se deben cometer

```
Feature/CrudSolicitudes         ← no usar mayúsculas
feature crud solicitudes        ← no usar espacios
feature_crud_solicitudes        ← no usar guión bajo
mi-rama                         ← sin tipo ni descripción
rama-nueva                      ← no descriptivo
arreglando-bug                  ← sin tipo prefijo
fix                             ← sin descripción
feature/todo-el-sprint          ← una rama no puede tener múltiples funcionalidades
```

### Ejemplo de flujo completo

```bash
# 1. Actualizar main antes de empezar
git checkout main
git pull origin main

# 2. Crear rama desde main
git checkout -b feature/auto-prioridad-alta

# 3. Trabajar, hacer commits frecuentes
git add .
git commit -m "feat: implement auto-escalation of priority based on request date"

# 4. Subir la rama
git push origin feature/auto-prioridad-alta

# 5. Crear Pull Request → esperar aprobación → merge a main

# 6. Eliminar la rama después del merge
git branch -d feature/auto-prioridad-alta
git push origin --delete feature/auto-prioridad-alta
```

---

## 3. Convención de Commits — Conventional Commits

Se usa el estándar **Conventional Commits** para mantener un historial limpio, legible y compatible con herramientas de automatización como changelogs y versionado semántico.

### Formato

```
<tipo>: <descripción corta en inglés en imperativo>
```

### Tipos de commits

| Tipo | Cuándo usarlo | Ejemplo |
|---|---|---|
| `feat` | Nueva funcionalidad | `feat: add request calendar view` |
| `fix` | Corrección de error | `fix: fix person name not showing in list` |
| `refactor` | Mejora sin cambio de comportamiento | `refactor: simplify filter computed signal` |
| `docs` | Cambios en documentación | `docs: update README with TBD strategy` |
| `chore` | Mantenimiento, dependencias | `chore: update spring boot to 4.0.6` |
| `test` | Agregar o modificar pruebas | `test: add unit tests for request service` |
| `hotfix` | Corrección urgente en producción | `hotfix: fix neon db timeout in prod` |
| `style` | Formato, espaciado, sin lógica | `style: fix indentation in solicitud-form` |
| `perf` | Mejora de rendimiento | `perf: optimize request filter computation` |

### Reglas para escribir commits

- Usar inglés siempre
- Verbo en imperativo: `add`, `fix`, `update`, `remove`, `implement`, `improve`
- Sin punto al final de la descripción
- Máximo 72 caracteres en la descripción
- Un commit = un cambio lógico, nunca mezclar funcionalidades distintas
- No subir código comentado ni archivos innecesarios
- No hacer commit de archivos de configuración personal (`.env`, IDE settings)

### Ejemplos de commits correctos

```bash
feat: add request management with calendar and conflict detection
feat: implement auto-escalation of priority based on request date
feat: add cloudinary document upload to solicitud form
feat: add searchable person dropdown in request form
feat: add date filter to request list with today week month options
feat: improve request management with priority update endpoint
fix: fix person search not filtering by full name in request list
fix: fix mass type option not showing in form dropdown
fix: remove unused variable opt in guardar method
fix: fix input file not resetting after file selection
refactor: improve request filter computed signal with date range logic
refactor: move conflict check to dedicated method in form component
docs: update README with trunk based development strategy
chore: update spring boot version to 4.0.6 in pom.xml
hotfix: fix neon db connection timeout in production environment
```

### Errores de commits que NO se deben cometer

```bash
# Mensajes vagos e inútiles
fix bugs
updated files
changes
WIP
asdf
.
commit
subiendo cambios

# En español
arreglé el error del formulario
agregué nueva funcionalidad
actualicé el código

# Mezclando varios cambios
feat: Add request form. Fix login. Update styles.

# Con punto al final
feat: add calendar view.

# Sin tipo
add new feature
fix something
```

---

## 4. Buenas Prácticas

### Código

- Variables, métodos y parámetros en inglés, camelCase
- Nombres de clases en PascalCase
- Nombres de archivos en kebab-case para Angular, PascalCase para Java
- Cada método o función hace una sola cosa (principio de responsabilidad única)
- No dejar código comentado en el repositorio
- Eliminar imports no usados antes de hacer commit
- No subir credenciales, contraseñas, tokens ni API keys al repositorio
- Usar `.gitignore` correctamente para excluir:
  - Java: `target/`, `*.class`, `*.jar`
  - Angular: `node_modules/`, `dist/`, `.angular/`
  - General: `.env`, `*.log`, archivos de IDE (`.idea/`, `.vscode/`)

### Pull Requests

- Título corto y descriptivo (máximo 70 caracteres)
- Descripción con: qué se hizo, por qué, y qué se probó
- Mínimo 1 revisor antes de hacer merge
- Nunca aprobar el propio Pull Request
- Resolver todos los comentarios del revisor antes de mergear
- No hacer merge si hay conflictos sin resolver
- El PR debe ser pequeño y enfocado en un solo tema

### Git

- Hacer `git pull origin main` siempre antes de empezar a trabajar
- Commits pequeños y frecuentes, no acumular todo al final
- No usar `git push --force` sobre `main` nunca
- No reescribir el historial de `main` con `git rebase` ni `git reset`
- Eliminar la rama local y remota después del merge
- No trabajar en una rama por más de 2 días sin hacer merge

### Errores generales que NO se deben cometer

- Subir contraseñas, tokens o API keys al repositorio
- Hacer commits directamente sobre `main`
- Acumular semanas de trabajo en una sola rama
- Hacer merge sin aprobación
- Subir archivos `node_modules/` o `target/` al repositorio
- Mezclar varios temas en un mismo commit o Pull Request
- Ignorar los comentarios del code review
- Usar `git push --force` en ramas compartidas
- Olvidar eliminar ramas después del merge
- No hacer `git pull` antes de empezar y luego tener conflictos evitables

---

## 5. Stack Tecnológico

**Backend:**
- Java 17 LTS — Lenguaje base de todos los microservicios
- Spring Boot 4.0.6 — Framework principal
- Spring WebFlux — APIs reactivas no bloqueantes
- Spring Data R2DBC — Repositorios reactivos
- PostgreSQL Neon Cloud — Base de datos serverless
- Docker + Docker Compose — Contenedorización
- GitLab CI/CD — Pipeline de integración continua

**Frontend:**
- Angular 20.3.0 — SPA framework
- TypeScript 5.9.2 — Lenguaje tipado
- TailwindCSS 4.2.4 — Estilos utilitarios
- RxJS 7.8.0 — Programación reactiva

**Infraestructura:**
- Dokploy — PaaS self-hosted en VPS
- Nginx Alpine — Servidor web y reverse proxy
- Neon DB — PostgreSQL serverless en la nube
- Cloudinary — Almacenamiento de archivos

---

## Repositorios

Los microservicios del PRS están alojados en GitLab:

```
https://gitlab.com/vallegrande/as241s5_prs3
```

---

## 📂 6. Cómo subir el código de cada microservicio al repositorio

Cada integrante del equipo sube su microservicio al repositorio siguiendo el flujo de Trunk Based Development. El código del microservicio va dentro de una carpeta con el nombre del servicio en la raíz del repositorio.

### Estructura del repositorio

```
as241s6_prs3_tbd/
├── README.md
├── vg-ms-requestsservice/       ← Duban S.N.
├── vg-ms-peopleservice/         ← Jennifer C.C.
├── vg-ms-booksservice/          ← Jennifer C.C.
├── vg-ms-massesservice/         ← Kevin H.V.
├── vg-ms-scheduleservice/       ← Jeanpier V.L.
├── vg-ms-eventservice/          ← Jeanpier V.L.
├── vg-ms-organizationservice/   ← Jeanpier V.L.
├── vg-ms-tenantservice/         ← Carlos Tomi
├── vg-ms-paymentservice/        ← Carlos Tomi / Luis H.
├── vg-ms-authservice/           ← Leonardo
└── vg-web-fideinexus/           ← Equipo PRS
```

### Flujo para subir tu microservicio

```bash
# 1. Clonar el repositorio
git clone https://github.com/vallegrande/as241s6_prs3_tbd.git
cd as241s6_prs3_tbd

# 2. Asegurarse de estar en main y tener lo último
git checkout main
git pull origin main

# 3. Copiar el código de tu microservicio en su carpeta correspondiente
# Ejemplo: copiar vg-ms-peopleservice dentro de la carpeta del repo

# 4. Agregar los archivos
git add .

# 5. Hacer commit siguiendo Conventional Commits
git commit -m "feat: add people service implementation"

# 6. Subir a main
git push origin main
```

### Mensajes de commit por microservicio

Cada integrante usa su prefijo de microservicio para identificar su aporte:

```bash
# vg-ms-peopleservice — Jennifer C.C.
git commit -m "feat: add people service with crud and tenant filter"
git commit -m "feat: add books service with inventory management"

# vg-ms-requestsservice — Duban S.N.
git commit -m "feat: add requests service with calendar and cloudinary"

# vg-ms-massesservice — Kevin H.V.
git commit -m "feat: add masses service with jwt security"

# vg-ms-scheduleservice — Jeanpier V.L.
git commit -m "feat: add schedule service with event and org orchestration"

# vg-ms-tenantservice — Carlos Tomi
git commit -m "feat: add tenant service with parish management"

# vg-ms-paymentservice — Carlos Tomi / Luis H.
git commit -m "feat: add payment service with finance management"

# vg-ms-authservice — Leonardo
git commit -m "feat: add auth service with jwt authentication"
```

---

*FideiNexus PRS — AS241S6 | Instituto Valle Grande*
