-- ═════════════════════════════════════════════════════════════════════════════
-- DATOS DE PRUEBA PARA TENANT 9 - USER 32
-- Sistema FideInexus - Gestión Parroquial
-- ═════════════════════════════════════════════════════════════════════════════
-- PROPOSITO: Datos de prueba simplificados para tenant_id=9, user_id=32
-- ═════════════════════════════════════════════════════════════════════════════

-- ═════════════════════════════════════════════════════════════════════════════
-- PASO 1: SERVICES (vg-ms-servicesservice)
-- ═════════════════════════════════════════════════════════════════════════════

-- Catálogo de tipos de servicio (si no existe)
INSERT INTO service_types (code, name, description, active)
VALUES
    ('BAPTISM', 'Bautismo', 'Sacramento del Bautismo', TRUE),
    ('CONFIRMATION', 'Confirmación', 'Sacramento de la Confirmación', TRUE),
    ('MARRIAGE', 'Matrimonio', 'Sacramento del Matrimonio', TRUE),
    ('MASS', 'Misa Especial', 'Solicitud de misa especial', TRUE)
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    active = EXCLUDED.active,
    updated_at = NOW();

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICE 1: BAUTISMO (PENDING) - User 32 como CHILD
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO services (tenant_id, service_type_id, description, scheduled_date, status, request_date)
SELECT 9, st.id, 'Bautismo de prueba - Usuario 32', '2024-11-15', 'PENDING', '2024-10-19 10:00:00'
FROM service_types st WHERE st.code = 'BAPTISM';

INSERT INTO service_participants (tenant_id, service_id, user_id, role)
VALUES (9, 1, 32, 'CHILD');

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICE 2: CONFIRMACIÓN (APPROVED) - User 32 como CONFIRMED
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO services (tenant_id, service_type_id, description, scheduled_date, status, request_date)
SELECT 9, st.id, 'Confirmación de prueba - Usuario 32', '2024-12-01', 'APPROVED', '2024-10-19 11:00:00'
FROM service_types st WHERE st.code = 'CONFIRMATION';

INSERT INTO service_participants (tenant_id, service_id, user_id, role)
VALUES (9, 2, 32, 'CONFIRMED');

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICE 3: MATRIMONIO (PENDING) - User 32 como GROOM
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO services (tenant_id, service_type_id, description, scheduled_date, status, request_date)
SELECT 9, st.id, 'Matrimonio de prueba - Usuario 32', '2024-11-30', 'PENDING', '2024-10-19 12:00:00'
FROM service_types st WHERE st.code = 'MARRIAGE';

INSERT INTO service_participants (tenant_id, service_id, user_id, role)
VALUES (9, 3, 32, 'GROOM');

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICE 4: MISA ESPECIAL (APPROVED) - User 32 como TITULAR
-- ⚠️ AJUSTAR church_id con UUID real de tu base de datos
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO services (tenant_id, service_type_id, church_id, description, scheduled_date, status, request_date)
SELECT 9, st.id, '550e8400-e29b-41d4-a716-446655440001'::UUID, 
       'Misa de Difuntos - Usuario 32', '2024-11-02', 'APPROVED', '2024-10-19 13:00:00'
FROM service_types st WHERE st.code = 'MASS';

INSERT INTO service_participants (tenant_id, service_id, user_id, role)
VALUES (9, 4, 32, 'TITULAR');

-- ═════════════════════════════════════════════════════════════════════════════
-- PASO 2: PREPARATION (vg-ms-preparationservice)
-- ═════════════════════════════════════════════════════════════════════════════

-- Preparación para BAUTISMO (service_id = 1)
INSERT INTO preparation (tenant_id, service_id, type, session_date, status, attendance_status, notes)
VALUES
    (9, 1, 'TITULAR', '2024-10-20', 'COMPLETED', 'PRESENT', 
     'Sesión de preparación completada.');

-- Preparación para CONFIRMACIÓN (service_id = 2)
INSERT INTO preparation (tenant_id, service_id, type, session_date, status, attendance_status, exam_score, exam_passed, notes)
VALUES
    (9, 2, 'TITULAR', '2024-10-05', 'COMPLETED', 'PRESENT', 85, TRUE, 
     'Examen aprobado con buena nota.'),
    (9, 2, 'TITULAR', '2024-10-12', 'COMPLETED', 'PRESENT', 92, TRUE, 
     'Segunda sesión completada exitosamente.');

