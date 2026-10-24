# 📊 Resumen de los 5 Estándares - vg-ms-organizationservice

**Fecha**: 2026-10-19  
**Microservicio**: vg-ms-organizationservice  
**Puerto**: 8093  
**Base de datos**: PostgreSQL (Neon) - R2DBC  

---

## Introducción

El microservicio `vg-ms-organizationservice` implementa **5 estándares de calidad** que se verifican automáticamente en Jenkins:

```
Jenkins Pipeline → Descarga vg-ms-arquitect → Genera 5 reportes Excel
```

Estos reportes se guardan en `target/estandares/` y están disponibles como artefactos del build.

---

## Los 5 Estándares

### 1. 📐 ProjectArchitecture PR241
**Archivo Excel**: `1-Arquitectura.xlsx`  
**Qué verifica**: Arquitectura hexagonal (puertos y adaptadores)

#### Estructura hexagonal:
```
pe/edu/vallegrande/fideinexus/organization/
├── domain/                    ← Modelo de dominio puro
│   ├── model/                 Organization, AuditRecord
│   ├── vo/                    Value Objects (Dni, Email, Phone, etc.)
│   ├── exception/             Excepciones de dominio
│   └── port/
│       ├── in/                OrganizationUseCase
│       └── out/               OrganizationRepositoryPort, AuditLogRepositoryPort
├── application/               ← Casos de uso
│   └── usecase/               OrganizationService, AuditService
└── infrastructure/            ← Adaptadores externos
    ├── adapter/
    │   ├── in/rest/           Controllers REST, DTOs
    │   └── out/persistence/   Repositorios R2DBC
    ├── security/              JWT de Keycloak
    ├── exception/             Handlers globales
    └── config/                CORS, Security, OpenAPI
```

**Estado**: ✅ **CUMPLE** - Arquitectura hexagonal completa

---

### 2. 🗄️ DatabaseStorage PRS241
**Archivo Excel**: `2-BaseDeDatos.xlsx`  
**Qué verifica**: Diseño de base de datos y persistencia

#### Características:
- **Tabla principal**: `organizations`
  - PK: `id` (formato `ORG-T{tenant}-{NNN}`)
  - FK: `tenant_id` (parroquia)
  - Borrado lógico: `record_status` (A/I)
  - Auditoría: `created_by`, `updated_by`, `created_at`, `updated_at`, `deleted_at`

- **Tabla de auditoría**: `audit_logs`
  - Registro de todas las operaciones sensibles
  - Inmutable (protegida contra UPDATE/DELETE)

- **Índices**:
  - Único por `tenant_id` + `dni` (solo activos)
  - Único por `tenant_id` + `coordinatorEmail` (solo activos)
  - Index por `tenant_id`

- **Conexión**:
  - R2DBC (reactivo)
  - PostgreSQL en Neon
  - TLS obligatorio (`sslMode=require`)

**Estado**: ✅ **CUMPLE** - HEX-02 y HEX-03 (puertos de persistencia)

---

### 3. ⚙️ Backend AS241S6
**Archivo Excel**: `3-Backend.xlsx`  
**Qué verifica**: Estándares de código backend

#### Características:
- **Framework**: Spring Boot 3.4.5 con WebFlux (reactivo)
- **Java**: 17 (LTS)
- **Seguridad**:
  - OAuth2 Resource Server
  - JWT de Keycloak
  - Roles: `SUPERADMIN`, `PARROCO`, `SECRETARIO`
  - `@PreAuthorize` en endpoints

- **Endpoints REST**: 8 endpoints documentados
  - CRUD completo
  - Borrado lógico + Restaurar
  - Endpoint público (sin PII)

- **DTOs tipados**:
  - `OrganizationRequest` (entrada)
  - `OrganizationResponse` (salida completa)
  - `PublicOrganizationResponse` (salida pública)

- **Validaciones**:
  - Bean Validation (`@Valid`, `@NotBlank`, `@Size`)
  - Custom validator (`@AllowedValues`)

- **Manejo de errores**:
  - Códigos HTTP: 400, 401, 403, 404, 409, 422, 500, 503
  - `ResponseDto` estándar
  - `ValidationError` con detalles

- **Documentación**: OpenAPI/Swagger en `/swagger-ui.html`

