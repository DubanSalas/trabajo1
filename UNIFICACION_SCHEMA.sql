-- =====================================================
-- SCHEMA UNIFICADO PARA: vg-ms-requestservice
-- Fusiona: requests + enrollment_participants
-- Los demás microservicios se mantienen separados:
--   - vg-ms-preparationservice (preparation)
--   - vg-ms-celebrationservice (celebration)
--   - vg-ms-certificateservice (certificate)
-- =====================================================
-- CAMBIOS PRINCIPALES:
-- 1. Nueva tabla service_types (catálogo en BD, NO enum)
-- 2. requests → services (con service_type_id FK)
-- 3. enrollment_participants → service_participants
-- =====================================================

-- Tabla 1: Tipos de Servicio (NUEVO - Como pidió el profesor)
CREATE TABLE IF NOT EXISTS service_types (
    id              BIGSERIAL       PRIMARY KEY,
    code            VARCHAR(50)     NOT NULL UNIQUE,
    name            VARCHAR(100)    NOT NULL,
    description     TEXT,
    active          BOOLEAN         DEFAULT true,
    created_at      TIMESTAMP       DEFAULT NOW(),
    updated_at      TIMESTAMP       DEFAULT NOW()
);

-- Poblar con datos iniciales
INSERT INTO service_types (code, name, description) VALUES
('BAPTISM', 'Bautismo', 'Sacramento del Bautismo'),
('CONFIRMATION', 'Confirmación', 'Sacramento de la Confirmación'),
('MARRIAGE', 'Matrimonio', 'Sacramento del Matrimonio'),
('MASS', 'Misa Especial', 'Solicitud de misa especial'),
('BOOKS', 'Libros Sacramentales', 'Gestión de libros parroquiales')
ON CONFLICT (code) DO NOTHING;

-- Tabla 2: Services (antes requests)
-- Campos verificados contra schema original de requests
CREATE TABLE IF NOT EXISTS services (
    id                  BIGSERIAL       PRIMARY KEY,
    tenant_id           BIGINT          NOT NULL,
    user_id             BIGINT          NOT NULL,        -- persona que solicita → ms-users/personas
    service_type_id     BIGINT          NOT NULL REFERENCES service_types(id),
    sacrament_id        UUID,                             -- id en ms-sacraments (para requisitos)
    church_id           BIGINT,                           -- → ms-churches
    description         TEXT,
    document_url        TEXT,
    scheduled_date      DATE,                             -- OPCIONAL: fecha deseada (MATRIMONIO, MISA, LIBROS). NULL para BAUTISMO/CONFIRMACIÓN
    status              VARCHAR(30)     NOT NULL DEFAULT 'PENDING',
    request_date        TIMESTAMP       NOT NULL DEFAULT NOW(),
    certificate_id      BIGINT,                           -- → ms-certificates (cuando acta lista)
    response_data       TEXT,                             -- JSON con info de respuesta (link descarga, etc)
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW()
);

-- Índices para services (los mismos que requests original)
CREATE INDEX IF NOT EXISTS idx_services_tenant ON services(tenant_id);
CREATE INDEX IF NOT EXISTS idx_services_user ON services(user_id);
CREATE INDEX IF NOT EXISTS idx_services_type ON services(service_type_id);
CREATE INDEX IF NOT EXISTS idx_services_sacrament ON services(sacrament_id);
CREATE INDEX IF NOT EXISTS idx_services_status ON services(status);
CREATE INDEX IF NOT EXISTS idx_services_tenant_status ON services(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_services_tenant_type ON services(tenant_id, service_type_id);

-- Tabla 3: Service Participants (antes enrollment_participants)
CREATE TABLE IF NOT EXISTS service_participants (
    id              BIGSERIAL       PRIMARY KEY,
    tenant_id       BIGINT          NOT NULL,
    service_id      BIGINT          NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    user_id         BIGINT          NOT NULL,
    role            VARCHAR(50)     NOT NULL,
    document_url    TEXT,
    created_at      TIMESTAMP       DEFAULT NOW(),
    updated_at      TIMESTAMP       DEFAULT NOW()
);

-- Índices para participants
CREATE INDEX idx_participants_service ON service_participants(service_id);
CREATE INDEX idx_participants_user ON service_participants(user_id);
CREATE INDEX idx_participants_tenant ON service_participants(tenant_id);

-- Tabla 4: Preparations
CREATE TABLE IF NOT EXISTS preparations (
    id                  BIGSERIAL       PRIMARY KEY,
    tenant_id           BIGINT          NOT NULL,
    service_id          BIGINT          NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    type                VARCHAR(20)     NOT NULL,
    session_date        DATE            NOT NULL,
    status              VARCHAR(20)     NOT NULL DEFAULT 'PENDING',
    attendance_status   VARCHAR(20),
    payment_amount      DECIMAL(10,2),
    payment_status      VARCHAR(20),
    payment_date        DATE,
    payment_receipt_url TEXT,
    exam_score          INTEGER,
    exam_passed         BOOLEAN,
    notes               TEXT,
    created_at          TIMESTAMP       DEFAULT NOW(),
    updated_at          TIMESTAMP       DEFAULT NOW()
);

-- Índices para preparations
CREATE INDEX idx_preparations_service ON preparations(service_id);
CREATE INDEX idx_preparations_status ON preparations(status);
CREATE INDEX idx_preparations_tenant ON preparations(tenant_id);

-- Tabla 5: Celebrations
CREATE TABLE IF NOT EXISTS celebrations (
    id              BIGSERIAL       PRIMARY KEY,
    tenant_id       BIGINT          NOT NULL,
    service_id      BIGINT          NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    church_id       UUID,
    event_date      DATE            NOT NULL,
    event_time      TIME            NOT NULL,
    status          VARCHAR(20)     NOT NULL DEFAULT 'SCHEDULED',
    created_at      TIMESTAMP       DEFAULT NOW(),
    updated_at      TIMESTAMP       DEFAULT NOW(),
    
    UNIQUE(service_id)
);

-- Índices para celebrations
CREATE INDEX idx_celebrations_service ON celebrations(service_id);
CREATE INDEX idx_celebrations_status ON celebrations(status);
CREATE INDEX idx_celebrations_date ON celebrations(event_date);
CREATE INDEX idx_celebrations_tenant ON celebrations(tenant_id);

-- Comentarios explicativos
COMMENT ON TABLE service_types IS 'Catálogo de tipos de servicios sacramentales';
COMMENT ON TABLE services IS 'Solicitudes de servicios sacramentales (bautismo, confirmación, matrimonio, misa, libros)';
COMMENT ON TABLE service_participants IS 'Participantes en cada servicio (beneficiarios, padrinos, padres, etc.)';
COMMENT ON TABLE preparations IS 'Sesiones de preparación espiritual antes de la celebración';
COMMENT ON TABLE celebrations IS 'Celebraciones del sacramento (fecha, hora, iglesia)';

-- =====================================================
-- FIN DEL SCHEMA UNIFICADO
-- =====================================================
