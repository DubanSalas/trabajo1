# Flujo de Asistencia en Preparación

## Fecha: 2026-10-17

---

## 🎯 ¿Cómo Funciona la Asistencia en Preparación?

La **asistencia** en las sesiones de preparación se registra a nivel de **cada sesión** para controlar quién asistió, quién faltó y quién justificó su ausencia.

---

## 📊 Campos en la Base de Datos

### Tabla: `preparation`

```sql
CREATE TABLE preparation (
    id                   BIGSERIAL       PRIMARY KEY,
    request_id           BIGINT          NOT NULL,
    type                 VARCHAR(20)     NOT NULL DEFAULT 'TITULAR',
    session_date         DATE            NOT NULL,
    
    -- Estado general de la sesión
    status               VARCHAR(30)     NOT NULL DEFAULT 'PENDING',
    
    -- ⬇️ ASISTENCIA (campo separado)
    attendance_status    VARCHAR(20),     -- PRESENT | ABSENT | EXCUSED
    
    -- Para Confirmación: examen
    exam_score           INTEGER,
    exam_passed          BOOLEAN,
    
    notes                TEXT,
    created_at           TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMP       NOT NULL DEFAULT NOW(),
    tenant_id            VARCHAR(100)    NOT NULL
);
```

### Campos Clave

| Campo | Tipo | Valores | Descripción |
|-------|------|---------|-------------|
| `status` | VARCHAR(30) | PENDING, IN_PROGRESS, COMPLETED, CANCELLED | Estado general de la sesión |
| `attendance_status` | VARCHAR(20) | PRESENT, ABSENT, EXCUSED | Estado de asistencia específico |

---

## 🔄 Flujo de Registro

### 1. **Crear Sesión de Preparación**

Cuando se crea una sesión:
```
status = 'PENDING'
attendance_status = NULL  (sin registrar)
```

### 2. **Registrar Asistencia**

Cuando llega el día de la sesión, el secretario o párroco registra:

**Opciones:**
- ✅ **PRESENT** - La persona asistió
- ❌ **ABSENT** - La persona faltó sin justificación
- ⚠️ **EXCUSED** - La persona faltó pero justificó su ausencia

### 3. **Completar Sesión**

Una vez registrada la asistencia:
```
status = 'COMPLETED'
attendance_status = 'PRESENT' | 'ABSENT' | 'EXCUSED'
```

---

## 🎨 Visualización en Frontend

### Estado de Asistencia en Tarjetas

**Código HTML:**
```html
@if (prep.attendanceStatus) {
  <div class="flex items-center gap-1.5">
    <svg class="w-3.5 h-3.5 text-slate-400">...</svg>
    <span [class]="attendanceStatusClass(prep.attendanceStatus)" 
          class="px-2 py-0.5 rounded-md text-[10px] font-bold">
      {{ attendanceStatusLabel(prep.attendanceStatus) }}
    </span>
  </div>
}
```

**Métodos TypeScript:**
```typescript
attendanceStatusLabel(status?: string): string {
  const map: Record<string, string> = {
    PRESENT: 'Presente',
    ABSENT: 'Ausente',
    EXCUSED: 'Justificado',
  };
  return status ? (map[status] ?? status) : '—';
}

attendanceStatusClass(status?: string): string {
  const map: Record<string, string> = {
    PRESENT: 'bg-emerald-100 text-emerald-700',
    ABSENT: 'bg-red-100 text-red-600',
    EXCUSED: 'bg-blue-100 text-blue-600',
  };
  return map[status ?? ''] ?? 'bg-slate-100 text-slate-500';
}
```

### Colores

- **PRESENT** 🟢 - Verde (emerald-100/700)
- **ABSENT** 🔴 - Rojo (red-100/600)
- **EXCUSED** 🔵 - Azul (blue-100/600)

---

## ✏️ Formulario de Edición

### Modal de Editar Sesión

```html
<div>
  <label>Estado de asistencia</label>
  <select [(ngModel)]="prep.attendanceStatus">
    <option value="">Sin registrar</option>
    <option value="PRESENT">Presente</option>
    <option value="ABSENT">Ausente</option>
    <option value="EXCUSED">Justificado</option>
  </select>
</div>
```

