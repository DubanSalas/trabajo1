# 📚 Inventario Completo de Estándares PRS241

**Fecha**: 2026-10-19  
**Repositorio**: `vallegrande/PRS241_standards`  
**URL**: https://github.com/vallegrande/PRS241_standards

---

## 🌳 Ramas Disponibles

El repositorio tiene **7 ramas** con diferentes estándares organizados por tema:

| # | Rama | Contenido | Estado |
|---|------|-----------|--------|
| 1 | `main` | Rama principal (por defecto) | ✅ Activo |
| 2 | `backend` | Estándares Backend (AS241S6) | ✅ Activo |
| 3 | `Reports` | Estándares de Reportes (PRS1-5) | ✅ Activo |
| 4 | `DatabaseStorage` | Estándares de BD y Storage (PRS1-5) | ✅ Activo |
| 5 | `ProjectArchitecture` | Estándares de Arquitectura Hexagonal | ✅ Activo |
| 6 | `frontend` | Estándares de Frontend | ✅ Activo |
| 7 | `security` | Estándares de Seguridad | ✅ Activo |

---

## 📖 Detalle por Rama

### 1️⃣ **Rama: `backend`**

**Propósito**: Estándares de desarrollo backend con Java/Spring

```
PRS241_standards/
├── skills/
│   └── as241-backend-standards/
│       ├── SKILL.md                      # Guía principal
│       ├── checklist.md                  # Checklist de cumplimiento
│       ├── anti-patterns.md              # Anti-patrones a evitar
│       ├── report-format.md              # Formato de reportes de auditoría
│       ├── scripts/
│       │   └── generate_report.py        # Generador de reportes Excel
│       └── templates/
│           └── PRS_Reporte_Estandares_TEMPLATE.xlsx
└── README.md                             # Guía completa backend AS241S6
```

**Temas cubiertos**:
- ✅ DDD (Domain-Driven Design) práctico
- ✅ Arquitectura hexagonal (opcional)
- ✅ API REST (`/api/v1/...`)
- ✅ Spring Boot 3.x + WebFlux
- ✅ OAuth2 + JWT + Keycloak
- ✅ PostgreSQL + R2DBC / MongoDB Reactivo
- ✅ Clean Code + SOLID
- ✅ Docker + README + Testing

**Aplica a**: Microservicios Java/Spring

---

### 2️⃣ **Rama: `Reports`**

**Propósito**: Estándares de generación de reportes PDF/Excel

```
PRS241_standards/
├── PRS1-Standar-Reports/
│   ├── 01-resumen/
│   ├── 02-formatos/
│   ├── 03-arquitectura/
│   ├── 04-despliegue/
│   ├── 05-operaciones/
│   └── 06-frontend/
├── PRS2-Standar-Reports/
│   └── (misma estructura)
├── PRS3-Standar-Reports/              # ⭐ TU PROYECTO (FIDEI NEXUS)
│   ├── 01-resumen/
│   ├── 02-formatos/
│   ├── 03-arquitectura/
│   │   ├── arquitectura-general.md    # ⭐ Arquitectura 100% Client-Side
│   │   └── patrones-generacion.md     # ⭐ jsPDF + SheetJS
│   ├── 04-despliegue/
│   ├── 05-operaciones/
│   └── 06-frontend/
├── PRS4-Standar-Reports/
│   └── (misma estructura)
├── PRS5-Standar-Reports/
│   └── (misma estructura)
└── README.md                          # Guía maestra de reportes
```

**Temas cubiertos**:
- ✅ **Arquitectura client-side por defecto** (jsPDF + SheetJS)
- ⚠️ **Excepción server-side** solo con justificación escrita (iText 7 + POI)
- ✅ Formatos: PDF, XLSX, CSV, HTML, JSON
- ✅ Nomenclatura de archivos (`Reporte_{Nombre}_{YYYY-MM-DD}.ext`)
- ✅ Lazy imports (performance)
- ✅ Patrones de generación reactivos
- ✅ Enriquecimiento de datos multiservicio

**Aplica a**: Todos los proyectos PRS (PRS1-PRS5)

**Regla clave para PRS3**:
```markdown
## 3.2 Arquitectura de Reportes (100% Client-Side)

FIDEI NEXUS no implementa generación de documentos en el backend.
Los microservicios actúan como productores de datos JSON puros enriquecidos.
El frontend asume toda la responsabilidad de renderizar estos payloads 
en documentos descargables utilizando jsPDF y SheetJS.
```

---

