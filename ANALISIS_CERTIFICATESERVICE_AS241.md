# ⚠️ Análisis de Cumplimiento AS241 - vg-ms-certificateservice-hexagonal

**Fecha**: 2026-10-19  
**Microservicio**: vg-ms-certificateservice-hexagonal  
**Propósito**: Gestionar certificados sacramentales  
**Estándar**: AS241 - Todos los estándares (Arquitectura, BD, Backend, Seguridad, Reportes)  
**Estado**: ⚠️ **CUMPLE 95% - HALLAZGO: Endpoint PDF**

---

## Resumen Ejecutivo

Se analizó el microservicio `vg-ms-certificateservice-hexagonal` para verificar cumplimiento con los **5 estándares** de `PRS241_standards`:

### Resultado General:
⚠️ **Cumple 4 de 5 estándares al 100%**  
⚠️ **Estándar de Reportes: 95% - 1 endpoint genera PDF en backend**

### ⚠️ HALLAZGO CRÍTICO:
```java
@GetMapping(value = "/{id}/pdf", produces = MediaType.APPLICATION_PDF_VALUE)
public Mono<byte[]> downloadPdf(@PathVariable @Positive Long id) {
    return useCase.generatePDF(id);
}
```

**Estado actual**: Implementación **mock** (sin iText ni POI en `pom.xml`)  
**Impacto**: Si se implementa generación real de PDF server-side, violaría AS241  
**Recomendación**: Ver sección "Decisión sobre endpoint PDF" abajo

---

## 1. 📐 Arquitectura (PR241) - ✅ CUMPLE 100%

### Estructura Hexagonal:

```
pe/edu/vallegrande/fideinexus/certificate/
├── domain/
│   ├── model/           Certificate, CertificateCopy
│   ├── exception/       CertificateNotFoundException
│   └── port/
│       ├── in/          CertificateUseCase
│       └── out/         CertificateRepositoryPort
├── application/usecase/ CertificateService
└── infrastructure/
    ├── adapter/
    │   ├── in/rest/     CertificateRest, DTOs, Mappers
    │   └── out/
    │       └── persistence/r2dbc/  Repository, Entity, Mapper
    ├── security/        JWT
    ├── exception/       GlobalExceptionHandler
    └── config/          SecurityConfig, CorsConfig
```

**Análisis**:
- ✅ **Puertos IN**: `CertificateUseCase` (casos de uso)
- ✅ **Puertos OUT**: `CertificateRepositoryPort`
- ✅ **Adaptadores IN**: `CertificateRest` (HTTP)
- ✅ **Adaptadores OUT**: `persistence/r2dbc` (PostgreSQL)
- ✅ **Dominio puro**: Sin anotaciones Spring ni R2DBC

**Calificación**: 🟢 **100%** ✅

---

## 2. 🗄️ Base de Datos (PRS241) - ✅ CUMPLE 100%

### Tabla principal:

**`certificates`**:
- PK: `id` (BIGSERIAL)
- FK: `service_id` (solicitud), `celebration_id` (celebración)
- Columnas: `certificate_number`, `book`, `folio`, `signed`, `certificate_type`, `main_person_id`, `main_person_name`, `certificate_data`
- Auditoría: `issued_at`, `signed_at`, `created_at`, `updated_at`

### Características:

| Aspecto | Estado | Evidencia |
|---------|--------|-----------|
| Base de datos propia | ✅ | PostgreSQL independiente puerto 8099 |
| R2DBC reactivo | ✅ | `spring-boot-starter-data-r2dbc` + `r2dbc-postgresql` |
| Scripts SQL | ✅ | `src/main/resources/sql/schema.sql` |
| Credenciales seguras | ✅ | Variables de entorno `.env` |
| Pool de conexiones | ✅ | `r2dbc-pool` |

**Análisis**:
- ✅ No comparte tablas con otros microservicios
- ✅ Scripts idempotentes (`ADD COLUMN IF NOT EXISTS`)
- ✅ Sin contraseñas hardcodeadas
- ✅ `CertificateRepository` sigue **NOM-05** (`{Entidad}Repository`)

**Calificación**: 🟢 **100%** ✅

---

## 3. ⚙️ Backend (AS241S6) - ✅ CUMPLE 100%

### Endpoints REST:

**CertificateRest** (`/api/v1/certificates`):

