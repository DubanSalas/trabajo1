-- ═══════════════════════════════════════════════════════════════════════════
-- SCRIPT DE LIMPIEZA DE TABLAS OBSOLETAS
-- Sistema: FideiNexus - Gestión Parroquial
-- Fecha: 18 de Octubre 2026
-- ═══════════════════════════════════════════════════════════════════════════
-- ⚠️ ADVERTENCIA IMPORTANTE:
-- 
-- Este script ELIMINA tablas de la base de datos.
-- Ejecutar SOLO después de:
-- 1. Hacer BACKUP completo de la BD
-- 2. Verificar con TODO el equipo que NO usan estas tablas
-- 3. Ejecutar primero en ambiente de DESARROLLO
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- PASO 1: VERIFICAR TABLAS EXISTENTES
-- ═══════════════════════════════════════════════════════════════════════════

-- Ver qué tablas existen actualmente
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ═══════════════════════════════════════════════════════════════════════════
-- PASO 2: TABLAS QUE SE VAN A ELIMINAR
-- ═══════════════════════════════════════════════════════════════════════════

/*
❌ TABLAS A ELIMINAR (No tienen código asociado):
   - events
   - event_reactions
   - audit_logs
   - requests (obsoleta, reemplazada por 'services')
   - enrollment_participants (obsoleta, reemplazada por 'service_participants')
   - sacrament_acts (obsoleta de sacramentservice)
   - sacrament_records (obsoleta de sacramentservice)

✅ TABLAS QUE SE MANTIENEN (Son usadas):
   - organizations → Usada por vg-ms-organizationservice
   - service_types, services, service_participants → Usadas por requestsservice
   - preparation → Usada por preparationservice
   - celebration → Usada por celebrationservice
   - certificate → Usada por certificateservice
   - roles, users, permissions, user_permissions → Usadas por usersmicroservice
   - churches → Usada por locations
   - sacraments, requirements → Usadas por sacramentservice
*/

-- ═══════════════════════════════════════════════════════════════════════════
-- PASO 3: CONTAR REGISTROS (Para confirmar si tienen datos)
-- ═══════════════════════════════════════════════════════════════════════════

DO $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Verificar events
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'events') THEN
        SELECT COUNT(*) INTO v_count FROM events;
        RAISE NOTICE 'Tabla events tiene % registros', v_count;
    ELSE
        RAISE NOTICE 'Tabla events NO existe';
    END IF;

    -- Verificar event_reactions
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'event_reactions') THEN
        SELECT COUNT(*) INTO v_count FROM event_reactions;
        RAISE NOTICE 'Tabla event_reactions tiene % registros', v_count;
    ELSE
        RAISE NOTICE 'Tabla event_reactions NO existe';
    END IF;

    -- Verificar audit_logs
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_logs') THEN
        SELECT COUNT(*) INTO v_count FROM audit_logs;
        RAISE NOTICE 'Tabla audit_logs tiene % registros', v_count;
    ELSE
        RAISE NOTICE 'Tabla audit_logs NO existe';
    END IF;

    -- Verificar requests
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'requests') THEN
        SELECT COUNT(*) INTO v_count FROM requests;
        RAISE NOTICE 'Tabla requests tiene % registros', v_count;
    ELSE
        RAISE NOTICE 'Tabla requests NO existe';
    END IF;

    -- Verificar enrollment_participants
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'enrollment_participants') THEN
        SELECT COUNT(*) INTO v_count FROM enrollment_participants;
        RAISE NOTICE 'Tabla enrollment_participants tiene % registros', v_count;
    ELSE
        RAISE NOTICE 'Tabla enrollment_participants NO existe';
    END IF;

    -- Verificar sacrament_acts
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sacrament_acts') THEN
        SELECT COUNT(*) INTO v_count FROM sacrament_acts;
        RAISE NOTICE 'Tabla sacrament_acts tiene % registros', v_count;
    ELSE
        RAISE NOTICE 'Tabla sacrament_acts NO existe';
    END IF;

    -- Verificar sacrament_records
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sacrament_records') THEN
        SELECT COUNT(*) INTO v_count FROM sacrament_records;
        RAISE NOTICE 'Tabla sacrament_records tiene % registros', v_count;
    ELSE
        RAISE NOTICE 'Tabla sacrament_records NO existe';
    END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- PASO 4: BACKUP DE DATOS (Solo si tienen registros)