-- Preparación para MATRIMONIO (service_id = 3)
INSERT INTO preparation (tenant_id, service_id, type, session_date, status, attendance_status, notes)
VALUES
    (9, 3, 'TITULAR', '2024-10-08', 'COMPLETED', 'PRESENT',
     'Sesión 1: Fundamentos del matrimonio cristiano.'),
    (9, 3, 'TITULAR', '2024-10-15', 'COMPLETED', 'PRESENT',
     'Sesión 2: Comunicación y resolución de conflictos.');

-- ═════════════════════════════════════════════════════════════════════════════
-- PASO 3: CELEBRATION (vg-ms-celebrationservice)
-- ═════════════════════════════════════════════════════════════════════════════
-- ⚠️ IMPORTANTE: Reemplazar los UUIDs con church_id reales de tu base de datos
-- Ejecutar primero: SELECT id, name FROM churches WHERE tenant_id = 9 AND active = true;

-- Celebración para BAUTISMO (service_id = 1)
INSERT INTO celebration (service_id, church_id, event_date, event_time, status, tenant_id)
VALUES (1, '550e8400-e29b-41d4-a716-446655440001'::UUID, '2024-11-15', '10:00:00', 'SCHEDULED', 9);

-- Celebración para CONFIRMACIÓN (service_id = 2)
INSERT INTO celebration (service_id, church_id, event_date, event_time, status, tenant_id)
VALUES (2, '550e8400-e29b-41d4-a716-446655440001'::UUID, '2024-12-01', '16:00:00', 'SCHEDULED', 9);

-- Celebración para MATRIMONIO (service_id = 3)
INSERT INTO celebration (service_id, church_id, event_date, event_time, status, tenant_id)
VALUES (3, '550e8400-e29b-41d4-a716-446655440001'::UUID, '2024-11-30', '18:00:00', 'SCHEDULED', 9);

-- Celebración para MISA ESPECIAL (service_id = 4)
INSERT INTO celebration (service_id, church_id, event_date, event_time, status, tenant_id)
VALUES (4, '550e8400-e29b-41d4-a716-446655440001'::UUID, '2024-11-02', '09:00:00', 'SCHEDULED', 9);

-- ═════════════════════════════════════════════════════════════════════════════
-- PASO 4: CERTIFICATE (vg-ms-certificateservice) - OPCIONAL
-- ═════════════════════════════════════════════════════════════════════════════
-- Estos se generan automáticamente cuando la celebración se marca como REALIZED
-- Puedes crear uno manualmente para pruebas:

INSERT INTO certificate (
    tenant_id, service_id, celebration_id, certificate_type, certificate_number, book, folio,
    main_person_id, main_person_name, certificate_data, signed, issued_at
)
VALUES (
    9, 2, 2, 'CONFIRMATION', 'CONF-2024-TEST', 'Libro II', '001',
    32, 'Usuario de Prueba',
    '{
       "confirmedName": "Usuario de Prueba",
       "confirmationDate": "2024-12-01"
     }',
    FALSE, NOW()
);

-- ═════════════════════════════════════════════════════════════════════════════
-- VERIFICACIÓN DE DATOS
-- ═════════════════════════════════════════════════════════════════════════════
-- Ejecutar estas queries para verificar:

-- SELECT * FROM services WHERE tenant_id = 9;
-- SELECT * FROM service_participants WHERE tenant_id = 9;
-- SELECT * FROM preparation WHERE tenant_id = '9';
-- SELECT * FROM celebration WHERE tenant_id = 9;
-- SELECT * FROM certificate WHERE tenant_id = 9;

-- ═════════════════════════════════════════════════════════════════════════════
-- NOTAS IMPORTANTES
-- ═════════════════════════════════════════════════════════════════════════════
-- 1. tenant_id = 9 (debe existir en vg-ms-organizationservice)
-- 2. user_id = 32 (único feligrés disponible en tenant 9)
-- 3. church_id: Reemplazar '550e8400-e29b-41d4-a716-446655440001' con UUID real
-- 4. Los service_id empiezan en 1 (ajustar si ya hay datos en la BD)
-- 5. Los celebration_id empiezan en 1 (ajustar según corresponda)
-- ═════════════════════════════════════════════════════════════════════════════