| Método | Endpoint | Respuesta | Datos |
|--------|----------|-----------|-------|
| `GET` | `/request/{serviceId}` | `Mono<CertificateResponse>` | JSON |
| `GET` | `/celebration/{celebrationId}` | `Mono<CertificateResponse>` | JSON |
| `GET` | `/{id}` | `Mono<CertificateResponse>` | JSON |
| `GET` | `/signed/{signed}` | `Flux<CertificateResponse>` | JSON |
| `GET` | `/search` | `Flux<CertificateResponse>` | JSON |
| `GET` | `/person/{personId}` | `Flux<CertificateResponse>` | JSON |
| `GET` | `/tenant/{tenantId}/type/{certificateType}` | `Flux<CertificateResponse>` | JSON |
| `POST` | `/generate` | `Mono<CertificateResponse>` | JSON |
| `POST` | `/{id}/copy` | `Mono<CopyCertificateResponse>` | JSON |
| `POST` | `/{id}/complete-certificate-request` | `Mono<CompleteCertificateResponse>` | JSON |
| `PATCH` | `/{id}/sign` | `Mono<CertificateResponse>` | JSON |
| ⚠️ `GET` | ⚠️ `/{id}/pdf` | ⚠️ `Mono<byte[]>` | ⚠️ **PDF binario** |

**Análisis**:
- ✅ **11 endpoints JSON** que cumplen AS241
- ⚠️ **1 endpoint PDF** que requiere revisión
- ✅ DTOs tipados (6 DTOs: 3 Request + 3 Response)
- ✅ Bean Validation (`@Valid`, `@Positive`)
- ✅ Permisos (`@PreAuthorize` con SECRETARIO, PARROCO, FELIGRES)
- ✅ Documentación OpenAPI/Swagger

### DTOs:

#### Entrada:
1. `CertificateGenerateRequest`: Genera certificado desde solicitud+celebración
2. `CertificateSignRequest`: Firma manual con número, libro, folio
3. `CompleteCertificateRequest`: Marca como completada la solicitud

#### Salida:
1. `CertificateResponse`: Certificado completo
2. `CopyCertificateResponse`: Respuesta de copia generada
3. `CompleteCertificateResponse`: Confirmación de completitud

**Análisis**:
- ✅ Records tipados (Java 17)
- ✅ Sin `Object` ni `Map<String, Object>`
- ✅ Fechas tipadas (`LocalDateTime`)

### Tecnologías:

| Componente | Versión |
|------------|---------|
| Java | 17 |
| Spring Boot | 3.4.5 |
| WebFlux | Reactivo |
| PostgreSQL | R2DBC |
| SpringDoc OpenAPI | 2.8.8 |
| JaCoCo | 0.8.13 |

**Calificación**: 🟢 **100%** ✅ (backend estándar)

---

## 4. 🔐 Seguridad - ✅ CUMPLE 100%

### OAuth2 + JWT:

```java
@PreAuthorize("hasAnyRole('SECRETARIO','PARROCO')")
public Flux<CertificateResponse> findBySigned(Boolean signed) { ... }
```

### Características:

| Aspecto | Estado | Evidencia |
|---------|--------|-----------|
| OAuth2 Resource Server | ✅ | `spring-boot-starter-oauth2-resource-server` |
| Keycloak JWT | ✅ | `IDP_ISSUER_URI`, `IDP_JWK_SET_URI` |
| Roles | ✅ | `SECRETARIO`, `PARROCO`, `FELIGRES` |
| `@PreAuthorize` | ✅ | Todos los endpoints protegidos |
| CORS configurado | ✅ | `CORS_ALLOWED_ORIGINS` |

### Permisos por endpoint:

| Endpoint | Roles permitidos |
|----------|-----------------|
| Consultas generales | SECRETARIO, PARROCO |
| Búsqueda (`/search`) | SECRETARIO, PARROCO, FELIGRES |
| Descarga PDF (`/{id}/pdf`) | SECRETARIO, PARROCO, FELIGRES |
| Firmar (`/{id}/sign`) | **SOLO PARROCO** |

**Análisis**:
- ✅ JWT validado automáticamente
- ✅ Firmas restringidas solo a párrocos
- ✅ Feligreses pueden buscar y descargar sus certificados
- ✅ Manejo de errores tipados

