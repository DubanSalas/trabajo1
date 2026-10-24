# Estado del Frontend - Actualización Pendiente

## Fecha: 2026-10-17

---

## Resumen

El backend de **vg-ms-requestsservice** fue actualizado para eliminar el campo `userId` de la tabla `services`. Ahora **todas las personas** (incluido el solicitante) se registran en la tabla `service_participants` con su respectivo `role`.

### Cambios en el Backend (✅ Completados):

**Tabla `services`:**
- ❌ Eliminado: `user_id` (BIGINT)
- ❌ Eliminado: `sacrament_id` (UUID)

**Tabla `service_participants`:**
- ✅ Todas las personas se registran aquí con su role
- ✅ El solicitante principal usa `role='TITULAR'`

**Commit**: `d6a668f`  
**Push**: ✅ Exitoso a origin/develop

---

## Cambios en el Frontend

### ✅ COMPLETADO:

#### Archivo: `solicitudes.interface.ts`
- ✅ Interface `Service`: Eliminados `userId`, `peopleId`, `sacramentId`
- ✅ Comentarios actualizados explicando el nuevo modelo
- ✅ Interface `ServiceParticipant` con todos los roles

---

### ❌ PENDIENTE:

El frontend **NO** puede usarse actualmente porque los componentes TypeScript aún intentan acceder a `service.userId` que ya no existe en el backend.

## Archivos que Necesitan Actualización

### 1. **actas.ts** (4 referencias a `userId`)

**Línea 200-204:**
```typescript
// ❌ PROBLEMA: req.userId ya no existe
const userId = req?.userId;
const userName = userId ? this.getUserName(userId) : '—';
return { 
  certificate: cert, 
  request: req ?? undefined, 
  userName,
  userId  // ❌ Este campo ya no tiene valor
} as ActaEnriquecida;
```

**Solución propuesta:**
```typescript
// ✅ SOLUCIÓN: Obtener el TITULAR de service_participants
this.service.getServiceParticipants(cert.requestId!).pipe(
  map(participants => {
    const titular = participants.find(p => p.role === 'TITULAR');
    const userId = titular?.userId;
    const userName = userId ? this.getUserName(userId) : '—';
    return {
      certificate: cert,
      request: req ?? undefined,
      userName,
      userId,
      participants
    } as ActaEnriquecida;
  })
)
```

**Líneas 1266-1296:**
```typescript
// ❌ PROBLEMA: Acceso a participants.userId en PDF
const fatherUser = usersMap.get(father.userId || 0);
const motherUser = usersMap.get(mother.userId || 0);
const godfatherUser = godfather ? usersMap.get(godfather.userId || 0) : null;
```

**Solución:** Estos ya están bien (acceden a `participant.userId` no `service.userId`)

---

### 2. **solicitud-list.ts** (3 referencias a `userId`)

**Línea 103-107:**
```typescript
// ❌ PROBLEMA: s.userId ya no existe
return this.solicitudes().filter((s: Service) => {
  const personId = s.userId ?? 0;
  const userNombre = this.getUserName(personId).toLowerCase();
  // ...
});
```

**Solución propuesta:**
```typescript
// ✅ SOLUCIÓN A: Backend devuelve userId calculado (MÁS FÁCIL)
// El backend puede agregar un campo virtual @JsonProperty("userId")
// que devuelva el userId del participant con role='TITULAR'

// ✅ SOLUCIÓN B: Frontend carga participants (MÁS COMPLEJO)
// Cargar participants al inicio y guardar en Map<serviceId, userId>
private solicitanteMap = signal<Map<number, number>>(new Map());

// En ngOnInit después de cargar services:
const participantsObs = data.map(s => 
  this.service.getServiceParticipants(s.id!).pipe(
    map(participants => ({
      serviceId: s.id!,
      userId: participants.find(p => p.role === 'TITULAR')?.userId
    }))
  )
);

forkJoin(participantsObs).subscribe(mappings => {
  const map = new Map<number, number>();
  mappings.forEach(m => {
    if (m.userId) map.set(m.serviceId, m.userId);
  });
  this.solicitanteMap.set(map);
});

// En el filter:
const personId = this.solicitanteMap().get(s.id ?? 0) ?? 0;
```

**Línea 575 (PDF):**
```typescript
const persona = trunc(this.getUserName(s.userId), 28);
```

**Línea 1052 (Excel):**
```typescript
{ v: this.getUserName(s.userId), ... }
```

---

### 3. **solicitud-detail.ts** (3 referencias a `userId`)

**Línea 843:**
```typescript
// ❌ PROBLEMA: s.userId en PDF
['Persona solicitante', this.getUserName(s.userId)],
```

**Solución:** Obtener de participants cargados:
```typescript
const titular = this.participants().find(p => p.role === 'TITULAR');
['Persona solicitante', this.getUserName(titular?.userId)],
```