-- ═══════════════════════════════════════════════════════════════════════════

-- Si alguna tabla tiene datos, crear una tabla de respaldo
-- Descomenta y ejecuta según necesites:

/*
-- Backup de events (si tiene datos)
CREATE TABLE IF NOT EXISTS backup_events_20261018 AS 
SELECT * FROM events;

-- Backup de event_reactions (si tiene datos)
CREATE TABLE IF NOT EXISTS backup_event_reactions_20261018 AS 
SELECT * FROM event_reactions;

-- Backup de audit_logs (si tiene datos)
CREATE TABLE IF NOT EXISTS backup_audit_logs_20261018 AS 
SELECT * FROM audit_logs;

-- Backup de requests (si tiene datos)
CREATE TABLE IF NOT EXISTS backup_requests_20261018 AS 
SELECT * FROM requests;

-- Backup de enrollment_participants (si tiene datos)
CREATE TABLE IF NOT EXISTS backup_enrollment_participants_20261018 AS 
SELECT * FROM enrollment_participants;
*/

-- ═══════════════════════════════════════════════════════════════════════════
-- PASO 5: ELIMINAR TABLAS OBSOLETAS (En orden correcto por dependencias)
-- ═══════════════════════════════════════════════════════════════════════════

-- ⚠️ IMPORTANTE: Comentar esta sección hasta confirmar con el equipo

/*
-- Eliminar event_reactions (depende de events)
DROP TABLE IF EXISTS event_reactions CASCADE;

-- Eliminar events
DROP TABLE IF EXISTS events CASCADE;

-- Eliminar audit_logs
DROP TABLE IF EXISTS audit_logs CASCADE;

-- Eliminar enrollment_participants (puede tener FK a requests)
DROP TABLE IF EXISTS enrollment_participants CASCADE;

-- Eliminar requests
DROP TABLE IF EXISTS requests CASCADE;

-- Eliminar sacrament_acts
DROP TABLE IF EXISTS sacrament_acts CASCADE;

-- Eliminar sacrament_records
DROP TABLE IF EXISTS sacrament_records CASCADE;
*/

-- ═══════════════════════════════════════════════════════════════════════════
-- PASO 6: VERIFICAR RESULTADO
-- ═══════════════════════════════════════════════════════════════════════════

-- Ver qué tablas quedaron después de la limpieza
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ═══════════════════════════════════════════════════════════════════════════
-- PASO 7: VERIFICAR QUE MICROSERVICIOS FUNCIONAN
-- ═══════════════════════════════════════════════════════════════════════════

/*
Después de ejecutar este script, verificar que funcionan:

✅ vg-ms-requestsservice-hexagonal
✅ vg-ms-preparationservice-hexagonal
✅ vg-ms-certificateservice-hexagonal
✅ vg-ms-celebrationservice-hexagonal
✅ vg-ms-organizationservice-develop
✅ vg-ms-usersmicroservice-hexagonal
✅ vg-ms-locations-develop
✅ vg-ms-sacramentservice-develop

Si alguno falla, restaurar el backup inmediatamente.
*/

-- ═══════════════════════════════════════════════════════════════════════════
-- NOTAS FINALES
-- ═══════════════════════════════════════════════════════════════════════════

/*
❌ NO ELIMINAR:
   - organizations → Usada activamente por organizationservice

❓ INVESTIGAR ANTES DE ELIMINAR:
   - events, event_reactions, audit_logs → Origen desconocido
   
   Preguntar al equipo:
   1. ¿Alguien usa estas 3 tablas?
   2. ¿De qué sistema vienen?
   3. ¿Hay algún microservicio externo que las necesite?

✅ SEGURO ELIMINAR:
   - requests → Reemplazada por 'services'
   - enrollment_participants → Reemplazada por 'service_participants'
   - sacrament_acts, sacrament_records → Obsoletas de sacramentservice

PROCESO RECOMENDADO:
1. Ejecutar PASO 1-3 para ver estado actual
2. Hacer backup de BD completa
3. Preguntar al equipo por events, event_reactions, audit_logs
4. Si nadie las usa, descomentar PASO 5
5. Ejecutar PASO 5 (eliminar tablas)
6. Ejecutar PASO 6 (verificar resultado)
7. Probar TODOS los microservicios
*/

-- ═══════════════════════════════════════════════════════════════════════════
-- FIN DEL SCRIPT
-- ═══════════════════════════════════════════════════════════════════════════
