-- =============================================
-- SCRIPT MAESTRO: RECREAR BASES DE DATOS
-- Elimina y recrea todas las BD con datos limpios
-- =============================================
-- Fecha: 2026-10-19
-- Propósito: Aplicar limpieza y correcciones de schemas
-- =============================================

-- IMPORTANTE: Ejecutar como superusuario de PostgreSQL
-- Ejemplo: psql -U postgres -f RECREAR_BD_COMPLETA.sql

\echo '======================================================'
\echo 'PASO 1: ELIMINAR BASES DE DATOS EXISTENTES'
\echo '======================================================'

-- Terminar conexiones activas antes de eliminar
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname IN ('servicesdb', 'preparationdb', 'celebrationdb', 'certificatedb')
  AND pid <> pg_backend_pid();

-- Eliminar bases de datos
DROP DATABASE IF EXISTS servicesdb;
DROP DATABASE IF EXISTS preparationdb;
DROP DATABASE IF EXISTS celebrationdb;
DROP DATABASE IF EXISTS certificatedb;

\echo 'Bases de datos eliminadas correctamente'
\echo ''

\echo '======================================================'
\echo 'PASO 2: CREAR BASES DE DATOS LIMPIAS'
\echo '======================================================'

CREATE DATABASE servicesdb
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Spanish_Peru.1252'
    LC_CTYPE = 'Spanish_Peru.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

CREATE DATABASE preparationdb
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Spanish_Peru.1252'
    LC_CTYPE = 'Spanish_Peru.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

CREATE DATABASE celebrationdb
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Spanish_Peru.1252'
    LC_CTYPE = 'Spanish_Peru.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

CREATE DATABASE certificatedb
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Spanish_Peru.1252'
    LC_CTYPE = 'Spanish_Peru.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

\echo 'Bases de datos creadas correctamente'
\echo ''

\echo '======================================================'
\echo 'PASO 3: CREAR SCHEMAS Y TABLAS'
\echo '======================================================'

-- =============================================
-- 3.1 SERVICESDB
-- =============================================
\echo 'Creando schema de servicesdb...'
\c servicesdb

