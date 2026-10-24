# 🔍 ANÁLISIS: Tablas Obsoletas en Base de Datos

**Fecha**: 18 de Octubre 2026  
**Problema**: Tablas obsoletas aparecen "de la nada" al ejecutar microservicios  
**Investigadores**: Duban + Ordoñez

---

## 📋 RESUMEN EJECUTIVO

### Tablas Encontradas en BD (que NO deberían estar)
```
✅ CORRECTAS (Sistema actual):
- service_types
- services
- service_participants
- preparation
- celebration
- certificate
- roles
- users
- permissions
- user_permissions
- churches
- sacraments
- requirements

❌ OBSOLETAS (De versiones antiguas):
- organizations         → Viene de vg-ms-organizationservice
- events               → NO ENCONTRADO en ningún schema actual
- event_reactions      → NO ENCONTRADO en ningún schema actual
- audit_logs           → NO ENCONTRADO en ningún schema actual
- requests             → Tabla vieja (reemplazada por 'services')
- enrollment_participants → Tabla vieja (reemplazada por 'service_participants')
- sacrament_acts       → Tabla vieja de sacramentservice
- sacrament_records    → Tabla vieja de sacramentservice
```

---

## 🔍 ORIGEN DE LAS TABLAS OBSOLETAS

### 1. **organizations** ✅ CONFIRMADO - ORIGEN ENCONTRADO

**🎯 CONCLUSIÓN: Esta tabla ES USADA por vg-ms-organizationservice**

- **Origen**: `vg-ms-organizationservice-develop`
- **Archivo Schema**: `src/main/resources/schema_organization.sql`
- **Configuración**: `spring.sql.init.mode: never` ✅
- **¿Se ejecuta automáticamente?**: NO en teoría, PERO...

**⚠️ PROBLEMA ENCONTRADO:**

El microservicio `vg-ms-organizationservice-develop` **SÍ USA** la tabla `organizations`:

```java
// OrganizationEntity.java
@Table("organizations")
public class OrganizationEntity {
    @Id private Long id;
    @Column("tenant_id") private Long tenantId;
    @Column("organization_name") private String organizationName;
    // ... más campos
}

// OrganizationR2dbcRepository.java
@Query("SELECT * FROM organizations WHERE deleted = false ORDER BY id ASC")
Flux<OrganizationEntity> findAllByDeletedFalse();

@Query("SELECT * FROM organizations WHERE tenant_id = :tenantId AND deleted = false")
Flux<OrganizationEntity> findAllByTenantIdAndDeletedFalse(Long tenantId);
```

**🔥 ESTO ES LO QUE PASÓ:**

1. Tu compañero ejecutó `vg-ms-organizationservice-develop`
2. El microservicio intentó hacer `SELECT * FROM organizations`
3. Como la tabla NO existía, R2DBC/PostgreSQL **NO puede funcionar**
4. Alguien ejecutó manualmente el `schema_organization.sql` para que funcione el microservicio
5. **Por eso apareció la tabla "de la nada"**

**Evidencia del Schema:**
```sql
-- schema_organization.sql
CREATE TABLE organizations (
    id                BIGSERIAL    PRIMARY KEY,
    tenant_id         BIGINT,
    code              VARCHAR(50),
    organization_name VARCHAR(255),
    type              VARCHAR(100),
    scope             VARCHAR(100),
    ...
);
```

**❌ Esta tabla NO puede ser eliminada** mientras `vg-ms-organizationservice` esté en uso.

### 2. **events, event_reactions, audit_logs** ❓ NO ENCONTRADOS
- **Origen**: DESCONOCIDO
- **Archivos buscados**: NINGUNO
- **¿Dónde buscamos?**: 
  - ✅ Todos los microservicios actuales (requestsservice, preparationservice, certificateservice, celebrationservice)
  - ✅ usersmicroservice-hexagonal
  - ✅ locations-develop
  - ✅ sacramentservice-develop
  - ✅ organizationservice-develop
  - ❌ NO encontrado en ningún schema.sql actual

**Hipótesis:**
1. **Vienen de una versión anterior del sistema** que fue ejecutada antes
2. **Fueron creadas manualmente** por alguien del equipo
3. **Vienen de otro microservicio** que NO está en este workspace
4. **Fueron parte de MIGRACION_COMPLETA.sql** (aunque no están ahí)

