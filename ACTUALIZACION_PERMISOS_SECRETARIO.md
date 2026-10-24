# Actualización de Permisos - SECRETARIO puede Aprobar/Rechazar

## Fecha: 2026-10-17

---

## 🎯 Objetivo

Permitir que tanto **SECRETARIO** como **PÁRROCO** puedan:
- ✅ Aprobar/Rechazar solicitudes
- ✅ Firmar certificados/actas
- ✅ Gestionar todo el flujo sacramental

---

## ✅ Cambios Realizados

### 1. Frontend (3 archivos TypeScript)

#### 📄 `solicitud-detail.ts`
**Antes:**
```typescript
canApprove = computed(() => {
  const user = this.authService.getUser();
  return user?.role === 'PARROCO';  // ❌ Solo PARROCO
});
```

**Después:**
```typescript
canApprove = computed(() => {
  const user = this.authService.getUser();
  // Tanto PARROCO como SECRETARIO pueden aprobar/rechazar solicitudes
  return user?.role === 'SECRETARIO' || user?.role === 'PARROCO';  // ✅
});
```

---

#### 📄 `solicitud-list.ts`
**Antes:**
```typescript
canApprove = computed(() => {
  const user = this.authService.getUser();
  return user?.role === 'PARROCO';  // ❌ Solo PARROCO
});
```

**Después:**
```typescript
canApprove = computed(() => {
  const user = this.authService.getUser();
  // Tanto PARROCO como SECRETARIO pueden aprobar/rechazar solicitudes
  return user?.role === 'PARROCO' || user?.role === 'SECRETARIO';  // ✅
});
```

---

#### 📄 `actas.ts`
**Antes:**
```typescript
canApprove = computed(() => 
  this.authService.getUser()?.role === 'PARROCO'  // ❌ Solo PARROCO
);
```

**Después:**
```typescript
canApprove = computed(() => 
  this.authService.getUser()?.role === 'PARROCO' || 
  this.authService.getUser()?.role === 'SECRETARIO'  // ✅
);
```

---

### 2. Backend Java (1 archivo)

#### 📄 `CertificateRest.java` (vg-ms-certificateservice)

**Endpoint:** `PATCH /api/v1/certificates/{id}/sign` (Firmar acta)

**Antes:**
```java
@PreAuthorize("hasAnyRole('PARROCO')")  // ❌ Solo PARROCO
@PatchMapping("/{id}/sign")
public Mono<CertificateResponse> sign(...)
```

**Después:**
```java
@PreAuthorize("hasAnyRole('SECRETARIO','PARROCO')")  // ✅
@PatchMapping("/{id}/sign")
public Mono<CertificateResponse> sign(...)
```

---

## ✅ Backend - Estado de Permisos

### vg-ms-requestsservice (Solicitudes)

**Todos los endpoints YA tenían permisos correctos:**

```java
@PreAuthorize("hasAnyRole('SECRETARIO', 'PARROCO')")
@GetMapping                           // Listar solicitudes
@GetMapping("/{id}")                  // Ver detalle
@PostMapping                          // Crear solicitud
@PutMapping("/{id}")                  // Actualizar solicitud
@PatchMapping("/{id}/status")         // ✅ Cambiar estado (Aprobar/Rechazar)
@DeleteMapping("/{id}")               // Eliminar solicitud
```

**Estado:** ✅ No requiere cambios

---

### vg-ms-certificateservice (Certificados/Actas)

**Endpoints verificados:**

```java
@PreAuthorize("hasAnyRole('SECRETARIO','PARROCO')")
@GetMapping("/request/{requestId}")      // Buscar por solicitud
@GetMapping("/signed/{signed}")          // Listar firmadas/sin firmar
@PostMapping("/generate")                // Generar acta
@PatchMapping("/{id}/sign")              // ✅ FIRMAR ACTA (ACTUALIZADO)
```

**Estado:** ✅ Actualizado (era solo PARROCO, ahora incluye SECRETARIO)

---

### vg-ms-preparationservice (Preparación)

**Permisos verificados (ejemplos):**

```java
@PreAuthorize("hasAnyRole('SECRETARIO', 'PARROCO')")
// Todos los endpoints de preparación
```

**Estado:** ✅ No requiere cambios

---

### vg-ms-celebrationservice (Celebración)

**Permisos verificados (ejemplos):**

```java
@PreAuthorize("hasAnyRole('SECRETARIO', 'PARROCO')")
// Todos los endpoints de celebración
```