CREATE TABLE IF NOT EXISTS service_type (
    id          BIGSERIAL   PRIMARY KEY,
    code        VARCHAR(30) NOT NULL UNIQUE,
    name        VARCHAR(100) NOT NULL,
    description TEXT,
    active      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE service_type IS 'Catálogo de tipos de servicio: BAPTISM, CONFIRMATION, MARRIAGE, MASS';
COMMENT ON COLUMN service_type.code IS 'Código único del tipo de servicio (BAPTISM, CONFIRMATION, MARRIAGE, MASS)';
COMMENT ON COLUMN service_type.name IS 'Nombre descriptivo del tipo de servicio';
COMMENT ON COLUMN service_type.active IS 'Indica si el tipo de servicio está disponible para nuevas solicitudes';

CREATE TABLE IF NOT EXISTS service (
    id                BIGSERIAL    PRIMARY KEY,
    tenant_id         BIGINT       NOT NULL,
    service_type_id   BIGINT       NOT NULL REFERENCES service_type(id),
    church_id         VARCHAR(255),
    description       TEXT,
    document_url      TEXT,
    scheduled_date    DATE,
    status            VARCHAR(30)  NOT NULL DEFAULT 'PENDING',
    request_date      TIMESTAMP    NOT NULL DEFAULT NOW(),
    certificate_id    BIGINT,
    response_data     TEXT,
    created_at        TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP    NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE service IS 'Solicitudes de servicios sacramentales y misas especiales';
COMMENT ON COLUMN service.tenant_id IS 'ID del tenant (parroquia) - referencia a vg-ms-organization';
COMMENT ON COLUMN service.service_type_id IS 'Tipo de servicio (FK a service_type)';
COMMENT ON COLUMN service.church_id IS 'ID de la iglesia donde se realizará - referencia a vg-ms-churches';
COMMENT ON COLUMN service.status IS 'Estado: PENDING, APPROVED, REJECTED, COMPLETED';

CREATE INDEX idx_service_tenant ON service(tenant_id);
CREATE INDEX idx_service_type ON service(service_type_id);
CREATE INDEX idx_service_status ON service(status);
CREATE INDEX idx_service_date ON service(scheduled_date);

CREATE TABLE IF NOT EXISTS service_participant (
    id          BIGSERIAL   PRIMARY KEY,
    tenant_id   BIGINT      NOT NULL,
    service_id  BIGINT      NOT NULL REFERENCES service(id) ON DELETE CASCADE,
    user_id     BIGINT      NOT NULL,
    role        VARCHAR(50) NOT NULL,
    document_url TEXT,
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE service_participant IS 'Participantes de un servicio (bautizado, padres, padrinos, novios, etc.)';
COMMENT ON COLUMN service_participant.role IS 'Rol del participante: CHILD, FATHER, MOTHER, GODFATHER, GODMOTHER, GROOM, BRIDE, CONFIRMED, GODPARENT';
COMMENT ON COLUMN service_participant.user_id IS 'ID del usuario participante - referencia a vg-ms-users';

CREATE INDEX idx_participant_service ON service_participant(service_id);
CREATE INDEX idx_participant_user ON service_participant(user_id);
CREATE INDEX idx_participant_role ON service_participant(role);

-- Insertar tipos de servicio
INSERT INTO service_type (code, name, description, active) VALUES
('BAPTISM', 'Bautismo', 'Sacramento del Bautismo', true),
('CONFIRMATION', 'Confirmación', 'Sacramento de la Confirmación', true),
('MARRIAGE', 'Matrimonio', 'Sacramento del Matrimonio', true),
('MASS', 'Misa Especial', 'Solicitud de Misa Especial', true);

\echo 'Schema de servicesdb creado correctamente'

-- =============================================
-- 3.2 PREPARATIONDB
-- =============================================
\echo 'Creando schema de preparationdb...'
\c preparationdb

CREATE TABLE IF NOT EXISTS preparation (
    id                BIGSERIAL   PRIMARY KEY,
    tenant_id         BIGINT      NOT NULL,
    service_id        BIGINT      NOT NULL,
    type              VARCHAR(30) NOT NULL,
    session_date      DATE        NOT NULL,
    status            VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    attendance_status VARCHAR(30),
    exam_score        INTEGER,
    exam_passed       BOOLEAN,
    notes             TEXT,
    created_at        TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE preparation IS 'Sesiones de preparación previa al sacramento';
COMMENT ON COLUMN preparation.tenant_id IS 'ID del tenant (parroquia)';
COMMENT ON COLUMN preparation.service_id IS 'ID del servicio asociado - referencia a vg-ms-services';
COMMENT ON COLUMN preparation.type IS 'Tipo de sesión: TITULAR (para quien recibe el sacramento), GODPARENT (para padrinos)';
COMMENT ON COLUMN preparation.status IS 'Estado: PENDING, IN_PROGRESS, COMPLETED, CANCELLED';
COMMENT ON COLUMN preparation.attendance_status IS 'Asistencia: PRESENT, ABSENT, EXCUSED';
COMMENT ON COLUMN preparation.exam_score IS 'Puntuación del examen (0-100) - solo para Confirmación';
COMMENT ON COLUMN preparation.exam_passed IS 'Indica si aprobó el examen - solo para Confirmación';

CREATE INDEX idx_preparation_service ON preparation(service_id);
CREATE INDEX idx_preparation_tenant ON preparation(tenant_id);
CREATE INDEX idx_preparation_date ON preparation(session_date);
CREATE INDEX idx_preparation_status ON preparation(status);

\echo 'Schema de preparationdb creado correctamente'

-- =============================================
-- 3.3 CELEBRATIONDB
-- =============================================
\echo 'Creando schema de celebrationdb...'
\c celebrationdb

CREATE TABLE IF NOT EXISTS celebration (
    id          BIGSERIAL    PRIMARY KEY,
    tenant_id   BIGINT       NOT NULL,
    service_id  BIGINT       NOT NULL,
    church_id   VARCHAR(255) NOT NULL,
    event_date  DATE         NOT NULL,
    event_time  TIME         NOT NULL,
    status      VARCHAR(30)  NOT NULL DEFAULT 'SCHEDULED',
    created_at  TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE celebration IS 'Celebraciones sacramentales programadas';
COMMENT ON COLUMN celebration.tenant_id IS 'ID del tenant (parroquia)';
COMMENT ON COLUMN celebration.service_id IS 'ID del servicio - referencia a vg-ms-services';
COMMENT ON COLUMN celebration.church_id IS 'ID de la iglesia - referencia a vg-ms-churches';
COMMENT ON COLUMN celebration.status IS 'Estado: SCHEDULED, REALIZED, CANCELLED';

CREATE INDEX idx_celebration_service ON celebration(service_id);
CREATE INDEX idx_celebration_date ON celebration(event_date);
CREATE INDEX idx_celebration_status ON celebration(status);
CREATE INDEX idx_celebration_tenant ON celebration(tenant_id);

\echo 'Schema de celebrationdb creado correctamente'

-- =============================================
-- 3.4 CERTIFICATEDB
-- =============================================
\echo 'Creando schema de certificatedb...'
\c certificatedb

CREATE TABLE IF NOT EXISTS certificate (
    id                   BIGSERIAL   PRIMARY KEY,
    tenant_id            BIGINT      NOT NULL,
    service_id           BIGINT      NOT NULL,
    celebration_id       BIGINT      NOT NULL,
    certificate_number   VARCHAR(50),
    book                 VARCHAR(100),
    folio                VARCHAR(50),
    signed               BOOLEAN     NOT NULL DEFAULT FALSE,
    signed_at            TIMESTAMP,
    signed_by_user_id    BIGINT,
    issued_at            TIMESTAMP   NOT NULL DEFAULT NOW(),
    created_at           TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMP   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE certificate IS 'Actas sacramentales oficiales';
COMMENT ON COLUMN certificate.tenant_id IS 'ID del tenant (parroquia)';
COMMENT ON COLUMN certificate.service_id IS 'ID del servicio - referencia a vg-ms-services (contiene service_type_id y user_id)';
COMMENT ON COLUMN certificate.celebration_id IS 'ID de la celebración - referencia a vg-ms-celebration';
COMMENT ON COLUMN certificate.certificate_number IS 'Número de partida (ej: B-2026-001)';
COMMENT ON COLUMN certificate.book IS 'Libro donde se registró (ej: Libro 5)';
COMMENT ON COLUMN certificate.folio IS 'Folio o página del libro';
COMMENT ON COLUMN certificate.signed IS 'Indica si el acta fue firmada manualmente por el párroco';
COMMENT ON COLUMN certificate.signed_at IS 'Fecha y hora de la firma';
COMMENT ON COLUMN certificate.signed_by_user_id IS 'ID del párroco que firmó - referencia a vg-ms-users';

CREATE INDEX idx_certificate_service ON certificate(service_id);
CREATE INDEX idx_certificate_celebration ON certificate(celebration_id);
CREATE INDEX idx_certificate_tenant ON certificate(tenant_id);
CREATE INDEX idx_certificate_signed ON certificate(signed);
CREATE INDEX idx_certificate_number ON certificate(certificate_number);

\echo 'Schema de certificatedb creado correctamente'
\echo ''

\echo '======================================================'
\echo 'PASO 4: INSERTAR DATOS DE PRUEBA - TENANT 9'
\echo '======================================================'

-- =============================================
-- 4.1 DATOS DE PRUEBA - SERVICESDB
-- =============================================
\echo 'Insertando datos de prueba en servicesdb...'
\c servicesdb

-- Servicio 1: Bautismo
INSERT INTO service (tenant_id, service_type_id, church_id, description, status, request_date, scheduled_date)
VALUES (9, 1, 'church-uuid-001', 'Bautismo de Juan Pérez', 'APPROVED', NOW() - INTERVAL '5 days', CURRENT_DATE + INTERVAL '30 days');

-- Servicio 2: Confirmación
INSERT INTO service (tenant_id, service_type_id, church_id, description, status, request_date, scheduled_date)
VALUES (9, 2, 'church-uuid-001', 'Confirmación de María López', 'APPROVED', NOW() - INTERVAL '3 days', CURRENT_DATE + INTERVAL '45 days');

-- Servicio 3: Matrimonio
INSERT INTO service (tenant_id, service_type_id, church_id, description, status, request_date, scheduled_date)
VALUES (9, 3, 'church-uuid-001', 'Matrimonio de Carlos y Ana', 'APPROVED', NOW() - INTERVAL '7 days', CURRENT_DATE + INTERVAL '60 days');

-- Participantes del Bautismo (service_id=1)
INSERT INTO service_participant (tenant_id, service_id, user_id, role) VALUES
(9, 1, 32, 'CHILD'),      -- Bautizado
(9, 1, 33, 'FATHER'),     -- Padre
(9, 1, 34, 'MOTHER'),     -- Madre
(9, 1, 35, 'GODFATHER'),  -- Padrino
(9, 1, 36, 'GODMOTHER');  -- Madrina

-- Participantes de la Confirmación (service_id=2)
INSERT INTO service_participant (tenant_id, service_id, user_id, role) VALUES
(9, 2, 32, 'CONFIRMED'),  -- Confirmado
(9, 2, 33, 'FATHER'),     -- Padre
(9, 2, 34, 'MOTHER'),     -- Madre
(9, 2, 35, 'GODPARENT');  -- Padrino/Madrina

-- Participantes del Matrimonio (service_id=3)
INSERT INTO service_participant (tenant_id, service_id, user_id, role) VALUES
(9, 3, 37, 'GROOM'),       -- Novio
(9, 3, 38, 'BRIDE'),       -- Novia
(9, 3, 35, 'GODFATHER'),   -- Padrino
(9, 3, 36, 'GODMOTHER');   -- Madrina

\echo 'Datos de prueba insertados en servicesdb'

-- =============================================
-- 4.2 DATOS DE PRUEBA - PREPARATIONDB
-- =============================================
\echo 'Insertando datos de prueba en preparationdb...'
\c preparationdb

-- Preparación para Bautismo (service_id=1)
INSERT INTO preparation (tenant_id, service_id, type, session_date, status, attendance_status) VALUES
(9, 1, 'TITULAR', CURRENT_DATE + INTERVAL '5 days', 'PENDING', NULL),
(9, 1, 'GODPARENT', CURRENT_DATE + INTERVAL '10 days', 'PENDING', NULL);

-- Preparación para Confirmación (service_id=2)
INSERT INTO preparation (tenant_id, service_id, type, session_date, status, attendance_status, exam_score, exam_passed) VALUES
(9, 2, 'TITULAR', CURRENT_DATE + INTERVAL '7 days', 'PENDING', NULL, NULL, NULL),
(9, 2, 'TITULAR', CURRENT_DATE + INTERVAL '14 days', 'PENDING', NULL, NULL, NULL),
(9, 2, 'TITULAR', CURRENT_DATE + INTERVAL '21 days', 'PENDING', NULL, NULL, NULL);

-- Preparación para Matrimonio (service_id=3)
INSERT INTO preparation (tenant_id, service_id, type, session_date, status, attendance_status) VALUES
(9, 3, 'TITULAR', CURRENT_DATE + INTERVAL '15 days', 'PENDING', NULL),
(9, 3, 'TITULAR', CURRENT_DATE + INTERVAL '30 days', 'PENDING', NULL),
(9, 3, 'TITULAR', CURRENT_DATE + INTERVAL '45 days', 'PENDING', NULL);

\echo 'Datos de prueba insertados en preparationdb'

-- =============================================
-- 4.3 DATOS DE PRUEBA - CELEBRATIONDB
-- =============================================
\echo 'Insertando datos de prueba en celebrationdb...'
\c celebrationdb

-- NOTA: En producción, las celebraciones se crean cuando:
-- 1. Todas las preparaciones están completadas
-- 2. El párroco o secretario programa la fecha
-- 3. El pago está confirmado
-- Aquí agregamos ejemplos para pruebas

-- Celebración para Bautismo (service_id=1)
INSERT INTO celebration (tenant_id, service_id, church_id, event_date, event_time, status)
VALUES (9, 1, 'church-uuid-001', CURRENT_DATE + INTERVAL '30 days', '10:00:00', 'SCHEDULED');

-- Celebración para Confirmación (service_id=2) 
INSERT INTO celebration (tenant_id, service_id, church_id, event_date, event_time, status)
VALUES (9, 2, 'church-uuid-001', CURRENT_DATE + INTERVAL '45 days', '11:00:00', 'SCHEDULED');

-- Celebración para Matrimonio (service_id=3)
INSERT INTO celebration (tenant_id, service_id, church_id, event_date, event_time, status)
VALUES (9, 3, 'church-uuid-001', CURRENT_DATE + INTERVAL '60 days', '16:00:00', 'SCHEDULED');

\echo 'Datos de prueba insertados en celebrationdb'

-- =============================================
-- 4.4 DATOS DE PRUEBA - CERTIFICATEDB
-- =============================================
\echo 'Insertando datos de prueba en certificatedb...'
\c certificatedb

-- NOTA: En producción, los certificados se generan automáticamente cuando:
-- 1. La celebración se marca como REALIZED
-- 2. El sistema genera el acta con estado signed=false
-- 3. El párroco la firma manualmente agregando número, libro y folio
-- Aquí agregamos ejemplos para pruebas de búsqueda de actas

-- Certificado para Bautismo (service_id=1, celebration_id=1) - SIN FIRMAR
INSERT INTO certificate (tenant_id, service_id, celebration_id, signed, issued_at)
VALUES (9, 1, 1, false, NOW());

-- Certificado para Confirmación (service_id=2, celebration_id=2) - SIN FIRMAR
INSERT INTO certificate (tenant_id, service_id, celebration_id, signed, issued_at)
VALUES (9, 2, 2, false, NOW());

-- Certificado para Matrimonio (service_id=3, celebration_id=3) - FIRMADO (ejemplo)
INSERT INTO certificate (tenant_id, service_id, celebration_id, certificate_number, book, folio, signed, signed_at, signed_by_user_id, issued_at)
VALUES (9, 3, 3, 'M-2026-001', 'Libro 10', '15', true, NOW(), 1, NOW() - INTERVAL '2 days');

\echo 'Datos de prueba insertados en certificatedb'

\echo ''
\echo '======================================================'
\echo 'RESUMEN'
\echo '======================================================'
\echo 'Bases de datos recreadas:'
\echo '  ✓ servicesdb      - 4 tipos de servicio, 3 servicios, 13 participantes'
\echo '  ✓ preparationdb   - 8 sesiones de preparación'
\echo '  ✓ celebrationdb   - 3 celebraciones programadas'
\echo '  ✓ certificatedb   - 3 actas (2 sin firmar, 1 firmada)'
\echo ''
\echo 'Tenant de prueba: 9'
\echo 'Usuario feligrés: 32'
\echo ''
\echo 'Para iniciar los microservicios ejecuta:'
\echo '  mvn spring-boot:run (en cada microservicio)'
\echo '======================================================'