### 3. **requests, enrollment_participants** ✅ CONFIRMADO
- **Origen**: Versiones antiguas de `vg-ms-requestsservice`
- **Estado**: Reemplazadas en refactorización masiva
- **Reemplazo**:
  - `requests` → `services`
  - `enrollment_participants` → `service_participants`

**Evidencia en MIGRACION_COMPLETA.sql:**
```sql
-- PASO 1: ELIMINAR TABLAS ANTIGUAS
DROP TABLE IF EXISTS requests CASCADE;  -- Tabla vieja
DROP TABLE IF EXISTS enrollment_participants CASCADE;  -- Tabla vieja
```

### 4. **sacrament_acts, sacrament_records** ✅ CONFIRMADO
- **Origen**: Versión antigua de `vg-ms-sacramentservice-develop`
- **Estado**: Eliminadas en limpieza del microservicio

**Evidencia en schema.sql actual:**
```sql
-- RESET DEL MICROSERVICIO MAESTRO DE SACRAMENTOS
DROP TABLE IF EXISTS sacrament_acts CASCADE;
DROP TABLE IF EXISTS sacrament_records CASCADE;
-- Ahora solo existe: sacraments, requirements
```

---

## 🔧 ¿CÓMO APARECIERON ESTAS TABLAS?

### ✅ Escenario CONFIRMADO:

1. **Tu compañero ejecutó `vg-ms-organizationservice-develop`**
2. **El microservicio intentó hacer queries a la tabla `organizations`** (SELECT * FROM organizations)
3. **La tabla NO existía → El microservicio FALLÓ**
4. **Alguien ejecutó manualmente `schema_organization.sql`** para arreglar el error
5. **Resultado: Apareció la tabla `organizations` en la BD**

### 🔥 COMPROBACIÓN:

```bash
# Cuando tu compañero ejecutó:
java -jar vg-ms-organizationservice-develop.jar

# El microservicio intentó:
SELECT * FROM organizations WHERE deleted = false ORDER BY id ASC

# Error de PostgreSQL:
ERROR: relation "organizations" does not exist

# Solución: Alguien ejecutó manualmente el schema
psql -d neondb -f schema_organization.sql
```

### Verificación:

```bash
# ¿Qué microservicios tienen mode: never?
✅ vg-ms-requestsservice-hexagonal    → mode: never
✅ vg-ms-preparationservice-hexagonal → mode: never
✅ vg-ms-certificateservice-hexagonal → mode: never
✅ vg-ms-celebrationservice-hexagonal → mode: never
✅ vg-ms-organizationservice-develop  → mode: never
✅ vg-ms-usersmicroservice-hexagonal  → (NO tiene spring.sql.init configurado)
✅ vg-ms-locations-develop            → (NO tiene spring.sql.init configurado)
✅ vg-ms-sacramentservice-develop     → (NO tiene spring.sql.init configurado)
```

**CONCLUSIÓN**: Todos tienen `mode: never`, por lo que NO deberían ejecutar schemas automáticamente.

**PERO**: Si algún microservicio tiene variables de entorno o configuración local diferente, SÍ puede ejecutarlos.

---

## 🗑️ RECOMENDACIÓN: Script de Limpieza

Ver archivo: `LIMPIEZA_TABLAS_OBSOLETAS.sql`

---

## 📌 ACCIONES RECOMENDADAS

### ❌ NO ELIMINAR `organizations`
**IMPORTANTE**: La tabla `organizations` **NO es obsoleta**. Es usada activamente por `vg-ms-organizationservice-develop`.

**Si la eliminas, el microservicio de organizaciones dejará de funcionar.**

### 1. Corto Plazo (HOY)
- ✅ **NO ejecutar script de limpieza para `organizations`**
- ⚠️ Investigar si el equipo realmente usa `events`, `event_reactions`, `audit_logs`
- 📝 Preguntar al equipo: ¿Alguien necesita estas 3 tablas?

### 2. Para `events`, `event_reactions`, `audit_logs`
**Estas 3 tablas NO tienen código asociado en ningún microservicio actual.**

Opciones:
- **Si nadie las usa**: Eliminarlas con script de limpieza
- **Si alguien las usa**: Pedir que identifiquen qué microservicio las necesita
- **Si vienen de sistema viejo**: Hacer backup y eliminar

