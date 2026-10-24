-- ═══════════════════════════════════════════════════════════════════════════
-- SCRIPT DE MIGRACIÓN COMPLETA
-- Sistema: FideiNexus - Gestión Parroquial
-- Responsables: Duban + Ordoñez
-- Fecha: 14 de Octubre 2026
-- ═══════════════════════════════════════════════════════════════════════════
-- IMPORTANTE: Ejecutar este script en ambiente de DESARROLLO primero
-- Hacer backup de la BD de producción antes de ejecutar
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- PASO 1: ELIMINAR TABLAS ANTIGUAS (en orden correcto por FK)
-- ═══════════════════════════════════════════════════════════════════════════

-- Eliminar tablas en orden inverso de dependencias
DROP TABLE IF EXISTS certificate CASCADE;
DROP TABLE IF EXISTS celebration CASCADE;
DROP TABLE IF EXISTS preparation CASCADE;
DROP TABLE IF EXISTS service_participants CASCADE;
DROP TABLE IF EXISTS enrollment_participants CASCADE;  -- Tabla vieja
DROP TABLE IF EXISTS services CASCADE;
DROP TABLE IF EXISTS requests CASCADE;  -- Tabla vieja
DROP TABLE IF EXISTS service_types CASCADE;

-- ═══════════════════════════════════════════════════════════════════════════
-- PASO 2: CREAR TABLAS NUEVAS
-- ═══════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────
-- MICROSERVICIO: vg-ms-requestservice (UNIFICADO)
-- ───────────────────────────────────────────────────────────────────────────

-- Tabla 1: service_types (Catálogo de tipos de servicio)
CREATE TABLE service_types (
    id              BIGSERIAL       PRIMARY KEY,
    code            VARCHAR(50)     NOT NULL UNIQUE,
    name            VARCHAR(100)    NOT NULL,
    description     TEXT,
    active          BOOLEAN         DEFAULT true,
    created_at      TIMESTAMP       DEFAULT NOW(),
    updated_at      TIMESTAMP       DEFAULT NOW()
);

COMMENT ON TABLE service_types IS 'Catálogo de tipos de servicios sacramentales (BAPTISM, CONFIRMATION, MARRIAGE, MASS, BOOKS)';
COMMENT ON COLUMN service_types.code IS 'Código único del tipo de servicio';
COMMENT ON COLUMN service_types.active IS 'TRUE = disponible, FALSE = deshabilitado (soft delete)';

