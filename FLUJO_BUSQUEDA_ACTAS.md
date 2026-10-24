# 🔍 Flujo de Búsqueda de Actas (Sin Desnormalización)

## ✅ Arquitectura Correcta: Single Source of Truth

### Base de Datos: Relaciones Limpias

```
┌─────────────────────────────────────────────────────────────┐
│ vg-ms-requestsservice (services)                            │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│ id, tenant_id, user_id, service_type_id, status             │
│                                                              │
│ ✅ Source of Truth para: persona (user_id) y tipo           │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ request_id (FK)
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ vg-ms-certificateservice (certificate)                      │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│ id, tenant_id, request_id, celebration_id                   │
│ certificate_number, book, folio, signed                     │
│                                                              │
│ ✅ Solo datos propios del acta (número, libro, folio)       │
│ ❌ NO duplica user_id ni service_type                       │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Flujo de Búsqueda en Frontend (actas.ts)

### 1. **Carga Inicial** (ngOnInit)

```typescript
ngOnInit() {
  // Paso 1: Cargar TODOS los usuarios una vez (cache en memoria)
  this.userService.getFeligreses(tenantId).subscribe(users => {
    const usersMap = new Map<number, User>();
    users.forEach(u => usersMap.set(u.id, u));
    this.usersMap.set(usersMap);  // ✅ Cache de nombres
  });
  
  // Paso 2: Cargar actas (solo IDs de usuario, sin nombres)
  forkJoin({
    signed: this.service.getCertificatesBySigned(true),
    unsigned: this.service.getCertificatesBySigned(false)
  }).subscribe(({ signed, unsigned }) => {
    const allCerts = [...signed, ...unsigned];
    this.enrichWithRequests(allCerts);  // ← Enriquece con datos de services
  });
}
```

### 2. **Enriquecimiento con Datos** (enrichWithRequests)

```typescript
private enrichWithRequests(certs: Certificate[]) {
  // Por cada certificado, obtener su service (solicitud)
  const obs = certs.map(cert =>
    this.service.getServiceById(cert.requestId!).pipe(
      map(req => {
        const userId = req?.userId;  // ← user_id viene de services
        const userName = userId ? this.getUserName(userId) : '—';  // ← lookup en usersMap
        return { 
          certificate: cert, 
          request: req,        // ✅ Tiene service_type_id
          userName,            // ✅ Lookup local (sin llamada de red)
          userId 
        };
      })
    )
  );
  
  forkJoin(obs).subscribe(enriched => {
    this.actas.set(enriched);  // ✅ Actas enriquecidas con nombres
  });
}
```

### 3. **Búsqueda en el Frontend** (actasFiltradas computed)

```typescript
actasFiltradas = computed(() => {
  const q = this.search().toLowerCase().trim();
  
  return this.actas().filter(a => {
    // ✅ Busca en el nombre que YA está en memoria (usersMap)
    const name = (a.userName ?? '').toLowerCase();
    const num  = (a.certificate.certificateNumber ?? '').toLowerCase();
    const id   = String(a.certificate.requestId ?? '');
    
    if (q && !name.includes(q) && !num.includes(q) && !id.includes(q)) {
      return false;
    }
    return true;
  });
});
```

---

## 🎯 Ventajas de NO Desnormalizar

### ✅ **Ventajas**

1. **Single Source of Truth**: `user_id` solo existe en `services`
2. **No hay sincronización**: Si cambia el nombre en People, no hay que actualizar certificates
3. **Menos espacio en BD**: No duplicamos VARCHAR(200) por cada acta
4. **Código más simple**: No hay lógica de "mantener campos sincronizados"
5. **Funciona perfecto**: El frontend ya carga usuarios en memoria (cache)

### ⚠️ **Trade-off Aceptable**

- **Costo**: Al cargar actas, hace 1 llamada por acta para obtener el service
- **Mitigación**: Se hace solo 1 vez al entrar al módulo (no en cada búsqueda)
- **Volumen real**: ~100-500 actas por parroquia al año → no es problema

---

## 📈 Comparación de Performance

### ❌ **Con Desnormalización** (anterior)

```
DB: 500 actas × 200 bytes por nombre = 100 KB extras
Carga inicial: SELECT * FROM certificate (rápido, 1 query)
Búsqueda: Rápida (todo en 1 tabla)
Mantenimiento: COMPLEJO (¿qué pasa si cambia el nombre?)
```

### ✅ **Sin Desnormalización** (actual)

```
DB: Sin duplicación = 0 KB extras
Carga inicial: 
  - 1 query a vg-ms-certificateservice (500 actas)
  - 500 queries a vg-ms-requestsservice (paralelas, ~2s total)
  - 1 query a vg-ms-users (100 usuarios) → cache en memoria
Búsqueda: Rápida (filtrado en memoria con usersMap)
Mantenimiento: SIMPLE (single source of truth)
```

---

## 🔧 Migración Aplicada

```sql
-- Eliminados estos campos duplicados:
-- certificate_type     ❌ (ya está en services.service_type_id)
-- main_person_id       ❌ (ya está en services.user_id)
-- main_person_name     ❌ (lookup en usersMap desde frontend)
-- certificate_data     ❌ (service_participants ya tiene esto)

-- Quedó solo lo esencial:
CREATE TABLE certificate (
    id, tenant_id, request_id, celebration_id,
    certificate_number, book, folio, signed,
    copies_issued, last_copy_date,
    issued_at, created_at, updated_at
);
```

---

## 💡 Conclusión

**No necesitas desnormalizar** porque:
1. ✅ El frontend ya hace cache de usuarios (usersMap)
2. ✅ El volumen de datos es pequeño (~500 actas/año)
3. ✅ La búsqueda es rápida (filtrado en memoria)
4. ✅ Mantener 1 fuente de verdad es más seguro
5. ✅ El código es más simple y mantenible

**Regla de oro**: Solo desnormaliza si tienes **millones de registros** y las búsquedas son **lentas** (>5 segundos). Para 500-1000 actas, no vale la pena la complejidad extra.