**Líneas 315, 320, 334, 350, 362, 374:**
Estos están **CORRECTOS** porque acceden a:
- `participantForm.userId` (formulario de agregar participant)
- `confirmed.userId` (participant ya cargado)

---

### 4. **solicitud-calendar.ts**

**NO usa `service.userId`** directamente, solo `request.userId` pero lo pasa al método `getUserName()` que está en el padre. Heredará el problema del componente padre.

---

## Opciones de Solución

### ⭐ **OPCIÓN A: Backend devuelve userId virtual (RECOMENDADA)**

**Ventajas:**
- ✅ Cambios mínimos en frontend
- ✅ Backward compatibility
- ✅ Menos requests HTTP

**Implementación:**
```java
// En Request.java (domain model)
@JsonProperty("userId")
public Long getUserId() {
    // Esto requiere que participants esté cargado en el dominio
    // O usar un DTO específico en la capa de presentación
    return null; // Placeholder
}

// En RequestResponse.java (DTO)
public class RequestResponse {
    private Long id;
    private Long userId; // ← Calculado desde participants
    // ...
    
    public static RequestResponse fromDomain(Request request, List<ServiceParticipant> participants) {
        RequestResponse dto = new RequestResponse();
        dto.setId(request.getId());
        
        // Buscar el TITULAR
        Long userId = participants.stream()
            .filter(p -> "TITULAR".equals(p.getRole()))
            .findFirst()
            .map(ServiceParticipant::getUserId)
            .orElse(null);
        dto.setUserId(userId);
        
        return dto;
    }
}
```

**Archivos backend a modificar:**
- `Request.java` o `RequestResponse.java` (agregar campo virtual)
- `RequestService.java` (cargar participants y calcular userId)
- `RequestRest.java` (usar DTO con userId calculado)

---

### **OPCIÓN B: Frontend consulta participants**

**Ventajas:**
- ✅ Backend mantiene modelo puro
- ✅ Separación de responsabilidades

**Desventajas:**
- ❌ Más requests HTTP (N+1 problem)
- ❌ Más código en frontend
- ❌ Más lento

**Implementación:** Ver código en la sección de `solicitud-list.ts` arriba.

---

## Recomendación

### 🎯 **Usar OPCIÓN A (Backend devuelve userId virtual)**

**Razones:**
1. El frontend ya espera `userId` en múltiples lugares
2. Menos cambios = menos riesgo de bugs
3. Mejor performance (evita requests adicionales)
4. Backward compatibility con código existante
5. El backend ya tiene acceso a participants, solo necesita exponerlo

**Pasos:**
1. ✅ **Backend**: Modificar el DTO de respuesta para incluir `userId` calculado
2. ✅ **Backend**: En el servicio, al devolver un `Service`, cargar participants y extraer userId del TITULAR
3. ✅ **Frontend**: Verificar que `service.userId` funciona correctamente
4. ✅ **Testing**: Probar listado, detalle, calendario y actas

---

## Estado de Dependencias

| Microservicio | Estado | Notas |
|---------------|--------|-------|
| vg-ms-certificateservice | ✅ Actualizado | Compañero refactorizó arquitectura |
| vg-ms-preparationservice | ✅ Limpio | Sin campos de pago |
| vg-ms-requestsservice | ⚠️ Schema OK, DTO pendiente | Necesita agregar userId virtual |
| vg-ms-celebrationservice | ✅ Sin cambios | - |
| vg-web-fideinexus | ⚠️ Interfaces OK, componentes pendientes | Esperando backend |

---

## Próximos Pasos

1. **Coordinación con compañero**: Confirmar que terminó la actualización de arquitectura
2. **Decisión del equipo**: ¿Backend devuelve userId virtual o frontend consulta participants?
3. **Implementación**:
   - Si OPCIÓN A → Modificar backend primero, luego probar frontend
   - Si OPCIÓN B → Actualizar componentes frontend
4. **Testing completo**:
   - Listado de solicitudes
   - Detalle de solicitud
   - Calendario
   - Actas (firmadas y sin firmar)
   - Búsqueda y filtros
   - Reportes PDF/Excel

---

## Archivos Modificados (Resumen)

### Backend (✅ Completado):
- `schema.sql` (requests, preparation, certificate)
- 27 archivos Java
- 3 archivos de migración SQL

### Frontend (⚠️ Parcial):
- ✅ `solicitudes.interface.ts` (interfaces actualizadas)
- ❌ `actas.ts` (pendiente)
- ❌ `solicitud-list.ts` (pendiente)
- ❌ `solicitud-detail.ts` (pendiente)
- ❌ `solicitud-calendar.ts` (heredará fix del padre)

---

## Contacto

Para dudas sobre esta actualización, consultar con el equipo de desarrollo.

**Documentos relacionados:**
- `RESUMEN_CAMBIOS_ESQUEMAS.md`
- `ACLARACION_FIRMA_MANUAL.md`
- `migration-remove-sacrament-id.sql`