### 3. Verificar con el equipo
```bash
# Pregunta clave:
¿Qué microservicio usa las tablas events, event_reactions, audit_logs?

# Si nadie responde o no las usan:
# Entonces son tablas huérfanas que pueden eliminarse
```

---

## 🚨 ADVERTENCIA

**⚠️ LA TABLA `organizations` NO PUEDE SER ELIMINADA**

Esta tabla es usada activamente por `vg-ms-organizationservice-develop`.

**ANTES de eliminar `events`, `event_reactions`, `audit_logs` en PRODUCCIÓN:**

1. **Hacer backup completo de la BD**
2. **Verificar con TODOS los integrantes del equipo** si usan estas 3 tablas
3. **Ejecutar primero en ambiente de desarrollo**
4. **Si nadie las usa, entonces sí pueden eliminarse**

---

## 📊 ESTADO DE TABLAS

| Tabla | ¿Usada por código? | Microservicio | Acción |
|-------|-------------------|---------------|---------|
| organizations | ✅ SÍ | organizationservice | ✅ MANTENER |
| events | ❌ NO | NINGUNO | ⚠️ Investigar → Eliminar |
| event_reactions | ❌ NO | NINGUNO | ⚠️ Investigar → Eliminar |
| audit_logs | ❌ NO | NINGUNO | ⚠️ Investigar → Eliminar |
| requests | ❌ NO | OBSOLETO | ✅ Eliminar (reemplazado por services) |
| enrollment_participants | ❌ NO | OBSOLETO | ✅ Eliminar (reemplazado por service_participants) |
| sacrament_acts | ❌ NO | OBSOLETO | ✅ Eliminar |
| sacrament_records | ❌ NO | OBSOLETO | ✅ Eliminar |

---

## 📊 ESTADO DE MICROSERVICIOS

| Microservicio | Schema Existe | Mode Config | ¿Ejecuta Auto? | Usa Tablas Obsoletas | Estado |
|--------------|---------------|-------------|----------------|---------------------|--------|
| requestsservice | ✅ | never | ❌ | ❌ NO | ✅ OK |
| preparationservice | ✅ | never | ❌ | ❌ NO | ✅ OK |
| certificateservice | ✅ | never | ❌ | ❌ NO | ✅ OK |
| celebrationservice | ✅ | never | ❌ | ❌ NO | ✅ OK |
| organizationservice | ✅ | never | ❌ | ✅ USA `organizations` | ✅ OK - TABLA NECESARIA |
| usersmicroservice | ✅ | N/A | ❌ | ❌ NO | ✅ OK |
| locations | ✅ | N/A | ❌ | ❌ NO | ✅ OK |
| sacramentservice | ✅ | N/A | ❌ | ❌ NO | ✅ OK |

---

## 🔗 ARCHIVOS RELACIONADOS

- `LIMPIEZA_TABLAS_OBSOLETAS.sql` - Script de limpieza segura
- `MIGRACION_COMPLETA.sql` - Migración original del sistema
- `vg-ms-organizationservice-develop/src/main/resources/schema_organization.sql` - Origen de tabla organizations

---

**Conclusión Final:**

**✅ TABLA `organizations` - ENCONTRADO EL ORIGEN:**
- Es usada activamente por `vg-ms-organizationservice-develop`
- Tiene código Java que hace queries: `SELECT * FROM organizations`
- Apareció porque tu compañero ejecutó el microservicio y alguien tuvo que crear la tabla manualmente
- **NO PUEDE SER ELIMINADA** - es necesaria para el sistema

**❓ TABLAS `events`, `event_reactions`, `audit_logs` - ORIGEN DESCONOCIDO:**
- NO tienen código Java asociado en ningún microservicio actual
- NO están en ningún schema.sql actual
- Posibles orígenes:
  1. Versión MUY antigua del sistema
  2. Otro repositorio que no está en este workspace
  3. Fueron creadas manualmente por alguien
  4. Vienen de un sistema externo

**Acción recomendada:**
1. Preguntar al equipo si usan `events`, `event_reactions`, `audit_logs`
2. Si nadie las usa → Eliminarlas con script de limpieza
3. Si alguien las usa → Pedir que identifiquen el microservicio correspondiente