**Calificación**: 🟢 **100%** ✅

---

## 5. 📊 Reportes (PRS3/AS241) - ⚠️ CUMPLE 95%

### Responsabilidades del Backend:

| Criterio | Estado | Evidencia |
|----------|--------|-----------|
| **Endpoints REST con JSON** | ✅ | 11 de 12 endpoints retornan JSON |
| **DTOs tipados** | ✅ | 6 DTOs (3 Request + 3 Response) |
| **Sin dependencias PDF** | ✅ | NO hay iText en `pom.xml` |
| **Sin dependencias Excel** | ✅ | NO hay Apache POI en `pom.xml` |
| **Sin endpoints `/report`** | ✅ | NO encontrado |
| **Sin generación server-side** | ⚠️ | **1 endpoint PDF encontrado** |
| **Datos completos para reportes** | ✅ | DTOs incluyen toda la info |

### ⚠️ HALLAZGO: Endpoint PDF

**Archivo**: `CertificateRest.java:107-109`

```java
@PreAuthorize("hasAnyRole('SECRETARIO','PARROCO','FELIGRES')")
@GetMapping(value = "/{id}/pdf", produces = MediaType.APPLICATION_PDF_VALUE)
public Mono<byte[]> downloadPdf(@PathVariable @Positive Long id) {
    return useCase.generatePDF(id);
}
```

**Implementación actual** (`CertificateService.java:133-137`):

```java
@Override
public Mono<byte[]> generatePDF(Long certificateId) {
    return findById(certificateId)
            .map(certificate -> ("PDF Certificate: " + certificate.getCertificateNumber())
                    .getBytes(StandardCharsets.UTF_8));
}
```

### Análisis del endpoint PDF:

| Aspecto | Estado |
|---------|--------|
| **Implementación real** | ❌ NO - Es un **mock** con texto plano |
| **Librerías PDF** | ✅ NO tiene iText ni POI |
| **Violación AS241** | ⚠️ **POTENCIAL** (si se implementa generación real) |
| **Uso actual** | ⚠️ Retorna texto plano fingiendo ser PDF |

### Verificación pom.xml:

```xml
<!-- ✅ Backend típico -->
<dependency>spring-boot-starter-webflux</dependency>
<dependency>spring-boot-starter-data-r2dbc</dependency>
<dependency>spring-boot-starter-security</dependency>
<dependency>spring-boot-starter-oauth2-resource-server</dependency>
<dependency>springdoc-openapi-starter-webflux-ui</dependency>

<!-- ❌ NO existe: iText (PDF) -->
<!-- ❌ NO existe: Apache POI (Excel) -->
<!-- ❌ NO existe: JasperReports -->
```

**Calificación**: ⚠️ **95%** - 1 endpoint que requiere decisión

---

## 📋 Decisión sobre el Endpoint PDF (Estándar PRS3 Oficial)

### ⚠️ VEREDICTO OFICIAL DEL ESTÁNDAR PRS3:

Según el documento **PRS3-Standar-Reports/03-arquitectura/arquitectura-general.md**:

```markdown
## 3.2 Arquitectura de Reportes (100% Client-Side)

FIDEI NEXUS no implementa generación de documentos en el backend. Los microservicios
actúan como productores de datos JSON puros enriquecidos. El frontend asume toda
la responsabilidad de renderizar estos payloads en documentos descargables utilizando
`jsPDF` y `SheetJS`.
```

**Estándar PRS3 - README.md §2**:
- ✅ **Generación**: Client-side por defecto (navegador arma el documento, backend entrega JSON)
- ⚠️ **Excepción**: Server-side (iText 7 / POI) **solo con justificación escrita**

### Opción 1: ❌ ELIMINAR (Cumple 100% PRS3) ✅ RECOMENDADO

**Cambios necesarios**:

1. Eliminar endpoint en `CertificateRest.java`:
```java
// ELIMINAR estas líneas:
@GetMapping(value = "/{id}/pdf", produces = MediaType.APPLICATION_PDF_VALUE)
public Mono<byte[]> downloadPdf(@PathVariable @Positive Long id) {
    return useCase.generatePDF(id);
}
```

2. Eliminar método en `CertificateUseCase.java`:
```java
// ELIMINAR:
Mono<byte[]> generatePDF(Long certificateId);
```

