# 🔧 Corrección de Schemas - Microservicios FideiNexus

**Fecha:** 19 de Octubre 2026  
**Responsables:** Equipo de Desarrollo

---

## 📋 Cambios Realizados

### 1️⃣ **vg-ms-preparationservice** ✅

#### **Problema detectado:**
- `preparation.tenant_id` era `VARCHAR(100)` en lugar de `BIGINT`
- Inconsistencia con el resto de microservicios

#### **Solución aplicada:**
- ✅ Cambiado `tenant_id` a `BIGINT` en schema.sql
- ✅ Agregado script de migración automática para BDs existentes
- ✅ Actualizado modelo de dominio `Preparation.java`
- ✅ Actualizado `TEST_DATA_TENANT_9.sql` con orden correcto de columnas
- ✅ Agregados comentarios explicativos en todas las columnas

#### **Archivos modificados:**
- `vg-ms-preparationservice-hexagonal/src/main/resources/sql/schema.sql`
- `vg-ms-preparationservice-hexagonal/src/main/java/.../Preparation.java`
- `TEST_DATA_TENANT_9.sql`

---

### 2️⃣ **vg-ms-servicesservice** ✅

#### **Mejoras aplicadas:**
- ✅ Eliminado código de compatibilidad obsoleto (ALTER TABLE)
- ✅ Agregados comentarios explicativos detallados
- ✅ Documentación clara de referencias lógicas vs FKs
- ✅ Mejorada estructura y organización del schema

#### **Archivos modificados:**
- `vg-ms-servicesservice-hexagonal/src/main/resources/sql/schema.sql`

---

### 3️⃣ **vg-ms-celebrationservice** ✅

#### **Mejoras aplicadas:**
- ✅ Agregados comentarios explicativos
- ✅ Mejorada estructura de índices
- ✅ Documentación de propósito y relaciones
- ✅ Índice para evitar conflictos de horario mejorado

#### **Archivos modificados:**
- `vg-ms-celebrationservice-hexagonal/src/main/resources/sql/schema.sql`

---

### 4️⃣ **vg-ms-certificateservice** ✅

#### **Cambios previos confirmados:**
- ✅ Eliminados campos redundantes: `certificate_type`, `main_person_id`, `main_person_name`, `certificate_data`
- ✅ Eliminados campos de control de copias: `copies_issued`, `last_copy_date`
- ✅ Schema simplificado y normalizado
- ✅ Comentarios explicativos agregados

#### **Archivos ya modificados:**
- `vg-ms-certificateservice-hexagonal/src/main/resources/sql/schema.sql`

---

## 🎯 Estado Final de las Tablas

### **Tabla: services** (Orquestador principal)
```sql
id, tenant_id, service_type_id (FK), church_id (UUID),
description, document_url, scheduled_date, status,
request_date, certificate_id, response_data,
created_at, updated_at
```
✅ tenant_id: BIGINT  
✅ Referencias: church_id (lógica), certificate_id (lógica)

---

### **Tabla: service_participants**
```sql
id, tenant_id, service_id (FK), user_id,
role, document_url, created_at, updated_at
```
✅ tenant_id: BIGINT  
✅ Referencias: user_id (lógica a vg-ms-users)

---

### **Tabla: preparation**
```sql
id, tenant_id, service_id, type, session_date,
status, attendance_status, exam_score, exam_passed,
notes, created_at, updated_at
```
✅ tenant_id: BIGINT ← **CORREGIDO**  
✅ Referencias: service_id (lógica a services)

---

### **Tabla: celebration**
```sql
id, tenant_id, service_id, church_id (UUID),
event_date, event_time, status,
created_at, updated_at
```
✅ tenant_id: BIGINT  
✅ Referencias: service_id (lógica), church_id (lógica)

---

### **Tabla: certificate**
```sql
id, tenant_id, service_id, celebration_id,
certificate_number, book, folio,
signed, signed_at, signed_by_user_id,
issued_at, created_at, updated_at
```
✅ tenant_id: BIGINT  
✅ Referencias: service_id (lógica), celebration_id (lógica)  
✅ Simplificado: sin campos redundantes

---

## 📦 Scripts de Migración

### **Para aplicar en BD existente:**
```bash
# 1. Ejecutar migración de preparation.tenant_id
psql -h <host> -U <user> -d <database> -f migration-fix-preparation-tenant.sql
```

### **Para BD nueva:**
Los schemas ya están corregidos. Solo ejecutar en orden:
1. `vg-ms-servicesservice/sql/schema.sql`
2. `vg-ms-preparationservice/sql/schema.sql`
3. `vg-ms-celebrationservice/sql/schema.sql`
4. `vg-ms-certificateservice/sql/schema.sql`

---

## ✅ Principios de Diseño Aplicados

1. **Sin FKs entre microservicios** ✓
   - Solo FKs dentro del mismo microservicio
   - Referencias lógicas para comunicación entre MS

2. **Tipos de datos consistentes** ✓
   - `tenant_id`: BIGINT en todos los servicios
   - `service_id`: BIGINT (referencia lógica)
   - `church_id`: UUID (referencia lógica)

3. **Sin duplicación de datos** ✓
   - Cada tabla solo contiene sus datos propios
   - No hay campos redundantes de otros servicios

4. **Índices bien diseñados** ✓
   - Índices simples para búsquedas frecuentes
   - Índices compuestos para queries complejas
   - Índices parciales donde aplica

5. **Documentación clara** ✓
   - Comentarios en todas las tablas
   - Comentarios en columnas clave
   - Referencias explicadas

---

## 🚀 Próximos Pasos

1. ✅ Schemas corregidos y documentados
2. ⏳ Ejecutar migración en BD de desarrollo
3. ⏳ Verificar que el backend compile sin errores
4. ⏳ Ejecutar tests unitarios
5. ⏳ Probar flujo completo en frontend

---

## 📝 Notas Adicionales

- La migración de `tenant_id` es automática y no destructiva
- Los datos existentes se convierten automáticamente con `USING tenant_id::BIGINT`
- Se incluye verificación previa para evitar errores
- Compatible con instalaciones existentes de NeonDB

---

**Revisado por:** Kiro AI Assistant  
**Aprobado por:** Equipo de Desarrollo
