# 🔍 RESUMEN: Investigación de Tablas Obsoletas

**Fecha**: 18 de Octubre 2026  
**Investigadores**: Duban + Ordoñez  
**Estado**: ✅ INVESTIGACIÓN COMPLETA

---

## 🎯 PREGUNTA ORIGINAL

> "¿Por qué aparecieron tablas obsoletas en la BD si solo ejecuté los backends?"

---

## ✅ RESPUESTA ENCONTRADA

### Tabla `organizations` - ✅ ORIGEN CONFIRMADO

**Tu compañero ejecutó `vg-ms-organizationservice-develop` y apareció la tabla.**

**¿Por qué?**

1. El microservicio `vg-ms-organizationservice-develop` **SÍ USA** la tabla `organizations`
2. Tiene código Java que hace queries:
   ```java
   @Query("SELECT * FROM organizations WHERE deleted = false")
   Flux<OrganizationEntity> findAllByDeletedFalse();
   ```
3. Cuando lo ejecutó, el microservicio intentó hacer `SELECT * FROM organizations`
4. **La tabla NO existía → ERROR**
5. Alguien ejecutó manualmente el script `schema_organization.sql` para arreglarlo
6. **Resultado**: La tabla apareció en la BD

**Archivos que comprueban esto:**
```
✅ vg-ms-organizationservice-develop/src/main/java/.../OrganizationEntity.java
   → @Table("organizations")

✅ vg-ms-organizationservice-develop/src/main/java/.../OrganizationR2dbcRepository.java
   → SELECT * FROM organizations

✅ vg-ms-organizationservice-develop/src/main/resources/schema_organization.sql
   → CREATE TABLE organizations (...)
```

---

### Tablas `events`, `event_reactions`, `audit_logs` - ❓ ORIGEN DESCONOCIDO

**NO encontré código Java en NINGÚN microservicio que use estas tablas.**

**Búsqueda realizada:**
```bash
✅ vg-ms-requestsservice-hexagonal   → NO usa estas tablas
✅ vg-ms-preparationservice-hexagonal → NO usa estas tablas
✅ vg-ms-certificateservice-hexagonal → NO usa estas tablas
✅ vg-ms-celebrationservice-hexagonal → NO usa estas tablas
✅ vg-ms-organizationservice-develop  → NO usa estas tablas
✅ vg-ms-usersmicroservice-hexagonal  → NO usa estas tablas
✅ vg-ms-locations-develop            → NO usa estas tablas
✅ vg-ms-sacramentservice-develop     → NO usa estas tablas
```

**Posibles orígenes:**
1. Versión MUY antigua del sistema
2. Otro repositorio que NO está en este workspace
3. Alguien las creó manualmente con SQL
4. Sistema externo que compartía la misma BD

---

## 📊 RESUMEN DE TABLAS

| Tabla | ¿Usada? | Microservicio | Acción |
|-------|---------|---------------|--------|
| **organizations** | ✅ SÍ | organizationservice | ✅ **MANTENER** |
| **events** | ❌ NO | NINGUNO | ⚠️ Preguntar al equipo |
| **event_reactions** | ❌ NO | NINGUNO | ⚠️ Preguntar al equipo |
| **audit_logs** | ❌ NO | NINGUNO | ⚠️ Preguntar al equipo |
| requests | ❌ NO | OBSOLETO | ✅ Eliminar |
| enrollment_participants | ❌ NO | OBSOLETO | ✅ Eliminar |
| sacrament_acts | ❌ NO | OBSOLETO | ✅ Eliminar |
| sacrament_records | ❌ NO | OBSOLETO | ✅ Eliminar |

---

## 🔥 LO MÁS IMPORTANTE

### ❌ NO ELIMINAR `organizations`
**Es usada activamente por el microservicio de organizaciones.**

Si la eliminas:
```
vg-ms-organizationservice → ERROR
SELECT * FROM organizations → ERROR: relation "organizations" does not exist
```

### ❓ PREGUNTAR POR `events`, `event_reactions`, `audit_logs`

**Antes de eliminarlas, preguntar al equipo:**

```
1. ¿Alguien usa las tablas events, event_reactions, audit_logs?
2. ¿De qué sistema o microservicio vienen?
3. ¿Hay algún servicio externo que las necesite?
```

**Si nadie las usa** → Pueden eliminarse con el script de limpieza

**Si alguien las usa** → Pedir que identifiquen el microservicio correspondiente

---

## 📋 PRÓXIMOS PASOS

### 1. Inmediato
- ✅ Revisar documentos creados:
  - `ANALISIS_TABLAS_OBSOLETAS.md` - Análisis técnico completo
  - `LIMPIEZA_TABLAS_OBSOLETAS.sql` - Script de limpieza seguro
  - `RESUMEN_INVESTIGACION_TABLAS.md` - Este archivo

### 2. Consultar con el equipo
```
Pregunta clave:
¿Alguien necesita las tablas events, event_reactions, audit_logs?

Si nadie responde en 48 horas:
→ Asumir que son obsoletas
→ Ejecutar script de limpieza
```

### 3. Ejecutar limpieza (solo si el equipo confirma)
```bash
# 1. Hacer backup
pg_dump neondb > backup_antes_limpieza_20261018.sql

# 2. Ejecutar script
psql -d neondb -f LIMPIEZA_TABLAS_OBSOLETAS.sql

# 3. Verificar microservicios
# Ejecutar todos los backends y confirmar que funcionan
```

---

## 🔗 ARCHIVOS RELACIONADOS

1. **ANALISIS_TABLAS_OBSOLETAS.md**
   - Análisis técnico detallado
   - Evidencias de código Java
   - Estado de cada microservicio

2. **LIMPIEZA_TABLAS_OBSOLETAS.sql**
   - Script de limpieza seguro
   - NO elimina `organizations`
   - Incluye pasos de verificación

3. **VALIDACION_FRONTEND_BACKEND.md**
   - Validación de compatibilidad
   - Estado de cada módulo

---

## ✅ CONCLUSIÓN

**Pregunta**: ¿Por qué aparecieron tablas obsoletas?

**Respuesta**: 
- `organizations` → Tu compañero ejecutó el microservicio que la necesita
- `events`, `event_reactions`, `audit_logs` → Origen desconocido, preguntar al equipo

**Solución**:
1. NO eliminar `organizations` - es necesaria
2. Preguntar por las otras 3 tablas
3. Ejecutar script de limpieza solo después de confirmar con el equipo

---

**Dudas o preguntas:** Revisar `ANALISIS_TABLAS_OBSOLETAS.md` para detalles técnicos completos.