-- Tabla 2: services (Solicitudes de servicios sacramentales)
CREATE TABLE services (
    id                  BIGSERIAL       PRIMARY KEY,
    tenant_id           BIGINT          NOT NULL,
    user_id             BIGINT          NOT NULL,
    service_type_id     BIGINT          NOT NULL REFERENCES service_types(id),
    sacrament_id        UUID,
    church_id           BIGINT,
    description         TEXT,
    document_url        TEXT,
    scheduled_date      DATE,
    status              VARCHAR(30)     NOT NULL DEFAULT 'PENDING',
    request_date        TIMESTAMP       NOT NULL DEFAULT NOW(),
    certificate_id      BIGINT,
    response_data       TEXT,
    created_at          TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP       NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE services IS 'Solicitudes de servicios sacramentales (fusiona requests + enrollments)';
COMMENT ON COLUMN services.user_id IS 'ID del feligrés que solicita (→ ms-users)';
COMMENT ON COLUMN services.service_type_id IS 'Tipo de servicio (FK → service_types)';
COMMENT ON COLUMN services.sacrament_id IS 'ID del sacramento en ms-sacraments (solo si tiene requisitos)';
COMMENT ON COLUMN services.scheduled_date IS 'Fecha deseada: MATRIMONIO/MISA/LIBROS (NULL para BAUTISMO/CONFIRMACIÓN)';
COMMENT ON COLUMN services.status IS 'PENDING → APPROVED → IN_PROGRESS → COMPLETED / REJECTED';
COMMENT ON COLUMN services.certificate_id IS 'ID del acta generada (→ ms-certificates, solo cuando status=COMPLETED)';
COMMENT ON COLUMN services.response_data IS 'JSON con info de respuesta: {"downloadUrl":"...", "message":"..."}';

-- Índices para services
CREATE INDEX idx_services_tenant         ON services(tenant_id);
CREATE INDEX idx_services_user           ON services(user_id);
CREATE INDEX idx_services_type           ON services(service_type_id);
CREATE INDEX idx_services_sacrament      ON services(sacrament_id);
CREATE INDEX idx_services_status         ON services(status);
CREATE INDEX idx_services_tenant_status  ON services(tenant_id, status);
CREATE INDEX idx_services_tenant_type    ON services(tenant_id, service_type_id);
CREATE INDEX idx_services_certificate    ON services(certificate_id);

-- Tabla 3: service_participants (Participantes en servicios)
CREATE TABLE service_participants (
    id              BIGSERIAL       PRIMARY KEY,
    tenant_id       BIGINT          NOT NULL,
    service_id      BIGINT          NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    user_id         BIGINT          NOT NULL,
    role            VARCHAR(50)     NOT NULL,
    document_url    TEXT,
    created_at      TIMESTAMP       DEFAULT NOW(),
    updated_at      TIMESTAMP       DEFAULT NOW()
);

COMMENT ON TABLE service_participants IS 'Participantes en cada servicio: padrinos, padres, beneficiarios, testigos';
COMMENT ON COLUMN service_participants.role IS 'CHILD, FATHER, MOTHER, GODFATHER, GODMOTHER, GROOM, BRIDE, WITNESS, etc.';
COMMENT ON COLUMN service_participants.document_url IS 'URL de documentos del participante (opcional)';

-- Índices para service_participants
CREATE INDEX idx_participants_service        ON service_participants(service_id);
CREATE INDEX idx_participants_user           ON service_participants(user_id);
CREATE INDEX idx_participants_tenant         ON service_participants(tenant_id);
CREATE INDEX idx_participants_role           ON service_participants(role);
CREATE INDEX idx_participants_tenant_service ON service_participants(tenant_id, service_id);

-- ───────────────────────────────────────────────────────────────────────────
-- MICROSERVICIO: vg-ms-preparationservice
-- ───────────────────────────────────────────────────────────────────────────

CREATE TABLE preparation (
    id                   BIGSERIAL       PRIMARY KEY,
    request_id           BIGINT          NOT NULL,
    type                 VARCHAR(20)     NOT NULL DEFAULT 'TITULAR',
    session_date         DATE            NOT NULL,
    status               VARCHAR(30)     NOT NULL DEFAULT 'PENDING',
    attendance_status    VARCHAR(20),
    payment_amount       DECIMAL(10,2),
    payment_status       VARCHAR(20),
    payment_date         DATE,
    payment_receipt_url  TEXT,
    exam_score           INTEGER,
    exam_passed          BOOLEAN,
    notes                TEXT,
    created_at           TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMP       NOT NULL DEFAULT NOW(),
    tenant_id            VARCHAR(100)    NOT NULL
);

COMMENT ON TABLE preparation IS 'Sesiones de preparación espiritual (charlas, cursos)';
COMMENT ON COLUMN preparation.type IS 'TITULAR = principal, REFUERZO = adicional';
COMMENT ON COLUMN preparation.status IS 'PENDING → COMPLETED → APPROVED';
COMMENT ON COLUMN preparation.attendance_status IS 'PRESENTE, AUSENTE, JUSTIFICADO';
COMMENT ON COLUMN preparation.exam_passed IS 'TRUE si aprobó el examen (solo Confirmación)';

CREATE INDEX idx_prep_request  ON preparation(request_id);
CREATE INDEX idx_prep_status   ON preparation(status);
CREATE INDEX idx_prep_req_stat ON preparation(request_id, status);
CREATE INDEX idx_prep_tenant   ON preparation(tenant_id);

-- ───────────────────────────────────────────────────────────────────────────
-- MICROSERVICIO: vg-ms-celebrationservice
-- ───────────────────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE celebration (
    id            BIGSERIAL   PRIMARY KEY,
    request_id    BIGINT      NOT NULL,
    church_id     UUID,
    event_date    DATE        NOT NULL,
    event_time    TIME        NOT NULL,
    status        VARCHAR(30) NOT NULL DEFAULT 'SCHEDULED',
    tenant_id     BIGINT      NOT NULL,
    created_at    TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE celebration IS 'Fecha/hora/lugar confirmados de la celebración del sacramento';
COMMENT ON COLUMN celebration.church_id IS 'ID de la iglesia (→ ms-churches, UUID)';
COMMENT ON COLUMN celebration.status IS 'SCHEDULED → COMPLETED → CANCELLED';

CREATE INDEX idx_celeb_request ON celebration(request_id);
CREATE INDEX idx_celeb_status  ON celebration(status);
CREATE INDEX idx_celeb_tenant  ON celebration(tenant_id);
CREATE INDEX idx_celeb_church  ON celebration(church_id);
CREATE INDEX idx_celeb_date    ON celebration(event_date);

-- ───────────────────────────────────────────────────────────────────────────
-- MICROSERVICIO: vg-ms-certificateservice
-- ───────────────────────────────────────────────────────────────────────────

CREATE TABLE certificate (
    id                   BIGSERIAL   PRIMARY KEY,
    tenant_id            BIGINT      NOT NULL,
    request_id           BIGINT      NOT NULL,
    celebration_id       BIGINT      NOT NULL,
    
    -- Campos para búsqueda y clasificación
    certificate_type     VARCHAR(30),
    main_person_id       BIGINT,
    main_person_name     VARCHAR(200),
    certificate_data     TEXT,
    
    -- Numeración oficial
    certificate_number   VARCHAR(50),
    book                 VARCHAR(100),
    folio                VARCHAR(50),
    
    -- Firma y validación
    signed               BOOLEAN     NOT NULL DEFAULT FALSE,
    signed_at            TIMESTAMP,
    signed_by_user_id    BIGINT,
    
    -- Control de copias
    copies_issued        INTEGER     DEFAULT 0,
    last_copy_date       TIMESTAMP,
    
    issued_at            TIMESTAMP   NOT NULL DEFAULT NOW(),
    created_at           TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMP   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE certificate IS 'Actas/certificados sacramentales (firmadas o sin firmar)';
COMMENT ON COLUMN certificate.certificate_type IS 'BAPTISM, CONFIRMATION, MARRIAGE (para búsqueda rápida)';
COMMENT ON COLUMN certificate.main_person_id IS 'ID de la persona principal (beneficiario)';
COMMENT ON COLUMN certificate.main_person_name IS 'Nombre completo desnormalizado (búsqueda rápida)';
COMMENT ON COLUMN certificate.certificate_data IS 'JSON con todos los datos del acta (padrinos, padres, etc)';
COMMENT ON COLUMN certificate.signed IS 'FALSE = borrador, TRUE = firmada por párroco';
COMMENT ON COLUMN certificate.copies_issued IS 'Contador de copias emitidas (inicia en 0)';

-- Índices para certificate
CREATE INDEX idx_cert_request          ON certificate(request_id);
CREATE INDEX idx_cert_celebration      ON certificate(celebration_id);
CREATE INDEX idx_cert_signed           ON certificate(signed);
CREATE INDEX idx_cert_tenant           ON certificate(tenant_id);
CREATE INDEX idx_cert_type             ON certificate(certificate_type);
CREATE INDEX idx_cert_main_person      ON certificate(main_person_id);
CREATE INDEX idx_cert_tenant_type      ON certificate(tenant_id, certificate_type);
CREATE INDEX idx_cert_tenant_signed    ON certificate(tenant_id, signed);
CREATE INDEX idx_cert_person_name_text ON certificate USING gin(to_tsvector('spanish', main_person_name));

-- ═══════════════════════════════════════════════════════════════════════════
-- PASO 3: POBLAR DATOS INICIALES
-- ═══════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────
-- 3.1. service_types (Catálogo de tipos de servicio)
-- ───────────────────────────────────────────────────────────────────────────

INSERT INTO service_types (code, name, description, active) VALUES
('BAPTISM', 'Bautismo', 'Sacramento del Bautismo - Iniciación cristiana', TRUE),
('CONFIRMATION', 'Confirmación', 'Sacramento de la Confirmación - Don del Espíritu Santo', TRUE),
('MARRIAGE', 'Matrimonio', 'Sacramento del Matrimonio - Unión sacramental', TRUE),
('MASS', 'Misa Especial', 'Solicitud de misa especial (difuntos, acción de gracias, etc)', TRUE),
('BOOKS', 'Libros Sacramentales', 'Solicitud de acta o certificado sacramental', TRUE);

-- ═══════════════════════════════════════════════════════════════════════════
-- PASO 4: DATOS DE PRUEBA (Comentar en producción)
-- ═══════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────
-- 4.1. ESCENARIO 1: Bautismo completado con acta firmada
-- ───────────────────────────────────────────────────────────────────────────

-- Solicitud de bautismo (scheduled_date = NULL porque primero va preparación)
INSERT INTO services (
    id, tenant_id, user_id, service_type_id, church_id, description, 
    scheduled_date, status, request_date, certificate_id, response_data, created_at
) VALUES (
    1, 9, 35, 1, 1, 'Solicitud de bautismo para bebé Juan Pérez García',
    NULL, 'COMPLETED', '2026-08-15 10:00:00', 1,
    '{"downloadUrl": "/api/v1/certificates/1/pdf", "message": "Tu acta de bautismo está lista para descargar"}',
    '2026-08-15 10:00:00'
);

-- Participantes del bautismo
INSERT INTO service_participants (tenant_id, service_id, user_id, role, created_at) VALUES
(9, 1, 35, 'CHILD', '2026-08-15 10:05:00'),      -- Bautizado
(9, 1, 32, 'FATHER', '2026-08-15 10:05:00'),     -- Padre
(9, 1, 37, 'MOTHER', '2026-08-15 10:05:00'),     -- Madre
(9, 1, 35, 'GODFATHER', '2026-08-15 10:05:00'),  -- Padrino
(9, 1, 32, 'GODMOTHER', '2026-08-15 10:05:00');  -- Madrina

-- Preparación completada
INSERT INTO preparation (
    request_id, type, session_date, status, attendance_status, 
    payment_amount, payment_status, payment_date, notes, tenant_id
) VALUES (
    1, 'TITULAR', '2026-09-10', 'APPROVED', 'PRESENTE',
    50.00, 'PAID', '2026-09-10', 'Padres completaron charla pre-bautismal', '9'
);

-- Celebración realizada
INSERT INTO celebration (
    request_id, church_id, event_date, event_time, status, tenant_id
) VALUES (
    1, '550e8400-e29b-41d4-a716-446655440000', '2026-10-05', '11:00:00', 'COMPLETED', 9
);

-- Certificado firmado
INSERT INTO certificate (
    id, tenant_id, request_id, celebration_id, certificate_type, 
    main_person_id, main_person_name, certificate_data,
    certificate_number, book, folio, signed, signed_at, signed_by_user_id,
    copies_issued, last_copy_date, issued_at
) VALUES (
    1, 9, 1, 1, 'BAPTISM',
    35, 'Juan Pérez García',
    '{
        "beneficiario": {
            "id": 35,
            "nombre": "Juan Pérez García",
            "fechaNacimiento": "2026-05-10",
            "lugarNacimiento": "Lima, Perú"
        },
        "padres": {
            "padre": {"id": 32, "nombre": "Carlos Pérez López"},
            "madre": {"id": 37, "nombre": "María García Torres"}
        },
        "padrinos": {
            "padrino": {"id": 35, "nombre": "José López Ramírez"},
            "madrina": {"id": 32, "nombre": "Ana Torres Sánchez"}
        },
        "celebracion": {
            "fecha": "2026-10-05",
            "hora": "11:00",
            "iglesia": "Parroquia San Pedro Apóstol",
            "ministro": "Pbro. Luis Rodríguez"
        }
    }',
    'B-2026-00123', 'Libro 5', '45', TRUE, '2026-10-06 15:30:00', 32,
    1, '2026-10-07 09:00:00', '2026-10-06 15:30:00'
);

-- ───────────────────────────────────────────────────────────────────────────
-- 4.2. ESCENARIO 2: Matrimonio con fecha deseada
-- ───────────────────────────────────────────────────────────────────────────

-- Solicitud de matrimonio (scheduled_date = '2026-12-20' porque novios pidieron esa fecha)
INSERT INTO services (
    id, tenant_id, user_id, service_type_id, church_id, description, 
    scheduled_date, status, request_date, created_at
) VALUES (
    2, 9, 35, 3, 1, 'Solicitud de matrimonio - Pedro Gómez y Laura Martínez',
    '2026-12-20', 'IN_PROGRESS', '2026-09-01 14:30:00', '2026-09-01 14:30:00'
);

-- Participantes del matrimonio
INSERT INTO service_participants (tenant_id, service_id, user_id, role, created_at) VALUES
(9, 2, 35, 'GROOM', '2026-09-01 14:35:00'),         -- Novio
(9, 2, 37, 'BRIDE', '2026-09-01 14:35:00'),          -- Novia
(9, 2, 32, 'GROOMS_FATHER', '2026-09-01 14:35:00'), -- Padre del novio
(9, 2, 35, 'GROOMS_MOTHER', '2026-09-01 14:35:00'), -- Madre del novio
(9, 2, 37, 'BRIDES_FATHER', '2026-09-01 14:35:00'), -- Padre de la novia
(9, 2, 32, 'BRIDES_MOTHER', '2026-09-01 14:35:00'); -- Madre de la novia

-- Preparación en progreso
INSERT INTO preparation (
    request_id, type, session_date, status, attendance_status, 
    payment_amount, payment_status, notes, tenant_id
) VALUES (
    2, 'TITULAR', '2026-11-15', 'PENDING', NULL,
    80.00, 'PENDING', 'Curso pre-matrimonial programado', '9'
);

-- ───────────────────────────────────────────────────────────────────────────
-- 4.3. ESCENARIO 3: Confirmación sin fecha deseada
-- ───────────────────────────────────────────────────────────────────────────

-- Solicitud de confirmación (scheduled_date = NULL, se asigna después)
INSERT INTO services (
    id, tenant_id, user_id, service_type_id, church_id, description, 
    scheduled_date, status, request_date, created_at
) VALUES (
    3, 9, 37, 2, 1, 'Solicitud de confirmación para Andrea Sánchez',
    NULL, 'APPROVED', '2026-09-20 09:00:00', '2026-09-20 09:00:00'
);

-- Participantes de confirmación
INSERT INTO service_participants (tenant_id, service_id, user_id, role, created_at) VALUES
(9, 3, 37, 'CONFIRMED', '2026-09-20 09:05:00'),   -- Confirmando
(9, 3, 32, 'FATHER', '2026-09-20 09:05:00'),      -- Padre
(9, 3, 35, 'MOTHER', '2026-09-20 09:05:00'),      -- Madre
(9, 3, 37, 'GODPARENT', '2026-09-20 09:05:00');   -- Padrino/a

-- ───────────────────────────────────────────────────────────────────────────
-- 4.4. ESCENARIO 4: Misa especial con fecha deseada
-- ───────────────────────────────────────────────────────────────────────────

INSERT INTO services (
    id, tenant_id, user_id, service_type_id, church_id, description, 
    scheduled_date, status, request_date, created_at
) VALUES (
    4, 9, 32, 4, 1, 'Misa de difuntos - Intención: Padre fallecido',
    '2026-11-02', 'APPROVED', '2026-10-10 16:00:00', '2026-10-10 16:00:00'
);

-- ───────────────────────────────────────────────────────────────────────────
-- 4.5. ESCENARIO 5: Solicitud de acta (BOOKS) con fecha límite
-- ───────────────────────────────────────────────────────────────────────────

INSERT INTO services (
    id, tenant_id, user_id, service_type_id, description, 
    scheduled_date, status, request_date, created_at
) VALUES (
    5, 9, 35, 5, 'Solicitud de acta de bautismo para trámite de pasaporte',
    '2026-10-30', 'PENDING', '2026-10-12 10:00:00', '2026-10-12 10:00:00'
);

-- ═══════════════════════════════════════════════════════════════════════════
-- PASO 5: RESETEAR SECUENCIAS
-- ═══════════════════════════════════════════════════════════════════════════

SELECT setval('service_types_id_seq', (SELECT MAX(id) FROM service_types));
SELECT setval('services_id_seq', (SELECT MAX(id) FROM services));
SELECT setval('service_participants_id_seq', (SELECT MAX(id) FROM service_participants));
SELECT setval('preparation_id_seq', (SELECT MAX(id) FROM preparation));
SELECT setval('celebration_id_seq', (SELECT MAX(id) FROM celebration));
SELECT setval('certificate_id_seq', (SELECT MAX(id) FROM certificate));

-- ═══════════════════════════════════════════════════════════════════════════
-- PASO 6: VERIFICACIÓN
-- ═══════════════════════════════════════════════════════════════════════════

-- Ver tipos de servicio
SELECT * FROM service_types ORDER BY id;

-- Ver solicitudes con su tipo
SELECT 
    s.id,
    s.status,
    st.name AS tipo_servicio,
    s.scheduled_date AS fecha_deseada,
    s.certificate_id,
    s.response_data
FROM services s
INNER JOIN service_types st ON s.service_type_id = st.id
ORDER BY s.id;

-- Ver participantes por servicio
SELECT 
    s.id AS solicitud_id,
    st.name AS tipo_servicio,
    sp.user_id,
    sp.role
FROM services s
INNER JOIN service_types st ON s.service_type_id = st.id
INNER JOIN service_participants sp ON s.id = sp.service_id
ORDER BY s.id, sp.role;

-- Ver certificados emitidos
SELECT 
    c.id,
    c.certificate_type,
    c.main_person_name,
    c.certificate_number,
    c.book,
    c.folio,
    c.signed,
    c.copies_issued
FROM certificate c
WHERE c.signed = TRUE
ORDER BY c.id;

-- ═══════════════════════════════════════════════════════════════════════════
-- FIN DEL SCRIPT
-- ═══════════════════════════════════════════════════════════════════════════

-- NOTAS IMPORTANTES:
-- 1. scheduled_date es NULL para BAUTISMO/CONFIRMACIÓN (se asigna después en celebration)
-- 2. scheduled_date tiene valor para MATRIMONIO/MISA/BOOKS (fecha deseada o límite)
-- 3. certificate_id y response_data solo se llenan cuando status = 'COMPLETED'
-- 4. Los user_id en los ejemplos (101, 201, etc) deben existir en ms-users
-- 5. Los church_id deben existir en ms-churches (Kevin's microservice)

