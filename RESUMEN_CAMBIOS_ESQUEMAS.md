# Resumen de Cambios en Esquemas de BD

## Fecha: 2026-10-17

---

## 1. vg-ms-certificateservice-hexagonal ✅

### **Campos Eliminados:**
- ❌ `copies_issued` (INTEGER)
- ❌ `last_copy_date` (TIMESTAMP)

### **Razón:**
No se necesita contador de descargas de PDFs. El certificado se genera una vez y puede descargarse libremente.

### **Schema Final (14 campos):**
```sql
CREATE TABLE certificate (
    id, tenant_id, request_id, celebration_id,
    certificate_number, book, folio,
    signed, signed_at, signed_by_user_id,
    issued_at, created_at, updated_at
);
```

### **Commit:** `fe3209c`
### **Archivos Modificados:** 10 archivos Java + schema.sql

---

## 2. vg-ms-preparationservice-hexagonal ✅

### **Campos Eliminados:**
- ❌ `payment_amount` (DECIMAL)
- ❌ `payment_status` (VARCHAR)
- ❌ `payment_date` (DATE)
- ❌ `payment_receipt_url` (TEXT)

### **Razón:**
Los datos de pago deben obtenerse del microservicio de pagos/finanzas (evitar duplicación de responsabilidades).

### **Schema Final (12 campos):**
```sql
CREATE TABLE preparation (
    id, request_id, type, session_date, status, attendance_status,
    exam_score, exam_passed, notes,
    created_at, updated_at, tenant_id
);
```

### **Commit:** `570e7a0`
### **Archivos Modificados:** 10 archivos Java + schema.sql

---

## 3. vg-ms-requestsservice-hexagonal 🔄 PENDIENTE

### **Campos Eliminados:**

#### **Tabla `services`:**
- ❌ `sacrament_id` (UUID) → Redundante con `service_type_id`
- ❌ `user_id` (BIGINT) → Duplicado en `service_participants`

### **Razón:**
1. **sacrament_id**: `service_type_id` ya identifica el tipo de sacramento, no se necesita otro UUID
2. **user_id**: Creaba doble registro de la misma persona:
   - En `services.user_id`
   - En `service_participants` con `role='TITULAR'`

### **Schema Final `services` (13 campos):**
```sql
CREATE TABLE services (
    id, tenant_id, service_type_id, church_id,
    description, document_url, scheduled_date,
    status, request_date, certificate_id, response_data,
    created_at, updated_at
);
```

### **Schema `service_participants` (8 campos):**
```sql
CREATE TABLE service_participants (
    id, tenant_id, service_id, user_id, role, document_url,
    created_at, updated_at
);
```

**Roles disponibles:**
- TITULAR (solicitante principal)
- BENEFICIARY (quien recibe el sacramento)
- FATHER, MOTHER (padres)
- GODFATHER, GODMOTHER (padrinos de bautismo)
- SPONSOR (padrino de confirmación)
- GROOM, BRIDE (novios)
- WITNESS (testigos de matrimonio)

### **Archivos Modificados:** 9 archivos Java + schema.sql + migration.sql

---

## 4. vg-ms-celebrationservice-hexagonal ✅

### **Sin Cambios**
El schema está correcto con 9 campos.

---

## Migraciones SQL Creadas:

1. `migration-remove-copies-control.sql` - Elimina campos de copias de certificate
2. `migration-remove-payment-fields.sql` - Elimina campos de pago de preparation
3. `migration-remove-sacrament-id.sql` - Elimina sacrament_id y user_id de services, migra datos a service_participants

---

## Frontend Actualizado ✅

### **Archivo:** `solicitudes.interface.ts`

**Cambios en interface `Service`:**
- ❌ Eliminado: `userId`, `peopleId`, `sacramentId`
- ✅ Comentarios actualizados explicando que ahora se usa `service_participants`

**Cambios en interface `Certificate`:**
- ❌ Eliminado: `copiesIssued`, `lastCopyDate`, `certificateType`, `mainPersonId`, `mainPersonName`, `certificateData`
- ✅ Simplificado a solo 14 campos esenciales

**Cambios en interface `Preparation`:**
- ❌ Eliminado: `paymentAmount`, `paymentStatus`, `paymentDate`, `paymentReceiptUrl`
- ✅ Solo 12 campos de preparación sacramental

---

## Estado Actual:

| Microservicio | Estado | Commit | Push |
|---------------|--------|--------|------|
| certificate | ✅ Limpio | fe3209c | ✅ |
| preparation | ✅ Limpio | 570e7a0 | ✅ |
| requests | 🔄 Modificado | Pendiente | ❌ |
| celebration | ✅ Sin cambios | - | - |
| **Frontend** | ✅ Actualizado | Pendiente | ❌ |

---

## Próximos Pasos:

1. ✅ Commit y push de cambios en `vg-ms-requestsservice-hexagonal`
2. ✅ Commit y push de cambios en frontend (`vg-web-fideinexus-develop`)
3. ⚠️ Ejecutar migraciones SQL en BD de desarrollo/producción
4. ⚠️ Actualizar documentación de API si existe
5. ⚠️ Avisar al equipo sobre cambios en contratos de API

---

## Beneficios de los Cambios:

✅ **Eliminación de redundancia** - No más datos duplicados  
✅ **Separación de responsabilidades** - Cada microservicio maneja lo suyo  
✅ **Normalización** - Datos en el lugar correcto  
✅ **Flexibilidad** - service_participants permite múltiples roles  
✅ **Mantenibilidad** - Código más limpio y fácil de entender
