# 📋 INSTRUCCIONES PARA RECREAR LA BASE DE DATOS

## ✅ Objetivo
Eliminar y recrear todas las bases de datos con las correcciones aplicadas:
- ✅ Tipos de datos consistentes (`BIGINT` para IDs y `tenant_id`)
- ✅ Campos redundantes eliminados de `certificate`
- ✅ Comentarios SQL explicativos
- ✅ Datos de prueba del tenant 9

---

## 🎯 Los 4 Tipos de Solicitud

Estos son los tipos que aparecen en el frontend:

| Código | Nombre | Descripción |
|--------|--------|-------------|
| **BAPTISM** | Bautismo | Sacramento del Bautismo |
| **CONFIRMATION** | Confirmación | Sacramento de la Confirmación |
| **MARRIAGE** | Matrimonio | Sacramento del Matrimonio |
| **MASS** | Misa Especial | Solicitud de Misa Especial |

✅ **Confirmado**: Estos 4 tipos están correctamente implementados en el `data.sql`

---

## 📦 Bases de Datos a Recrear

1. **servicesdb** - Solicitudes, tipos de servicio, participantes
2. **preparationdb** - Sesiones de preparación
3. **celebrationdb** - Celebraciones programadas
4. **certificatedb** - Actas sacramentales

---

## 🚀 PASO 1: Detener los Microservicios

**Antes de ejecutar el script**, detén todos los microservicios Java:

```bash
# En Windows (cmd o PowerShell)
# Presiona Ctrl+C en cada terminal donde esté corriendo un microservicio
```

O puedes matar los procesos manualmente:

```bash
# Ver procesos Java
tasklist | findstr java

# Matar proceso específico (reemplaza PID con el número)
taskkill /PID <número> /F
```

---

## 🗄️ PASO 2: Ejecutar el Script SQL

### Opción A: Desde pgAdmin

1. Abre **pgAdmin**
2. Conéctate a tu servidor PostgreSQL
3. Click derecho en **PostgreSQL** → **Query Tool**
4. Abre el archivo `RECREAR_BD_COMPLETA.sql`
5. Click en el botón **▶ Execute/Refresh** (F5)

### Opción B: Desde línea de comandos

```bash
# Ubicarte en la carpeta del proyecto
cd d:\Desktop\vg-ms-arquitect-main

# Ejecutar el script (reemplaza 'postgres' con tu usuario)
psql -U postgres -f RECREAR_BD_COMPLETA.sql
```

Si te pide contraseña, ingresa tu password de PostgreSQL.

---

## ⏱️ PASO 3: Esperar Confirmación

El script mostrará mensajes como:

```
======================================================
PASO 1: ELIMINAR BASES DE DATOS EXISTENTES
======================================================
Bases de datos eliminadas correctamente

======================================================
PASO 2: CREAR BASES DE DATOS LIMPIAS
======================================================
Bases de datos creadas correctamente

======================================================
PASO 3: CREAR SCHEMAS Y TABLAS
======================================================
Creando schema de servicesdb...
Schema de servicesdb creado correctamente
...

======================================================
PASO 4: INSERTAR DATOS DE PRUEBA - TENANT 9
======================================================
Insertando datos de prueba en servicesdb...
Datos de prueba insertados en servicesdb
...

======================================================
RESUMEN
======================================================
Bases de datos recreadas:
  ✓ servicesdb      - 4 tipos de servicio, 3 servicios, 13 participantes
  ✓ preparationdb   - 8 sesiones de preparación
  ✓ celebrationdb   - 3 celebraciones programadas
  ✓ certificatedb   - 3 actas (2 sin firmar, 1 firmada)

Tenant de prueba: 9
Usuario feligrés: 32
======================================================
```

---

## 🔄 PASO 4: Reiniciar los Microservicios

Después de recrear las bases de datos, inicia los microservicios **en este orden**:

### 1. vg-ms-servicesservice-hexagonal
```bash
cd vg-ms-servicesservice-hexagonal
mvn spring-boot:run
```

### 2. vg-ms-preparationservice-hexagonal
```bash
cd vg-ms-preparationservice-hexagonal
mvn spring-boot:run
```

### 3. vg-ms-celebrationservice-hexagonal
```bash
cd vg-ms-celebrationservice-hexagonal
mvn spring-boot:run
```

### 4. vg-ms-certificateservice-hexagonal
```bash
cd vg-ms-certificateservice-hexagonal
mvn spring-boot:run
```

---

## ✅ PASO 5: Verificar que Todo Funciona

### Opción A: Desde el Frontend (Puerto 4200)

1. Abre el navegador en `http://localhost:4200`
2. Inicia sesión con tu usuario
3. Ve a **Solicitudes**
4. Deberías ver los 4 tipos de solicitud:
   - 🪔 Bautismo
   - 🛡️ Confirmación
   - 💒 Matrimonio
   - 📿 Misa Especial
5. Crea una nueva solicitud de prueba

### Opción B: Desde Postman o cURL

**Verificar tipos de servicio:**
```bash
curl http://localhost:8001/api/v1/service-types
```

Respuesta esperada:
```json
[
  {"id": 1, "code": "BAPTISM", "name": "Bautismo", "active": true},
  {"id": 2, "code": "CONFIRMATION", "name": "Confirmación", "active": true},
  {"id": 3, "code": "MARRIAGE", "name": "Matrimonio", "active": true},
  {"id": 4, "code": "MASS", "name": "Misa Especial", "active": true}
]
```

