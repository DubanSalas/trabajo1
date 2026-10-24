-- ═════════════════════════════════════════════════════════════════════════════
-- MIGRATION: Cambiar tenant_id de VARCHAR a BIGINT en preparation
-- Fecha: 2026-10-19
-- Propósito: Consistencia de tipos entre todos los microservicios
-- ═════════════════════════════════════════════════════════════════════════════

-- Verificar estado actual
SELECT 
    column_name, 
    data_type, 
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'preparation' 
AND column_name = 'tenant_id';

-- Cambiar tenant_id de VARCHAR(100) a BIGINT
-- Solo si la columna existe y es VARCHAR
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'preparation' 
        AND column_name = 'tenant_id' 
        AND data_type = 'character varying'
    ) THEN
        -- Cambiar tipo de dato
        ALTER TABLE preparation 
            ALTER COLUMN tenant_id TYPE BIGINT 
            USING tenant_id::BIGINT;
        
        RAISE NOTICE 'preparation.tenant_id cambiado de VARCHAR a BIGINT exitosamente';
    ELSE
        RAISE NOTICE 'preparation.tenant_id ya es BIGINT o no existe';
    END IF;
END $$;

-- Verificar cambio
SELECT 
    column_name, 
    data_type, 
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'preparation' 
AND column_name = 'tenant_id';

-- Verificar que no hay datos corruptos
SELECT COUNT(*) as total_registros FROM preparation;
SELECT DISTINCT tenant_id FROM preparation ORDER BY tenant_id;

-- ═════════════════════════════════════════════════════════════════════════════
-- FIN DE MIGRACIÓN
-- ═════════════════════════════════════════════════════════════════════════════