**Estado:** ✅ No requiere cambios

---

## 📊 Resumen de Cambios

| Archivo | Ubicación | Tipo | Estado |
|---------|-----------|------|--------|
| `solicitud-detail.ts` | Frontend | TypeScript | ✅ Actualizado |
| `solicitud-list.ts` | Frontend | TypeScript | ✅ Actualizado |
| `actas.ts` | Frontend | TypeScript | ✅ Actualizado |
| `CertificateRest.java` | Backend | Java | ✅ Actualizado |
| `RequestRest.java` | Backend | Java | ✅ Ya estaba correcto |
| Otros microservicios | Backend | Java | ✅ Ya estaban correctos |

---

## 🎯 Resultado Final

### Ahora SECRETARIO puede:

1. ✅ **Aprobar solicitudes** (cambiar estado a APPROVED)
2. ✅ **Rechazar solicitudes** (cambiar estado a REJECTED)
3. ✅ **Firmar actas/certificados** (registrar firma manual del párroco)
4. ✅ **Gestionar inscripción** (agregar participantes)
5. ✅ **Gestionar preparación** (registrar sesiones)
6. ✅ **Gestionar celebración** (programar eventos)
7. ✅ **Ver todas las solicitudes** (listar y buscar)

### PÁRROCO sigue teniendo:

1. ✅ **Todos los mismos permisos que SECRETARIO**
2. ✅ **Autoridad final** sobre el proceso sacramental

---

## 🚀 Próximos Pasos

### Frontend:
1. ✅ Cambios realizados (3 archivos)
2. ⏳ **Pendiente:** Commit y push

### Backend:
1. ✅ Cambio realizado en `CertificateRest.java`
2. ⏳ **Pendiente:** Compilar y verificar
3. ⏳ **Pendiente:** Commit y push

---

## 📝 Notas Técnicas

### Roles en el Sistema:

```typescript
// Jerarquía de permisos (mayor a menor)
SUPERADMIN    // Administrador global de plataforma
PARROCO       // Párroco de una parroquia
SECRETARIO    // Secretario/a parroquial
FELIGRES      // Feligrés/usuario regular
PADRINO       // Padrino (solo para sacramentos)
MADRINA       // Madrina (solo para sacramentos)
```

### Diferencias entre PARROCO y SECRETARIO:

| Función | PARROCO | SECRETARIO |
|---------|---------|------------|
| Aprobar solicitudes | ✅ | ✅ |
| Rechazar solicitudes | ✅ | ✅ |
| Firmar actas | ✅ | ✅ |
| Celebrar sacramentos | ✅ | ❌ (Solo párroco celebra) |
| Gestionar parroquia | ✅ | ✅ |

**Nota:** En la práctica, el SECRETARIO **registra** la firma del párroco en el sistema (el párroco firma físicamente el libro parroquial, el secretario lo registra en el sistema digital).

---

## ✅ Validación de Seguridad

### Spring Security - hasAnyRole()

```java
@PreAuthorize("hasAnyRole('SECRETARIO','PARROCO')")
```

**Comportamiento:**
- ✅ Usuario con role `SECRETARIO` → Acceso permitido
- ✅ Usuario con role `PARROCO` → Acceso permitido
- ❌ Usuario con role `FELIGRES` → Acceso denegado (403 Forbidden)
- ❌ Sin autenticación → Acceso denegado (401 Unauthorized)

### Angular - canApprove

```typescript
canApprove = computed(() => 
  user?.role === 'SECRETARIO' || user?.role === 'PARROCO'
);
```

**Uso en template:**
```html
<button *ngIf="canApprove()" (click)="approve()">
  Aprobar Solicitud
</button>
```

**Comportamiento:**
- ✅ SECRETARIO → Botón visible
- ✅ PARROCO → Botón visible
- ❌ FELIGRES → Botón oculto

---

## 🔒 Consideraciones de Seguridad

1. ✅ **Doble validación:** Frontend (UI) + Backend (API)
2. ✅ **JWT con roles:** El token incluye el role del usuario
3. ✅ **Spring Security:** Valida permisos en cada request
4. ✅ **Sin bypass:** No se puede saltar la seguridad del backend
5. ✅ **Auditoría:** Cada cambio registra quién lo hizo (`signedByUserId`)

---

## 📌 Conclusión

**SECRETARIO y PARROCO ahora tienen los mismos permisos** para gestionar solicitudes y actas sacramentales. Esto agiliza el trabajo parroquial sin comprometer la seguridad.
