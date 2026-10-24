-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION: Eliminar campos de pago de la tabla preparation
-- FECHA: 2026-10-17
-- RAZÓN: Los datos de pago deben obtenerse del microservicio de pagos/finanzas
--        Evitar duplicación de datos (Single Source of Truth)
-- ═══════════════════════════════════════════════════════════════════════════

-- Eliminar campos de pago innecesarios
ALTER TABLE preparation 
DROP COLUMN IF EXISTS payment_amount,
DROP COLUMN IF EXISTS payment_status,
DROP COLUMN IF EXISTS payment_date,
DROP COLUMN IF EXISTS payment_receipt_url;

-- Verificación
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'preparation'
ORDER BY ordinal_position;

COMMENT ON TABLE preparation IS 'Preparaciones sacramentales (catequesis, charlas prematrimoniales, etc.). Los datos de pago se obtienen del microservicio de pagos.';
COMMENT ON COLUMN preparation.request_id IS 'FK a services en vg-ms-requestsservice - contiene la solicitud de sacramento relacionada';
COMMENT ON COLUMN preparation.type IS 'TITULAR (solicitante) o GODPARENT (padrino/madrina)';
COMMENT ON COLUMN preparation.status IS 'PENDING, IN_PROGRESS, COMPLETED, CANCELLED';
COMMENT ON COLUMN preparation.attendance_status IS 'PRESENT, ABSENT, EXCUSED';
COMMENT ON COLUMN preparation.exam_score IS 'Nota del examen de preparación (0-100)';
COMMENT ON COLUMN preparation.exam_passed IS 'Indica si aprobó el examen de preparación';
