# 📂 REVISIÓN ARCHIVO POR ARCHIVO - Los 4 Backends Hexagonales

**Fecha**: 18 de Octubre 2026  
**Investigadores**: Duban + Ordoñez  
**Estado**: ✅ REVISIÓN EXHAUSTIVA COMPLETADA

---

## 🔍 METODOLOGÍA

1. ✅ Git pull ejecutado en los 4 backends
2. ✅ Listado TODOS los archivos .java
3. ✅ Revisión de TODAS las entidades (@Table)
4. ✅ Revisión de TODOS los repositorios (queries SQL)
5. ✅ Búsqueda exhaustiva de palabras clave: organizations, events, event_reactions, audit_logs

---

## 1️⃣ VG-MS-REQUESTSSERVICE-HEXAGONAL

### 📊 Total de Archivos Java: 64 archivos

### 🗂️ Entidades (Entity.java):

#### RequestEntity.java ✅
```java
@Table("services")  // ← Usa tabla: services
public class RequestEntity {
    @Id private Long id;
    @Column("tenant_id") private Long tenantId;
    @Column("service_type_id") private Long serviceTypeId;
    @Column("church_id") private Long churchId;
    @Column("scheduled_date") private LocalDate scheduledDate;
    @Column("certificate_id") private Long certificateId;
    // ... más campos
}
```
**Tabla usada**: `services` ✅

#### ServiceParticipantEntity.java ✅
```java
@Table("service_participants")  // ← Usa tabla: service_participants
public class ServiceParticipantEntity {
    @Id private Long id;
    @Column("tenant_id") private Long tenantId;
    @Column("service_id") private Long serviceId;
    @Column("user_id") private Long userId;
    private String role;
    // ... más campos
}
```
**Tabla usada**: `service_participants` ✅

#### ServiceTypeEntity.java ✅
```java
@Table("service_types")  // ← Usa tabla: service_types
public class ServiceTypeEntity {
    @Id private Long id;
    private String code;
    private String name;
    private Boolean active;
    // ... más campos
}
```
**Tabla usada**: `service_types` ✅

### 🗃️ Repositorios (Repository.java):

#### RequestR2dbcRepository.java ✅
```java
@Query("SELECT s.*, st.code FROM services s JOIN service_types st ...")
Flux<RequestEntity> findAllWithType();

@Query("SELECT s.*, st.code FROM services s JOIN service_types st ...")
Flux<RequestEntity> findByTenantIdWithType(Long tenantId);

@Query("... FROM services s JOIN service_types st JOIN service_participants sp ...")
Flux<RequestEntity> findByParticipantUserIdWithType(Long userId);
```
**Tablas usadas**: `services`, `service_types`, `service_participants` ✅

#### ServiceParticipantR2dbcRepository.java ✅
```java
Flux<ServiceParticipantEntity> findByServiceId(Long serviceId);
Flux<ServiceParticipantEntity> findByServiceIdAndRole(Long serviceId, String role);
```
**Tabla usada**: `service_participants` (implícita por @Table) ✅

#### ServiceTypeR2dbcRepository.java ✅
```java
Flux<ServiceTypeEntity> findByActiveTrue();
Mono<ServiceTypeEntity> findByCode(String code);
```
**Tabla usada**: `service_types` (implícita por @Table) ✅

### ✅ RESULTADO REQUESTSSERVICE:
- ✅ Usa SOLO las tablas correctas: `services`, `service_participants`, `service_types`
- ❌ NO usa: `organizations`, `events`, `event_reactions`, `audit_logs`

---

## 2️⃣ VG-MS-PREPARATIONSERVICE-HEXAGONAL

### 📊 Total de Archivos Java: ~30 archivos

### 🗂️ Entidades (Entity.java):

#### PreparationEntity.java ✅
```java
@Data 
@Table("preparation")
public class PreparationEntity {
    @Id private Long id;
    @Column("request_id") private Long requestId;
    private String type;
    @Column("session_date") private LocalDate sessionDate;
    private String status;
    @Column("attendance_status") private String attendanceStatus;
    @Column("exam_score") private Integer examScore;
    @Column("exam_passed") private Boolean examPassed;
    @Column("tenant_id") private String tenantId;
    // ... más campos
}
```
**Tabla usada**: `preparation` ✅

### 🗃️ Repositorios:

Los repositorios de preparationservice usan Spring Data R2DBC automático (no tienen @Query custom), por lo que:
- Queries automáticos a tabla `preparation`
- No hay queries SQL manuales

### ✅ RESULTADO PREPARATIONSERVICE:
- ✅ Usa SOLO la tabla correcta: `preparation`
- ❌ NO usa: `organizations`, `events`, `event_reactions`, `audit_logs`

---

## 3️⃣ VG-MS-CERTIFICATESERVICE-HEXAGONAL

### 📊 Total de Archivos Java: ~30 archivos

### 🗂️ Entidades (Entity.java):

#### CertificateEntity.java ✅
```java
@Table("certificate")
public class CertificateEntity {
    @Id private Long id;
    @Column("tenant_id") private Long tenantId;
    @Column("request_id") private Long requestId;
    @Column("celebration_id") private Long celebrationId;
    @Column("certificate_type") private String certificateType;
    @Column("main_person_id") private Long mainPersonId;
    @Column("main_person_name") private String mainPersonName;
    @Column("certificate_data") private String certificateData;
    @Column("certificate_number") private String certificateNumber;
    private String book;
    private String folio;
    private Boolean signed;
    @Column("signed_at") private LocalDateTime signedAt;
    @Column("signed_by_user_id") private Long signedByUserId;
    // ... más campos
}
```
**Tabla usada**: `certificate` ✅