**Estado**: ✅ **CUMPLE** - Clean Code, SOLID, Reactive

---

### 4. 🔐 Seguridad
**Archivo Excel**: `4-Seguridad.xlsx`  
**Qué verifica**: Autenticación, autorización y protección de datos

#### Características:
- **Autenticación**:
  - JWT de Keycloak
  - Validación de firma con JWKS
  - Validación de issuer y expiración
  - Claim `tenantId` para multi-tenancy

- **Autorización**:
  - Roles jerárquicos: SUPERADMIN > PARROCO > SECRETARIO
  - `@PreAuthorize` en todos los endpoints protegidos
  - SUPERADMIN puede elegir tenant con `?tenantId=`
  - Personal solo ve su parroquia

- **Protección de datos**:
  - Endpoint público **SIN PII**: Sin DNI, teléfono, correo
  - Endpoint privado **CON PII**: Solo para personal autorizado
  - Filtrado automático por `tenant_id`

- **Auditoría**:
  - Tabla `audit_logs` con todas las operaciones sensibles
  - Actor, tenant, recurso, resultado, correlation ID
  - Inmutable (no se puede editar ni borrar)

- **CORS**: Configurado para frontend y gateway

- **Errores de seguridad**:
  - 401: Token inválido o expirado
  - 403: Sin permiso (rol insuficiente o tenant incorrecto)

**Estado**: ✅ **CUMPLE** - OAuth2, Multi-tenancy, Auditoría

---

### 5. 📊 Reportes PRS3 / AS241
**Archivo Excel**: `5-Reportes.xlsx`  
**Qué verifica**: Responsabilidades del backend en reportes

#### ✅ Lo que SÍ hace el Backend:
1. **Endpoints REST con JSON** (8 endpoints)
2. **DTOs tipados** (3 records Java)
3. **Filtros** (por `tenantId`, estado activo/eliminado)
4. **Permisos de acceso** (`@PreAuthorize`)
5. **Documentación OpenAPI** (Swagger)
6. **Validación de entrada** (Bean Validation)
7. **Manejo de errores** (códigos HTTP estándar)

#### ❌ Lo que NO hace el Backend (correcto según AS241):
1. **NO genera PDF**: Sin iText ni dependencias de PDF
2. **NO genera Excel**: Sin Apache POI ni dependencias de Excel
3. **NO tiene endpoints `/report`**: Solo endpoints REST JSON
4. **NO usa Content-Disposition**: No envía binarios

#### Arquitectura correcta:
```
Backend → Expone JSON → Frontend genera PDF/Excel → Usuario descarga
```

**Estado**: ✅ **CUMPLE 100%** - Client-side por defecto

---

## Herramientas de Verificación

### Jenkins Pipeline (Jenkinsfile):

```groovy
pipeline {
    stages {
        stage('Checkout')         → Clona el repositorio
        stage('Compilar')         → mvn clean compile
        stage('Pruebas')          → mvn test (JUnit + JaCoCo)
        stage('SonarCloud')       → Análisis de calidad
        stage('Estándares')       → Genera 5 reportes Excel
        stage('Empaquetar')       → mvn package
        stage('JMeter')           → Pruebas de carga
    }
}
```

### Etapa de Estándares:

```bash
# 1. Descargar herramientas de vg-ms-arquitect
git clone https://github.com/vallegrande/vg-ms-arquitect.git

# 2. Instalar dependencias
pip install openpyxl==3.1.5

# 3. Generar reportes
python vg-ms-arquitect/ci/standards/run_standards.py \
  --root . \
  --out target/estandares

# 4. Resultado: 5 archivos Excel
target/estandares/
├── 1-Arquitectura.xlsx
├── 2-BaseDeDatos.xlsx
├── 3-Backend.xlsx
├── 4-Seguridad.xlsx
└── 5-Reportes.xlsx
```

### Verificar localmente (sin Jenkins):

```bash
# 1. Clonar vg-ms-arquitect (si aún no lo tienes)
cd d:\Desktop\vg-ms-arquitect-main

# 2. Instalar Python dependencies
pip install openpyxl==3.1.5

# 3. Generar reportes
python ci/standards/run_standards.py \
  --root ./vg-ms-organizationservice \
  --out ./vg-ms-organizationservice/target/estandares

# 4. Ver reportes
ls ./vg-ms-organizationservice/target/estandares/*.xlsx
```

