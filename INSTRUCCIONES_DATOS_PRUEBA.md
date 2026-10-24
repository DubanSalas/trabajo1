# 📋 Instrucciones para Cargar Datos de Prueba

## 🎯 Objetivo
Cargar datos de prueba coherentes en todos los microservicios para verificar que el frontend funciona correctamente con todos los campos de la base de datos.

---

## 📂 Archivos Disponibles

### 1. **Archivo Maestro (Recomendado)**
```
TEST_DATA_COMPLETO.sql
```
- Contiene TODOS los datos de prueba en un solo archivo
- Orden correcto: services → preparation → celebration → certificate
- Listo para ejecutar en NeonDB (PostgreSQL)

### 2. **Archivos Individuales por Microservicio**
```
vg-ms-servicesservice-hexagonal/src/main/resources/sql/data.sql
vg-ms-preparationservice-hexagonal/src/main/resources/sql/data.sql
vg-ms-celebrationservice-hexagonal/src/main/resources/sql/data.sql
vg-ms-certificateservice-hexagonal/src/main/resources/sql/data.sql
```
- Útiles si solo necesitas actualizar un microservicio específico

---

## ⚠️ Prerrequisitos

Antes de ejecutar los scripts, asegúrate de que existan:

### 1. **Organization (Tenant)**
```sql
-- Verificar en vg-ms-organizationservice
SELECT id, name FROM organizations WHERE id = 1;

-- Si no existe, crear:
INSERT INTO organizations (id, name, active) 
VALUES (1, 'Parroquia San José - Pruebas', TRUE);
```

### 2. **Usuarios (People/Users)**
```sql
-- Verificar en vg-ms-usersmicroservice
SELECT id, name FROM users WHERE id IN (1, 2, 3, 4, 5, 6, 10);

-- Los scripts requieren estos user_id:
-- 1-6: Participantes de sacramentos (padres, padrinos, novios, etc.)
-- 10: Usuario que firmó el certificado (párroco)
```

### 3. **Iglesias (Churches) con UUIDs**
```sql
-- Verificar en vg-ms-churches
SELECT id, name FROM churches WHERE active = TRUE;

-- ⚠️ IMPORTANTE: Reemplazar los UUIDs de ejemplo en los scripts
-- Los scripts usan UUIDs de ejemplo que debes reemplazar:
-- '550e8400-e29b-41d4-a716-446655440001'
-- '550e8400-e29b-41d4-a716-446655440002'
```

### 4. **Schemas Creados**
Ejecutar `schema.sql` de cada microservicio antes de cargar datos:
```sql
-- Orden de ejecución de schemas:
1. vg-ms-servicesservice-hexagonal/src/main/resources/sql/schema.sql
2. vg-ms-preparationservice-hexagonal/src/main/resources/sql/schema.sql
3. vg-ms-celebrationservice-hexagonal/src/main/resources/sql/schema.sql
4. vg-ms-certificateservice-hexagonal/src/main/resources/sql/schema.sql
```

---

## 🚀 Cómo Cargar los Datos

### **Opción A: Archivo Maestro (Recomendado)**

1. **Ajustar UUIDs de iglesias:**
   ```sql
   -- Obtener UUIDs reales de tu BD
   SELECT id, name FROM churches WHERE active = TRUE;
   ```

2. **Editar `TEST_DATA_COMPLETO.sql`:**
   - Buscar todas las ocurrencias de `'550e8400-e29b-41d4-a716-446655440001'`
   - Reemplazar con UUIDs reales de tus iglesias

3. **Ejecutar en NeonDB:**
   ```bash
   # Desde psql
   \i TEST_DATA_COMPLETO.sql

   # O copiar y pegar todo el contenido en el Query Editor de Neon
   ```

### **Opción B: Archivos Individuales**

Si prefieres cargar por microservicio:

```bash
# 1. Services (obligatorio primero)
\i vg-ms-servicesservice-hexagonal/src/main/resources/sql/data.sql

# 2. Preparation (depende de services)
\i vg-ms-preparationservice-hexagonal/src/main/resources/sql/data.sql

# 3. Celebration (depende de services)
\i vg-ms-celebrationservice-hexagonal/src/main/resources/sql/data.sql

# 4. Certificate (depende de services y celebration)
\i vg-ms-certificateservice-hexagonal/src/main/resources/sql/data.sql
```