**Verificar servicios del tenant 9:**
```bash
curl http://localhost:8001/api/v1/services?tenantId=9
```

Respuesta esperada:
```json
[
  {"id": 1, "tenantId": 9, "serviceTypeCode": "BAPTISM", "status": "APPROVED", ...},
  {"id": 2, "tenantId": 9, "serviceTypeCode": "CONFIRMATION", "status": "APPROVED", ...},
  {"id": 3, "tenantId": 9, "serviceTypeCode": "MARRIAGE", "status": "APPROVED", ...}
]
```

---

## 📊 Datos de Prueba Incluidos

### Tenant 9:
- **3 servicios aprobados:**
  - Bautismo de Juan Pérez (ID: 1)
  - Confirmación de María López (ID: 2)
  - Matrimonio de Carlos y Ana (ID: 3)

- **13 participantes registrados:**
  - Bautizado, padre, madre, padrino, madrina
  - Confirmado, padre, madre, padrino/madrina
  - Novio, novia, padrino, madrina

- **8 sesiones de preparación:**
  - 2 para Bautismo (titular + padrinos)
  - 3 para Confirmación (3 sesiones)
  - 3 para Matrimonio (3 sesiones)

- **3 celebraciones programadas:**
  - Bautismo - 30 días desde hoy a las 10:00
  - Confirmación - 45 días desde hoy a las 11:00
  - Matrimonio - 60 días desde hoy a las 16:00

- **3 actas generadas:**
  - Bautismo - Sin firmar (pendiente)
  - Confirmación - Sin firmar (pendiente)
  - Matrimonio - **Firmada** (M-2026-001, Libro 10, Folio 15)

---

## 🚨 Problemas Comunes

### Error: "database is being accessed by other users"
**Solución**: Detén todos los microservicios y vuelve a ejecutar el script.

### Error: "permission denied"
**Solución**: Ejecuta el script como superusuario (`postgres`).

### Error: "relation already exists"
**Solución**: El script ya incluye `DROP DATABASE IF EXISTS`. Si persiste, elimina manualmente desde pgAdmin.

### Los microservicios no inician
**Solución**: Verifica que PostgreSQL esté corriendo y que las credenciales en `application.yml` sean correctas.

---

## 📝 Notas Importantes

### ⚠️ Sobre Celebraciones y Certificados

**¿Por qué no había INSERT en celebration y certificate?**

Es **intencional** porque en el flujo real del sistema:

1. **Celebraciones** se crean cuando:
   - ✅ Todas las preparaciones están completadas (`status = COMPLETED`)
   - ✅ El párroco o secretario programa la fecha desde el frontend
   - ✅ El pago está confirmado

2. **Certificados** se generan automáticamente cuando:
   - ✅ La celebración se marca como `REALIZED`
   - ✅ El sistema crea el acta con `signed = false` (sin firmar)
   - ✅ El párroco debe firmar manualmente agregando: `certificate_number`, `book`, `folio`

**Para pruebas**, el script incluye ejemplos de:
- ✅ 3 celebraciones programadas (SCHEDULED)
- ✅ 2 actas sin firmar (para probar búsqueda y firma)
- ✅ 1 acta firmada (para probar visualización de actas completas)

---

### 🔄 Flujo Completo del Sistema

```
SOLICITUD → INSCRIPCIÓN → PREPARACIÓN → CELEBRACIÓN → ACTA
(service)   (participants)  (preparation)  (celebration)  (certificate)

1. PENDING    →  Agregar      →  Programar    →  Programar   →  Generar
2. APPROVED      participantes    sesiones        fecha          acta
3. INSCRITO                       (catequesis)    y hora         (sin firma)
4. EN PREPARACIÓN                 Asistir         Realizar       Firmar
5. PREPARADO                      Completar       celebración    (párroco)
6. CELEBRADO                                      REALIZED       FIRMADA ✓
7. ACTA FIRMADA
```

---

### 📝 Notas Adicionales

1. **BACKUP**: Este script elimina completamente las bases de datos. Si tienes datos importantes, haz un backup antes.

2. **TENANT_ID**: Los datos de prueba usan `tenant_id = 9`. Si necesitas otro tenant, modifica el script.

3. **USER_ID**: Los participantes usan `user_id = 32-38`. Asegúrate de que estos usuarios existan en `vg-ms-users`.

4. **CHURCH_ID**: Se usa `church-uuid-001`. Asegúrate de que exista en `vg-ms-churches` o cámbialo.

---

## ✅ Checklist Final

- [ ] Detener todos los microservicios
- [ ] Ejecutar `RECREAR_BD_COMPLETA.sql`
- [ ] Verificar que el script completó sin errores
- [ ] Reiniciar microservicios en orden
- [ ] Verificar que el frontend muestra los 4 tipos de solicitud
- [ ] Crear una solicitud de prueba
- [ ] Verificar que todo el flujo funciona

---

## 🎉 Listo

Si todos los pasos se completaron exitosamente:
- ✅ Bases de datos limpias y actualizadas
- ✅ Tipos de datos consistentes
- ✅ Campos redundantes eliminados
- ✅ Datos de prueba listos para usar
- ✅ Sistema funcionando correctamente

**¡Todo el sistema está sincronizado y listo para producción!** 🚀