3. Eliminar implementación en `CertificateService.java`:
```java
// ELIMINAR:
@Override
public Mono<byte[]> generatePDF(Long certificateId) { ... }
```

4. **Frontend implementa generación**:
```typescript
// En Angular con jsPDF
generateCertificatePDF(certificateId: number) {
  // 1. GET /api/v1/certificates/{id} → JSON
  this.certificateService.getById(certificateId).subscribe(cert => {
    // 2. Generar PDF con jsPDF
    const doc = new jsPDF();
    doc.text(`Certificado N°: ${cert.certificateNumber}`, 10, 10);
    doc.text(`Libro: ${cert.book}`, 10, 20);
    // ... más datos del certificado
    doc.save(`certificado-${cert.certificateNumber}.pdf`);
  });
}
```

**Ventajas**:
- ✅ Cumple 100% con AS241
- ✅ Frontend controla diseño y logo institucional
- ✅ Sin dependencias server-side de PDF
- ✅ Escalable (no consume memoria del backend)

**Desventajas**:
- ⚠️ Requiere cambios en frontend
- ⚠️ Si ya existe código frontend que usa `GET /{id}/pdf`, debe migrarse

---

### Opción 2: ✅ MANTENER CON JUSTIFICACIÓN ESCRITA (Excepción PRS3)

**Cuándo es válido mantenerlo según PRS3 §2**:

✅ **Certificados sacramentales oficiales requieren**:
1. **Plantillas institucionales complejas** (escudos, sellos, marcas de agua)
2. **Firmas digitales PKI** (clave privada del párroco/diócesis)
3. **Formato legal estandarizado** (no puede variar por cliente)
4. **QR/código de verificación** cifrado server-side

**Si aplica, documentar en README**:

```markdown
### Excepción: Endpoint PDF de Certificados

El endpoint `GET /{id}/pdf` genera PDF server-side con justificación:

**Razones**:
1. Certificados oficiales requieren firma digital PKI con clave privada del párroco
2. Plantilla institucional con escudo diocesano y sello oficial
3. QR de verificación cifrado con secreto server-side
4. Formato legal estandarizado por la diócesis

**Implementación**:
- Librería: iText 7 (o alternativa)
- Plantilla: `resources/templates/certificate-template.pdf`
- Firma digital: Keystore del microservicio
- QR: URL de verificación pública

**Cumplimiento AS241**:
- Excepción documentada y aprobada
- Frontend NO replica esta lógica
- Otros reportes (listados, estadísticas) usan jsPDF/ExcelJS
```

**Cambios necesarios**:

1. Agregar librería PDF a `pom.xml`:
```xml
<dependency>
    <groupId>com.itextpdf</groupId>
    <artifactId>itext7-core</artifactId>
    <version>7.2.5</version>
</dependency>
```

2. Implementar generación real:
```java
@Override
public Mono<byte[]> generatePDF(Long certificateId) {
    return findById(certificateId).flatMap(certificate -> {
        try {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            PdfWriter writer = new PdfWriter(baos);
            PdfDocument pdf = new PdfDocument(writer);
            Document document = new Document(pdf);
            
            // Agregar escudo/sello
            // Agregar datos del certificado
            // Firmar digitalmente
            // Agregar QR de verificación
            
            document.close();
            return Mono.just(baos.toByteArray());
        } catch (Exception e) {
            return Mono.error(e);
        }
    });
}
```

**Ventajas**:
- ✅ Cumple requisitos legales de certificados oficiales
- ✅ Firma digital PKI garantiza autenticidad
- ✅ QR de verificación seguro

**Desventajas**:
- ⚠️ Requiere dependencia iText
- ⚠️ Consume memoria del backend
- ⚠️ Debe documentarse como excepción justificada

---

### ⚡ RECOMENDACIÓN FINAL

**Si los certificados requieren firma digital PKI o formato legal estricto**:  
→ **Opción 2**: Mantener con justificación escrita  

**Si los certificados son solo documentos informativos**:  
→ **Opción 1**: Eliminar endpoint y mover generación a frontend  

**Para decidir, pregunta**:
1. ¿Los certificados llevan firma digital PKI del párroco?
2. ¿La diócesis exige un formato PDF específico (plantilla legal)?
3. ¿Los certificados tienen código QR de verificación cifrado?