---

## 🧪 Datos de Prueba Incluidos

### **Service 1: Bautismo (PENDING)**
- **Estado:** Pendiente de aprobación
- **Participantes:** Niño, padre, madre, padrino, madrina
- **Preparación:** 2 sesiones completadas
- **Celebración:** Programada para 2024-11-15

### **Service 2: Confirmación (APPROVED)**
- **Estado:** Aprobado, listo para celebrar
- **Participantes:** Confirmando, padre, madre, padrino
- **Preparación:** 3 sesiones (2 completadas, 1 en progreso)
- **Celebración:** Programada para 2024-12-01
- **Certificado:** Generado pero pendiente de firma

### **Service 3: Matrimonio (PENDING)**
- **Estado:** Pendiente de aprobación
- **Participantes:** Novio, novia, padres de ambos, padrinos
- **Preparación:** 3 sesiones (2 completadas, 1 pendiente)
- **Celebración:** Programada para 2024-11-30
- **Certificado:** Generado pero pendiente de firma

### **Service 4: Misa Especial (APPROVED)**
- **Estado:** Aprobada
- **church_id:** UUID asignado (misas especiales sí usan church_id)
- **Participantes:** Solicitante
- **Celebración:** Programada para 2024-11-02
- **Documento adjunto:** URL de ejemplo

### **Service 5: Bautismo (COMPLETED)**
- **Estado:** Completado
- **Participantes:** Niño, padre, madre, padrino
- **Preparación:** Completada
- **Celebración:** Realizada el 2024-10-05
- **Certificado:** Emitido y FIRMADO por el párroco ✅

### **Service 6: Confirmación (REJECTED)**
- **Estado:** Rechazado
- **Participantes:** Confirmando
- **Motivo rechazo:** "Documentación incompleta: Falta certificado de bautismo y carta del párroco"

---

## ✅ Verificación Post-Carga

Ejecutar estas queries para verificar que todo se cargó correctamente:

```sql
-- 1. Ver todos los servicios
SELECT 
    s.id, 
    st.code AS tipo, 
    s.description, 
    s.status, 
    s.scheduled_date
FROM services s
JOIN service_types st ON s.service_type_id = st.id
ORDER BY s.id;

-- 2. Ver participantes por servicio
SELECT 
    sp.service_id,
    sp.user_id,
    sp.role,
    COUNT(*) OVER (PARTITION BY sp.service_id) AS total_participantes
FROM service_participants sp
ORDER BY sp.service_id, sp.id;

-- 3. Ver preparaciones por servicio
SELECT 
    p.service_id,
    p.type,
    p.session_date,
    p.status,
    p.attendance_status
FROM preparation p
ORDER BY p.service_id, p.session_date;

-- 4. Ver celebraciones programadas
SELECT 
    c.id,
    c.service_id,
    c.church_id,
    c.event_date,
    c.event_time,
    c.status
FROM celebration c
ORDER BY c.service_id;

-- 5. Ver certificados emitidos
SELECT 
    cert.id,
    cert.service_id,
    cert.certificate_type,
    cert.certificate_number,
    cert.signed,
    cert.main_person_name
FROM certificate cert
ORDER BY cert.service_id;

-- 6. Conteo de registros por tabla
SELECT 'services' AS tabla, COUNT(*) AS registros FROM services
UNION ALL
SELECT 'service_participants', COUNT(*) FROM service_participants
UNION ALL
SELECT 'preparation', COUNT(*) FROM preparation
UNION ALL
SELECT 'celebration', COUNT(*) FROM celebration
UNION ALL
SELECT 'certificate', COUNT(*) FROM certificate;
```

**Resultados esperados:**
```
tabla                   | registros
-----------------------|----------
services               | 6
service_participants   | 26
preparation            | 11
celebration            | 5
certificate            | 3
```

---

## 🧹 Limpiar Datos de Prueba

Si necesitas eliminar los datos de prueba:

```sql
-- ADVERTENCIA: Esto eliminará TODOS los datos de prueba

-- Orden inverso para respetar FKs
DELETE FROM certificate WHERE tenant_id = 1;
DELETE FROM celebration WHERE tenant_id = 1;
DELETE FROM preparation WHERE tenant_id = '1';
DELETE FROM service_participants WHERE tenant_id = 1;
DELETE FROM services WHERE tenant_id = 1;

-- Verificar limpieza
SELECT 'services' AS tabla, COUNT(*) AS registros FROM services WHERE tenant_id = 1
UNION ALL
SELECT 'service_participants', COUNT(*) FROM service_participants WHERE tenant_id = 1
UNION ALL
SELECT 'preparation', COUNT(*) FROM preparation WHERE tenant_id = '1'
UNION ALL
SELECT 'celebration', COUNT(*) FROM celebration WHERE tenant_id = 1
UNION ALL
SELECT 'certificate', COUNT(*) FROM certificate WHERE tenant_id = 1;
```

---

## 🎨 Probar en el Frontend

Una vez cargados los datos:

1. **Iniciar el frontend:**
   ```bash
   cd vg-web-fideinexus-develop
   npm start
   ```

2. **Verificar en la UI:**
   - ✅ Listado de solicitudes muestra los 6 registros
   - ✅ Detalle de solicitud muestra todos los participantes
   - ✅ Preparaciones aparecen con sus estados
   - ✅ Celebraciones muestran fecha/hora e iglesia
   - ✅ Certificados firmados vs pendientes
   - ✅ Solicitudes rechazadas muestran motivo
   - ✅ Misas especiales muestran iglesia asignada

3. **Flujos específicos a probar:**
   - 📝 Ver Service 1 (PENDING) → Aprobar → Crear celebración
   - 📅 Ver Service 2 (APPROVED) → Agendar en calendario
   - 📜 Ver Service 5 (COMPLETED) → Descargar certificado firmado
   - ❌ Ver Service 6 (REJECTED) → Ver motivo de rechazo
   - 💒 Ver Service 4 (MASS) → Verificar que muestra iglesia

---

## 📌 Notas Importantes

1. **church_id en services:**
   - `NULL` para Bautismo, Confirmación, Matrimonio (el lugar se define en celebration)
   - `UUID` para Misas Especiales (el lugar se define al crear la solicitud)

2. **userId virtual:**
   - El backend lo calcula desde `service_participants` con rol `TITULAR`
   - El frontend lo espera en la respuesta de GET /services

3. **Estados válidos:**
   - Services: `PENDING`, `APPROVED`, `REJECTED`, `COMPLETED`, `CANCELLED`
   - Preparation: `PENDING`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`
   - Celebration: `SCHEDULED`, `REALIZED`, `CANCELLED`

4. **Firma de certificados:**
   - `signed = FALSE`: Pendiente de autorización del párroco
   - `signed = TRUE`: Autorizado para emisión oficial

---

## 🆘 Troubleshooting

### Error: "foreign key violation on service_type_id"
**Solución:** Ejecutar primero la parte de `service_types` en data.sql

### Error: "foreign key violation on church_id"
**Solución:** Reemplazar los UUIDs de ejemplo con UUIDs reales de tu tabla `churches`

### Error: "foreign key violation on user_id"
**Solución:** Crear los usuarios 1-6 y 10 en `vg-ms-usersmicroservice`

### Error: "foreign key violation on service_id"
**Solución:** Ejecutar los scripts en orden: services → preparation → celebration → certificate

### Frontend no muestra datos
**Solución:** 
1. Verificar que `tenant_id = 1` existe
2. Verificar que el usuario logueado tiene acceso al tenant
3. Verificar rutas de API en `environment.ts`

---

## 📚 Referencias

- [Schema services](vg-ms-servicesservice-hexagonal/src/main/resources/sql/schema.sql)
- [Schema preparation](vg-ms-preparationservice-hexagonal/src/main/resources/sql/schema.sql)
- [Schema celebration](vg-ms-celebrationservice-hexagonal/src/main/resources/sql/schema.sql)
- [Schema certificate](vg-ms-certificateservice-hexagonal/src/main/resources/sql/schema.sql)
- [Interface Service](vg-web-fideinexus-develop/src/app/core/interfaces/solicitudes.interface.ts)

---

**Última actualización:** 19 octubre 2024  
**Versión:** 1.0  
**Estado:** Listo para producción de pruebas ✅