### 🗃️ Repositorios:

Los repositorios de certificateservice usan Spring Data R2DBC automático:
- Queries automáticos a tabla `certificate`
- Métodos como: `findByTenantId`, `findBySigned`, `findByCertificateType`

### ✅ RESULTADO CERTIFICATESERVICE:
- ✅ Usa SOLO la tabla correcta: `certificate`
- ❌ NO usa: `organizations`, `events`, `event_reactions`, `audit_logs`

---

## 4️⃣ VG-MS-CELEBRATIONSERVICE-HEXAGONAL

### 📊 Total de Archivos Java: ~30 archivos

### 🗂️ Entidades (Entity.java):

#### CelebrationEntity.java ✅
```java
@Table("celebration")
public class CelebrationEntity {
    @Id private Long id;
    @Column("request_id") private Long requestId;
    @Column("church_id") private UUID churchId;
    @Column("event_date") private LocalDate eventDate;
    @Column("event_time") private LocalTime eventTime;
    private String status;
    @Column("tenant_id") private Long tenantId;
    @Column("created_at") private LocalDateTime createdAt;
    @Column("updated_at") private LocalDateTime updatedAt;
}
```
**Tabla usada**: `celebration` ✅

### 🗃️ Repositorios:

Los repositorios de celebrationservice usan Spring Data R2DBC automático:
- Queries automáticos a tabla `celebration`
- Métodos como: `findByRequestId`, `findByTenantId`, `findByEventDate`

### ✅ RESULTADO CELEBRATIONSERVICE:
- ✅ Usa SOLO la tabla correcta: `celebration`
- ❌ NO usa: `organizations`, `events`, `event_reactions`, `audit_logs`

---

## 📊 RESUMEN GENERAL

### ✅ TABLAS CORRECTAS USADAS:

| Microservicio | Tablas Usadas | Estado |
|--------------|---------------|--------|
| requestsservice | `services`, `service_participants`, `service_types` | ✅ CORRECTO |
| preparationservice | `preparation` | ✅ CORRECTO |
| certificateservice | `certificate` | ✅ CORRECTO |
| celebrationservice | `celebration` | ✅ CORRECTO |

### ❌ TABLAS OBSOLETAS - NO ENCONTRADAS:

| Tabla Obsoleta | ¿Usada por los 4 backends? | Evidencia |
|---------------|----------------------------|-----------|
| `organizations` | ❌ NO | 0 referencias encontradas |
| `events` | ❌ NO | 0 referencias encontradas |
| `event_reactions` | ❌ NO | 0 referencias encontradas |
| `audit_logs` | ❌ NO | 0 referencias encontradas |

---

## 🔍 BÚSQUEDA EXHAUSTIVA REALIZADA

### Comandos Ejecutados:

```powershell
# 1. Listar todos los archivos Java
Get-ChildItem -Path "...\src\main\java" -Recurse -Filter "*.java"

# 2. Buscar en todos los archivos
Select-String -Pattern "organizations|events|event_reactions|audit_logs"

# 3. Extraer todas las anotaciones @Table
Select-String -Pattern "@Table\("
```

### Resultados:

```
✅ REQUESTSSERVICE: 
   @Table("services")
   @Table("service_participants")
   @Table("service_types")

✅ PREPARATIONSERVICE:
   @Table("preparation")

✅ CERTIFICATESERVICE:
   @Table("certificate")

✅ CELEBRATIONSERVICE:
   @Table("celebration")

❌ NINGUNA TABLA OBSOLETA ENCONTRADA
```

---

## ✅ CONCLUSIÓN FINAL

**DESPUÉS DE REVISAR ARCHIVO POR ARCHIVO:**

1. ✅ **Los 4 backends hexagonales están LIMPIOS**
   - NO usan tablas obsoletas
   - Solo usan tablas del esquema actual

2. ✅ **Todas las entidades (@Table) verificadas**
   - RequestEntity → `services`
   - ServiceParticipantEntity → `service_participants`
   - ServiceTypeEntity → `service_types`
   - PreparationEntity → `preparation`
   - CertificateEntity → `certificate`
   - CelebrationEntity → `celebration`

3. ✅ **Todos los repositorios verificados**
   - Queries SQL manuales: ✅ Revisados (solo usan tablas correctas)
   - Queries automáticos: ✅ Verificados (basados en @Table)

4. ❌ **Cero referencias a tablas obsoletas**
   - NO hay `organizations`
   - NO hay `events`
   - NO hay `event_reactions`
   - NO hay `audit_logs`

---

## 🎯 ORIGEN DE LAS TABLAS OBSOLETAS

Como los 4 backends hexagonales NO usan las tablas obsoletas, entonces:

### `organizations` ✅ CONFIRMADO
- Viene de: `vg-ms-organizationservice-develop` (otro microservicio)
- Es NECESARIA para ese microservicio
- Acción: ✅ MANTENER

### `events`, `event_reactions`, `audit_logs` ❓ DESCONOCIDO
- NO vienen de los 4 backends hexagonales
- NO vienen de organizationservice
- NO vienen de ningún microservicio del workspace
- Acción: ⚠️ Preguntar al equipo → Si nadie las usa, ELIMINAR

---

## 📄 ARCHIVOS DE REFERENCIA

- Schema SQL de cada backend (todos correctos)
- `CONFIRMACION_FINAL_TABLAS.md` - Confirmación después del git pull
- `ANALISIS_TABLAS_OBSOLETAS.md` - Análisis técnico completo
- `LIMPIEZA_TABLAS_OBSOLETAS.sql` - Script de limpieza seguro

---

**✅ REVISIÓN COMPLETADA**: Los 4 backends están correctos y NO usan tablas obsoletas.
