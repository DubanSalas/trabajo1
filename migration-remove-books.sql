-- =====================================================
-- MIGRATION: ELIMINAR BOOKS DE SERVICE_TYPES
-- Fecha: 2026-10-17
-- Descripción: BOOKS ya no es un tipo de solicitud válido.
-- Las actas se consultan desde el módulo de Actas, no se solicitan.
-- =====================================================

-- Eliminar el tipo BOOKS de service_types
DELETE FROM service_types WHERE code = 'BOOKS';

-- Verificar que solo quedan 4 tipos válidos
SELECT code, name, active FROM service_types ORDER BY id;

-- Si hay solicitudes existentes con BOOKS (no debería), marcarlas como DELETED
UPDATE services 
SET status = 'DELETED', 
    updated_at = NOW()
WHERE service_type_id = (SELECT id FROM service_types WHERE code = 'BOOKS')
  AND status != 'DELETED';

-- Comentario final
COMMENT ON TABLE service_types IS 'Catálogo de tipos de servicios sacramentales: BAPTISM, CONFIRMATION, MARRIAGE, MASS. BOOKS eliminado en Oct 2026.';