**Si 2 o más respuestas son SÍ** → Opción 2 (mantener con justificación)  
**Si todas son NO** → Opción 1 (eliminar y mover a frontend)

---

## Análisis de Dependencias (pom.xml)

### ✅ Dependencias Encontradas:

```xml
<!-- Framework -->
<dependency>spring-boot-starter-webflux</dependency>
<dependency>spring-boot-starter-actuator</dependency>

<!-- Persistencia -->
<dependency>spring-boot-starter-data-r2dbc</dependency>
<dependency>r2dbc-postgresql</dependency>
<dependency>r2dbc-pool</dependency>

<!-- Seguridad -->
<dependency>spring-boot-starter-security</dependency>
<dependency>spring-boot-starter-oauth2-resource-server</dependency>

<!-- Validación y Documentación -->
<dependency>spring-boot-starter-validation</dependency>
<dependency>springdoc-openapi-starter-webflux-ui</dependency>

<!-- Utilidades -->
<dependency>lombok</dependency>

<!-- Testing -->
<dependency>spring-boot-starter-test</dependency>
<dependency>reactor-test</dependency>
<dependency>spring-security-test</dependency>

<!-- Calidad -->
<dependency>jacoco-maven-plugin</dependency>
```

### ❌ Dependencias NO encontradas:

```xml
<!-- ✅ Correcto: NO tiene iText (PDF) -->
<dependency>com.itextpdf:itext7-core</dependency>

<!-- ✅ Correcto: NO tiene Apache POI (Excel) -->
<dependency>org.apache.poi:poi-ooxml</dependency>

<!-- ✅ Correcto: NO tiene JasperReports -->
<dependency>net.sf.jasperreports:jasperreports</dependency>
```

---

## Comparativa: 4 Microservicios

| Aspecto | servicesservice | preparationservice | certificateservice | organizationservice |
|---------|-----------------|-------------------|--------------------|---------------------|
| **Puerto** | 8087 | 8097 | 8099 | 8093 |
| **Propósito** | Solicitudes | Preparación | Certificados | Organizaciones |
| **Controllers** | 4 | 1 | 1 | 2 |
| **Endpoints JSON** | 15 | 10 | 11 | 8 |
| **Endpoints PDF** | 0 | 0 | ⚠️ **1** | 0 |
| **DTOs** | 7 | 4 | 6 | 3 |
| **Arquitectura** | Hexagonal ✅ | Hexagonal ✅ | Hexagonal ✅ | Hexagonal ✅ |
| **BD** | PostgreSQL ✅ | PostgreSQL ✅ | PostgreSQL ✅ | PostgreSQL ✅ |
| **OAuth2** | Keycloak ✅ | Keycloak ✅ | Keycloak ✅ | Keycloak ✅ |
| **PDF/Excel** | ❌ NO genera | ❌ NO genera | ⚠️ **1 endpoint** | ❌ NO genera |
| **Cumplimiento** | 🟢 100% | 🟢 100% | ⚠️ 95% | 🟢 100% |

---

## Checklist Final - Los 5 Estándares

### 1. Arquitectura (PR241):
- [x] Arquitectura hexagonal completa
- [x] Puertos IN y OUT
- [x] Adaptadores REST y R2DBC
- [x] Dominio puro

### 2. Base de Datos (PRS241):
- [x] Base de datos propia
- [x] R2DBC reactivo
- [x] Scripts SQL idempotentes
- [x] Credenciales por variables de entorno
- [x] Repository con nomenclatura NOM-05

### 3. Backend (AS241S6):
- [x] Spring Boot 3.4.5 + WebFlux
- [x] Java 17
- [x] 11 endpoints REST con JSON
- [x] DTOs tipados (records)
- [x] Bean Validation
- [x] Clean Code, SOLID
- [x] OpenAPI/Swagger

### 4. Seguridad:
- [x] OAuth2 Resource Server
- [x] Keycloak JWT
- [x] `@PreAuthorize` en endpoints
- [x] Roles (SECRETARIO, PARROCO, FELIGRES)
- [x] CORS configurado

### 5. Reportes (PRS3/AS241):
- [x] Backend expone JSON (11 endpoints)
- [x] Sin iText ni Apache POI actualmente
- [x] Sin endpoints `/report`
- [ ] ⚠️ **1 endpoint PDF requiere decisión**
- [x] DTOs completos para frontend

---