---

## Resumen de Cumplimiento

| Estándar | Archivo Excel | Estado | Porcentaje |
|----------|---------------|--------|------------|
| 1. ProjectArchitecture PR241 | `1-Arquitectura.xlsx` | ✅ CUMPLE | 100% |
| 2. DatabaseStorage PRS241 | `2-BaseDeDatos.xlsx` | ✅ CUMPLE | 100% |
| 3. Backend AS241S6 | `3-Backend.xlsx` | ✅ CUMPLE | 100% |
| 4. Seguridad | `4-Seguridad.xlsx` | ✅ CUMPLE | 100% |
| 5. Reportes PRS3/AS241 | `5-Reportes.xlsx` | ✅ CUMPLE | 100% |

**Calificación Total**: 🟢 **5/5 (100%)** ✅

---

## Documentación Relacionada

### README del microservicio:
`vg-ms-organizationservice/README.md`
- Sección 7: Estándares y reportes

### Herramientas en vg-ms-arquitect:
```
vg-ms-arquitect/
├── ci/standards/
│   └── run_standards.py           ← Script principal
├── PRS241_standards/
│   └── skills/as241-backend-standards/
│       ├── SKILL.md               ← Documentación
│       └── scripts/
│           └── generate_report.py ← Generador de reportes
└── keycloak/
    └── prs-realm-export.json      ← Configuración Keycloak
```

### Jenkins:
- **Pipeline**: `Jenkinsfile` en raíz del repositorio
- **Job**: Solo se ejecuta en branch `develop`
- **Artefactos**: Reportes Excel disponibles después del build

---

## Diferencias Clave: Backend vs Frontend

### Backend (vg-ms-organizationservice):
- **Responsabilidad**: Exponer datos JSON
- **Tecnología**: Spring Boot + WebFlux + R2DBC
- **Librerías**: Sin iText, sin POI
- **Endpoints**: REST con JSON tipado
- **Estándares**: 5 reportes Excel (backend)

### Frontend (vg-web-fideinexus-develop):
- **Responsabilidad**: Generar documentos PDF/Excel
- **Tecnología**: Angular + jsPDF + ExcelJS
- **Librerías**: jsPDF, ExcelJS
- **Generación**: Client-side (navegador)
- **Estándares**: AS241 de reportes (frontend)

---

## Notas Importantes

### 1. ProjectArchitecture PR241 (revisión 2026-10-14):
- **ANTES**: Recomendaba NO crear puertos innecesarios
- **AHORA**: Exige arquitectura hexagonal con puertos
- **Impacto**: Backend AS241S6 acepta puertos porque ProjectArchitecture los exige

### 2. DatabaseStorage PRS241:
- Cumple **HEX-02** (Puerto de persistencia: `OrganizationRepositoryPort`)
- Cumple **HEX-03** (Adaptador R2DBC: `OrganizationPersistenceAdapter`)

### 3. Códigos HTTP:
- **ProjectArchitecture**: Recomienda 400 para datos inválidos
- **Backend AS241S6**: Recomienda 422 para validaciones
- **Decisión del equipo**: Se usa **422** (Unprocessable Entity)

### 4. Jenkins NO es un estándar:
- Jenkins es la **herramienta de CI/CD**
- Ejecuta la verificación de los **5 estándares**
- NO genera un sexto reporte

---

## Conclusión

El microservicio `vg-ms-organizationservice` **cumple 100% con los 5 estándares** de calidad del proyecto:

1. ✅ Arquitectura hexagonal completa
2. ✅ Base de datos con auditoría y multi-tenancy
3. ✅ Backend reactivo con Spring Boot 3
4. ✅ Seguridad OAuth2 con Keycloak
5. ✅ Backend solo expone JSON (reportes en frontend)

Todos los estándares se verifican automáticamente en Jenkins y generan reportes Excel que se almacenan como artefactos del build.

---

**Autor**: Kiro AI Assistant  
**Fecha**: 2026-10-19  
**Versión**: 1.0  
**Referencias**:
- README del microservicio
- Jenkinsfile
- `vg-ms-arquitect/ci/standards/`
- Estándar AS241 de reportes
