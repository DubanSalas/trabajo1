-- =====================================================
-- MIGRACIÓN: Eliminar campos redundantes de services
-- Microservicio: vg-ms-requestsservice-hexagonal
-- Cambios:
--   1. Eliminar sacrament_id (redundante con service_type_id)
--   2. Eliminar user_id (duplicado en service_participants)
-- =====================================================

-- 1. Eliminar índices
DROP INDEX IF EXISTS idx_services_sacrament;
DROP INDEX IF EXISTS idx_services_user;

-- 2. Migrar datos: Mover user_id de services a service_participants
-- Crear registro en service_participants con role='TITULAR' para cada solicitud
INSERT INTO service_participants (tenant_id, service_id, user_id, role, created_at, updated_at)
SELECT tenant_id, id, user_id, 'TITULAR', NOW(), NOW()
FROM services
WHERE user_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- 3. Eliminar columnas
ALTER TABLE services DROP COLUMN IF EXISTS sacrament_id;
ALTER TABLE services DROP COLUMN IF EXISTS user_id;

-- Verificación
SELECT 'Migración completada: sacrament_id y user_id eliminados de services' AS resultado;
SELECT 'Datos migrados a service_participants con role=TITULAR' AS resultado;