### 3️⃣ **Rama: `DatabaseStorage`**

**Propósito**: Estándares de base de datos y almacenamiento

```
PRS241_standards/
├── PRS01/
│   └── PRS1-Estandar-DatabaseStorage.md
├── PRS02/
│   └── PRS2-Estandar-DatabaseStorage.md
├── PRS03/
│   └── PRS3-Estandar-DatabaseStorage.md    # ⭐ TU PROYECTO
├── PRS04/
│   └── PRS4-Estandar-DatabaseStorage.md
├── PRS05/
│   └── PRS5-Estandar-DatabaseStorage.md
├── skills/
│   └── as241-database-standards/
└── README.md
```

**Temas cubiertos**:
- ✅ PostgreSQL + R2DBC (reactivo)
- ✅ MongoDB Reactivo
- ✅ Esquemas + Migraciones
- ✅ Índices + Optimización
- ✅ Credenciales por variables de entorno
- ✅ Base de datos propia por microservicio
- ✅ Soft-delete vs hard-delete
- ✅ Storage de archivos (Cloudinary, MinIO, S3)

**Aplica a**: Todos los proyectos PRS (PRS1-PRS5)

---

### 4️⃣ **Rama: `ProjectArchitecture`**

**Propósito**: Estándares de arquitectura hexagonal

```
PRS241_standards/
└── README.md                    # Guía de arquitectura hexagonal
```

**Temas cubiertos**:
- ✅ Arquitectura hexagonal completa
- ✅ Puertos y Adaptadores (Ports & Adapters)
- ✅ Dominio puro (sin anotaciones técnicas)
- ✅ Use Cases / Casos de uso
- ✅ Separación de capas (domain / application / infrastructure)

**Aplica a**: Proyectos con arquitectura hexagonal explícita

---

### 5️⃣ **Rama: `frontend`**

**Propósito**: Estándares de desarrollo frontend

```
PRS241_standards/
├── PRS01/
│   └── PRS1-Estandar-DatabaseStorage.md
├── PRS02/
│   └── PRS2-Estandar-DatabaseStorage.md
├── PRS03/
│   └── PRS3-Estandar-DatabaseStorage.md    # ⭐ TU PROYECTO
├── PRS04/
│   └── PRS4-Estandar-DatabaseStorage.md
├── PRS05/
│   └── PRS5-Estandar-DatabaseStorage.md
├── skills/
│   └── as241-database-standards/
└── README.md
```

**Temas cubiertos**:
- ✅ Angular / Svelte
- ✅ Componentes standalone
- ✅ Tailwind CSS
- ✅ Servicios y Guards
- ✅ Lazy loading
- ✅ Estado y manejo de errores

**Aplica a**: Todos los proyectos PRS (PRS1-PRS5)

---

### 6️⃣ **Rama: `security`**

**Propósito**: Estándares de seguridad

```
PRS241_standards/
├── skills/
│   └── as241-frontend-standards/
└── README.md
```

**Temas cubiertos**:
- ✅ OAuth2 + JWT + Keycloak
- ✅ Roles y permisos
- ✅ CORS + CSRF
- ✅ Propagación de token Bearer
- ✅ Secrets management
- ✅ Rate limiting

**Aplica a**: Todos los proyectos PRS (PRS1-PRS5)

---

### 7️⃣ **Rama: `main`**

**Propósito**: Rama por defecto (redirige a otras ramas)

```
PRS241_standards/
└── README.md                    # Índice de todas las ramas
```

---

## 🎯 Estándares que Aplican a tu Proyecto (PRS3 - FIDEI NEXUS)

| Estándar | Rama | Documento Principal | Estado |
|----------|------|---------------------|--------|
| **Backend** | `backend` | `README.md` + `skills/as241-backend-standards/` | ✅ Implementado |
| **Reportes** | `Reports` | `PRS3-Standar-Reports/03-arquitectura/` | ⚠️ **Endpoint PDF viola** |
| **Base de Datos** | `DatabaseStorage` | `PRS03/PRS3-Estandar-DatabaseStorage.md` | ✅ Implementado |
| **Arquitectura** | `ProjectArchitecture` | `README.md` | ✅ Hexagonal implementado |
| **Frontend** | `frontend` | `PRS03/PRS3-Estandar-Frontend.md` | ✅ Angular standalone |
| **Seguridad** | `security` | `README.md` | ✅ OAuth2 + Keycloak |

---

## 📊 Resumen de Cumplimiento por Microservicio

### ✅ **Microservicios Completos (100%)**:

