-- ============================================
-- MIGRATION: ADD TENANT_ID TO ALL TABLES
-- Author: Duban Salas
-- Date: 2026-10-07
-- Description: Adds tenant_id column and indexes to enable multi-tenant isolation
-- ============================================

-- IMPORTANT: Run these ALTER TABLE commands manually after backup!
-- The DEFAULT 1 is temporary to avoid NOT NULL constraint errors.
-- After migration, change all tenant_id values to the correct tenant.

-- ============================================
-- 1. ENROLLMENT_PARTICIPANTS
-- ============================================
ALTER TABLE enrollment_participants 
ADD COLUMN IF NOT EXISTS tenant_id BIGINT NOT NULL DEFAULT 1;

ALTER TABLE enrollment_participants 
ALTER COLUMN tenant_id DROP DEFAULT;

CREATE INDEX IF NOT EXISTS idx_enroll_tenant ON enrollment_participants(tenant_id);
CREATE INDEX IF NOT EXISTS idx_enroll_tenant_request ON enrollment_participants(tenant_id, request_id);

-- ============================================
-- 2. PREPARATION
-- ============================================
ALTER TABLE preparation 
ADD COLUMN IF NOT EXISTS tenant_id BIGINT NOT NULL DEFAULT 1;

ALTER TABLE preparation 
ALTER COLUMN tenant_id DROP DEFAULT;

CREATE INDEX IF NOT EXISTS idx_prep_tenant ON preparation(tenant_id);
CREATE INDEX IF NOT EXISTS idx_prep_tenant_request ON preparation(tenant_id, request_id);

-- ============================================
-- 3. CELEBRATION
-- ============================================
ALTER TABLE celebration 
ADD COLUMN IF NOT EXISTS tenant_id BIGINT NOT NULL DEFAULT 1;

ALTER TABLE celebration 
ALTER COLUMN tenant_id DROP DEFAULT;

CREATE INDEX IF NOT EXISTS idx_celeb_tenant ON celebration(tenant_id);
CREATE INDEX IF NOT EXISTS idx_celeb_tenant_request ON celebration(tenant_id, request_id);

-- Add UNIQUE constraint on request_id (one celebration per request)
ALTER TABLE celebration 
ADD CONSTRAINT IF NOT EXISTS uk_celeb_request UNIQUE(request_id);

-- ============================================
-- 4. CERTIFICATE
-- ============================================
ALTER TABLE certificate 
ADD COLUMN IF NOT EXISTS tenant_id BIGINT NOT NULL DEFAULT 1;

ALTER TABLE certificate 
ALTER COLUMN tenant_id DROP DEFAULT;

CREATE INDEX IF NOT EXISTS idx_cert_tenant ON certificate(tenant_id);
CREATE INDEX IF NOT EXISTS idx_cert_tenant_request ON certificate(tenant_id, request_id);

-- Add UNIQUE constraints (one certificate per request/celebration)
ALTER TABLE certificate 
ADD CONSTRAINT IF NOT EXISTS uk_cert_request UNIQUE(request_id);

ALTER TABLE certificate 
ADD CONSTRAINT IF NOT EXISTS uk_cert_celebration UNIQUE(celebration_id);

-- Add validation: signed certificates must have number, book, folio
ALTER TABLE certificate 
ADD CONSTRAINT IF NOT EXISTS chk_cert_signed 
CHECK (
  signed = FALSE OR 
  (certificate_number IS NOT NULL AND 
   book IS NOT NULL AND 
   folio IS NOT NULL)
);

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check if columns were added
SELECT table_name, column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND column_name = 'tenant_id'
  AND table_name IN ('enrollment_participants', 'preparation', 'celebration', 'certificate')
ORDER BY table_name;

-- Check indexes
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND tablename IN ('enrollment_participants', 'preparation', 'celebration', 'certificate')
  AND indexname LIKE '%tenant%'
ORDER BY tablename, indexname;

-- Check constraints
SELECT conname, contype, conrelid::regclass AS table_name
FROM pg_constraint
WHERE conrelid IN ('celebration'::regclass, 'certificate'::regclass)
  AND contype IN ('u', 'c')
ORDER BY table_name, conname;
