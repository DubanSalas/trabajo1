-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION: Eliminar campos de control de copias de la tabla certificate
-- FECHA: 2026-10-17
-- RAZÓN: No se necesita llevar contador de descargas de PDFs
-- ═══════════════════════════════════════════════════════════════════════════

-- Eliminar campos innecesarios de control de copias
ALTER TABLE certificate 
DROP COLUMN IF EXISTS copies_issued,
DROP COLUMN IF EXISTS last_copy_date;

-- Verificación
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'certificate'
ORDER BY ordinal_position;

COMMENT ON TABLE certificate IS 'Certificados/Actas sacramentales generados después de celebraciones. Solo contiene datos específicos del certificado, no duplica datos de services o users.';