## Calificación Final por Estándar

```
✅ 1. Arquitectura (PR241):     20/20 (100%) ✅
✅ 2. Base de Datos (PRS241):   20/20 (100%) ✅
✅ 3. Backend (AS241S6):        20/20 (100%) ✅
✅ 4. Seguridad:                20/20 (100%) ✅
⚠️ 5. Reportes (PRS3/AS241):    19/20 (95%)  ⚠️

🎯 TOTAL: 99/100 (99%) ⚠️
```

**Pendiente**: Definir si el endpoint PDF es excepción justificada o debe eliminarse

---

## Conclusiones

### Estado Actual:
⚠️ **vg-ms-certificateservice-hexagonal cumple 99% con los 5 estándares**

### Arquitectura correcta (11 endpoints JSON):
```
Backend (certificateservice):
├── Expone: JSON tipado con DTOs ✅
├── Filtra: Por serviceId, celebrationId, personId, tenantId, type, signed
├── Genera: Certificados, copias, firmas
└── NO genera: PDF ni Excel (excepto 1 endpoint mock)

Frontend (fideinexus):
├── Consume: JSON del backend ✅
├── Genera: PDF (jsPDF) si se elimina endpoint ⚠️
├── Usa: Logo institucional del tenant
└── Descarga: Client-side
```

### ⚠️ Decisión requerida:

**Endpoint PDF** (`GET /{id}/pdf`):
1. **Eliminar** → Cumple 100% AS241, frontend usa jsPDF
2. **Mantener + Implementar** → Excepción justificada (firmas PKI, formato legal)

### Tus 4 microservicios analizados:

| Microservicio | Cumplimiento | Observaciones |
|---------------|--------------|---------------|
| `vg-ms-organizationservice` | 🟢 100% ✅ | Del compañero, sin reportes |
| `vg-ms-servicesservice-hexagonal` | 🟢 100% ✅ | Solo JSON, sin reportes |
| `vg-ms-preparationservice-hexagonal` | 🟢 100% ✅ | Solo JSON, integraciones OK |
| `vg-ms-certificateservice-hexagonal` | ⚠️ 99% | 1 endpoint PDF mock pendiente |

---

## Próximos Pasos

### Opción A: Eliminar endpoint PDF (100% cumplimiento AS241)

1. ✅ Eliminar endpoint `GET /{id}/pdf` del backend
2. ✅ Eliminar método `generatePDF()` de `CertificateUseCase` y `CertificateService`
3. ✅ Frontend implementa generación con jsPDF:
   ```typescript
   generateCertificatePDF(certificateId: number) {
     this.certificateService.getById(certificateId).subscribe(cert => {
       const doc = new jsPDF();
       // Diseño del certificado con datos del JSON
       doc.save(`certificado-${cert.certificateNumber}.pdf`);
     });
   }
   ```
4. ✅ Actualizar documentación (README, colección Postman)
5. ✅ Re-auditar → 100% cumplimiento ✅

### Opción B: Mantener con justificación (excepción AS241)

1. ✅ Documentar justificación en README (firmas PKI, formato legal)
2. ✅ Agregar `itext7-core` a `pom.xml`
3. ✅ Implementar generación real con plantilla institucional
4. ✅ Agregar firma digital PKI
5. ✅ Agregar QR de verificación cifrado
6. ✅ Obtener aprobación escrita del arquitecto/líder técnico
7. ✅ Actualizar este documento con la justificación aprobada

---

## Referencias

- **Estándar AS241**: `PRS241_standards/skills/as241-backend-standards/SKILL.md`
- **README**: `vg-ms-certificateservice-hexagonal/README.md`
- **Controller**: `CertificateRest.java`
- **Use Case**: `CertificateService.java`
- **DTOs**:
  - Request: `CertificateGenerateRequest`, `CertificateSignRequest`, `CompleteCertificateRequest`
  - Response: `CertificateResponse`, `CopyCertificateResponse`, `CompleteCertificateResponse`
- **pom.xml**: Sin dependencias de iText/POI (actualmente)

---

**Autor**: Kiro AI Assistant  
**Fecha**: 2026-10-19  
**Versión**: 1.0  
**Estándar**: Todos los estándares PRS241 (99% Completo) ⚠️  
**Pendiente**: Decisión sobre endpoint PDF (eliminar o justificar)