**Ubicación:** Modal "Editar Sesión de Preparación" en `solicitud-detail.html`

---

## 🔍 Ejemplo de Uso

### Caso: Bautismo con 2 sesiones de preparación

#### Sesión 1: Titular (Padres)
```json
{
  "id": 1,
  "requestId": 123,
  "type": "TITULAR",
  "sessionDate": "2026-10-20",
  "status": "COMPLETED",
  "attendanceStatus": "PRESENT",  // ✅ Asistieron
  "notes": "Padres completaron sesión 1"
}
```

#### Sesión 2: Padrinos
```json
{
  "id": 2,
  "requestId": 123,
  "type": "SPONSORS",
  "sessionDate": "2026-10-21",
  "status": "COMPLETED",
  "attendanceStatus": "EXCUSED",  // ⚠️ Justificaron ausencia
  "notes": "Padrinos faltaron por enfermedad (justificado)"
}
```

---

## 📋 Reglas de Validación

### ✅ Para que una solicitud pueda pasar a Celebración:

1. **Todas las sesiones deben estar COMPLETED**
   ```typescript
   allPreparationsOk = computed(() =>
     this.preparations().length > 0 &&
     this.preparations().every(p => p.status === 'COMPLETED')
   );
   ```

2. **¿Importa el attendance_status?**
   - ❌ NO bloquea la celebración
   - ℹ️ Es solo para registro y estadísticas
   - ✅ Puede haber asistido (PRESENT), faltado (ABSENT) o justificado (EXCUSED)

**Nota:** La asistencia se registra para control interno, pero no impide que se programe la celebración si todas las sesiones están marcadas como COMPLETED.

---

## 🔄 Flujo Completo

```
1. Crear solicitud → APPROVED
2. Agregar participantes (inscripción)
3. Crear sesiones de preparación:
   Sesión 1: type=TITULAR, status=PENDING, attendanceStatus=NULL
   Sesión 2: type=SPONSORS, status=PENDING, attendanceStatus=NULL

4. Día de la sesión 1:
   - Secretario edita sesión
   - Registra: attendanceStatus=PRESENT
   - Marca: status=COMPLETED

5. Día de la sesión 2:
   - Secretario edita sesión
   - Registra: attendanceStatus=ABSENT
   - Marca: status=COMPLETED

6. Validación para Celebración:
   ✅ Sesión 1: COMPLETED
   ✅ Sesión 2: COMPLETED
   → Permite crear celebración

7. Se programa celebración
8. Se realiza celebración
9. Se genera acta
10. Párroco firma acta
```

---

## 🎯 Diferencia: `status` vs `attendance_status`

| Campo | Propósito | Afecta Celebración |
|-------|-----------|-------------------|
| `status` | Estado general de la sesión (pendiente/completada/cancelada) | ✅ SÍ - Debe ser COMPLETED |
| `attendance_status` | Registro de asistencia (presente/ausente/justificado) | ❌ NO - Solo informativo |

**Ejemplo:**
- Una sesión puede estar `status=COMPLETED` y `attendanceStatus=ABSENT`
- Significa: "La sesión ya pasó, la persona NO asistió"
- ¿Bloquea? NO, solo se registra para control

---

## 📊 Casos Especiales

### Confirmación: Examen Obligatorio

Además de la asistencia, Confirmación requiere:
```typescript
{
  "attendanceStatus": "PRESENT",
  "examScore": 85,        // 0-100
  "examPassed": true      // true si aprobó
}
```

**Validación:**
- Si `examScore >= 70` → `examPassed = true`
- Si `examScore < 70` → `examPassed = false`

---

## ✅ Resumen

| Aspecto | Estado Actual |
|---------|--------------|
| **Campo en BD** | ✅ `attendance_status` VARCHAR(20) |
| **Valores** | ✅ PRESENT, ABSENT, EXCUSED |
| **Frontend - Visualización** | ✅ Implementado con colores |
| **Frontend - Edición** | ✅ Select con 3 opciones |
| **Backend - Modelo** | ✅ Campo en Preparation.java |
| **Validación** | ✅ No bloquea celebración |
| **Uso** | ✅ Control interno y estadísticas |

**Todo está implementado y funcionando correctamente.** ✅