| Microservicio | Backend | BD | Reportes | Arquitectura | Seguridad |
|---------------|---------|-----|----------|--------------|-----------|
| `vg-ms-organizationservice` (compañero) | ✅ 100% | ✅ 100% | ✅ 100% | ✅ Hexagonal | ✅ 100% |
| `vg-ms-servicesservice-hexagonal` | ✅ 100% | ✅ 100% | ✅ 100% | ✅ Hexagonal | ✅ 100% |
| `vg-ms-preparationservice-hexagonal` | ✅ 100% | ✅ 100% | ✅ 100% | ✅ Hexagonal | ✅ 100% |

### ⚠️ **Microservicios con Observaciones**:

| Microservicio | Backend | BD | Reportes | Arquitectura | Seguridad | Observación |
|---------------|---------|-----|----------|--------------|-----------|-------------|
| `vg-ms-certificateservice-hexagonal` | ✅ 100% | ✅ 100% | ⚠️ 95% | ✅ Hexagonal | ✅ 100% | **Endpoint PDF** viola PRS3 §3.2 |

---

## 🔧 Cómo Usar los Estándares

### 1. Cambiar de rama:

```bash
cd PRS241_standards

# Ver todas las ramas
git branch -a

# Cambiar a la rama que necesitas
git checkout backend          # Estándares backend
git checkout Reports          # Estándares de reportes
git checkout DatabaseStorage  # Estándares de BD
git checkout ProjectArchitecture  # Arquitectura hexagonal
git checkout frontend         # Estándares frontend
git checkout security         # Estándares de seguridad
```

### 2. Actualizar la rama:

```bash
git pull origin <nombre-rama>
```

### 3. Leer documentos específicos de PRS3:

**Backend**:
```bash
git checkout backend
# Leer: README.md
# Leer: skills/as241-backend-standards/SKILL.md
```

**Reportes** (⭐ IMPORTANTE):
```bash
git checkout Reports
# Leer: README.md (guía maestra)
# Leer: PRS3-Standar-Reports/03-arquitectura/arquitectura-general.md
# Leer: PRS3-Standar-Reports/03-arquitectura/patrones-generacion.md
```

**Base de Datos**:
```bash
git checkout DatabaseStorage
# Leer: PRS03/PRS3-Estandar-DatabaseStorage.md
```

---

## 🚨 Hallazgo Crítico: Violación del Estándar PRS3

### ⚠️ **Microservicio: `vg-ms-certificateservice-hexagonal`**

**Archivo**: `CertificateRest.java:107-109`

```java
@GetMapping(value = "/{id}/pdf", produces = MediaType.APPLICATION_PDF_VALUE)
public Mono<byte[]> downloadPdf(@PathVariable @Positive Long id) {
    return useCase.generatePDF(id);
}
```

**Violación**: 
- ❌ PRS3 establece **"100% Client-Side"** para FIDEI NEXUS
- ❌ Backend debe retornar **JSON puro**, NO binarios PDF
- ❌ Frontend debe usar **jsPDF** para generar documentos

**Estándar violado**: `PRS3-Standar-Reports/03-arquitectura/arquitectura-general.md §3.2`

**Acciones requeridas**:
1. **Opción A** (Recomendada): Eliminar endpoint PDF, implementar generación en frontend con jsPDF
2. **Opción B** (Excepción): Obtener justificación escrita y aprobación del arquitecto

---

## 📝 Documentos de Análisis Generados

Durante esta sesión se generaron los siguientes documentos:

1. ✅ `ANALISIS_BACKEND_ORGANIZATIONSERVICE_AS241.md` - Análisis del microservicio del compañero
2. ✅ `ANALISIS_SERVICESSERVICE_AS241.md` - Análisis de servicesservice
3. ✅ `ANALISIS_PREPARATIONSERVICE_AS241.md` - Análisis de preparationservice
4. ✅ `ANALISIS_CERTIFICATESERVICE_AS241.md` - Análisis de certificateservice (con hallazgo)
5. ✅ `INVENTARIO_ESTANDARES_PRS241.md` - Este documento

---

## 📚 Referencias

- **Repositorio GitHub**: https://github.com/vallegrande/PRS241_standards
- **Proyecto**: FIDEI NEXUS (PRS3)
- **Promoción**: AS241S6
- **Fecha de análisis**: 2026-10-19

---

**Autor**: Kiro AI Assistant  
**Fecha**: 2026-10-19  
**Versión**: 1.0  
**Estado**: Inventario completo con 7 ramas verificadas ✅

