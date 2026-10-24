-- =====================================================
-- MIGRATION: LIMPIAR CAMPOS DUPLICADOS EN CERTIFICATES
-- Fecha: 2026-10-17
-- Descripción: Eliminar desnormalización innecesaria.
-- Los datos de persona y tipo ya están en services.
-- =====================================================

-- Eliminar campos desnormalizados (duplican información de otros microservicios)
ALTER TABLE certificate DROP COLUMN IF EXISTS certificate_type;
ALTER TABLE certificate DROP COLUMN IF EXISTS main_person_id;
ALTER TABLE certificate DROP COLUMN IF EXISTS main_person_name;
ALTER TABLE certificate DROP COLUMN IF EXISTS certificate_data;

-- Eliminar índices asociados (ya no existen las columnas)
DROP INDEX IF EXISTS idx_cert_type;
DROP INDEX IF EXISTS idx_cert_main_person;
DROP INDEX IF EXISTS idx_cert_tenant_type;
DROP INDEX IF EXISTS idx_cert_person_name_text;

-- Agregar comentarios explicativos
COMMENT ON TABLE certificate IS 'Certificados/Actas sacramentales generados automáticamente después de celebraciones. Los datos de la persona y tipo se obtienen desde services.';
COMMENT ON COLUMN certificate.request_id IS 'FK a services - contiene user_id (persona) y service_type_id (tipo de sacramento)';
COMMENT ON COLUMN certificate.certificate_number IS 'Número de partida oficial asignado por el párroco (ej: B-2026-001)';
COMMENT ON COLUMN certificate.book IS 'Nombre del libro parroquial donde se registra (ej: Libro 5 de Bautismos)';
COMMENT ON COLUMN certificate.folio IS 'Número de folio/página en el libro parroquial';

-- Verificar estructura final
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'certificate' 
ORDER BY ordinal_position;
