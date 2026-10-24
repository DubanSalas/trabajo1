-- ═════════════════════════════════════════════════════════════════════════════
-- SCRIPT MAESTRO - DATOS DE PRUEBA COMPLETOS
-- Sistema FideInexus - Gestión Parroquial
-- ═════════════════════════════════════════════════════════════════════════════
-- PROPOSITO: Cargar datos de prueba coherentes en todos los microservicios
-- ORDEN: services → preparation → celebration → certificate
-- ═════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- PRERREQUISITOS
-- ─────────────────────────────────────────────────────────────────────────────
-- Antes de ejecutar este script, asegúrate de que existan:
--
-- 1. TENANT (organización):
--    - tenant_id = 9 en vg-ms-organizationservice
--
-- 2. USUARIOS (people/users):
--    - user_id = 32 (feligrés en tenant 9)
--    - Este usuario se usará como TITULAR en todas las solicitudes
--
-- 3. IGLESIAS (churches):
--    - UUIDs válidos en vg-ms-churches para tenant_id = 9
--    - Ejecutar: SELECT id, name FROM churches WHERE tenant_id = 9 AND active = true;
--    - Reemplazar los UUIDs de ejemplo en este script con UUIDs reales
--
-- 4. SCHEMAS CREADOS:
--    - Ejecutar schema.sql de cada microservicio antes de este script
-- ─────────────────────────────────────────────────────────────────────────────

-- ═════════════════════════════════════════════════════════════════════════════
-- PASO 1: SERVICES (vg-ms-servicesservice)
-- ═════════════════════════════════════════════════════════════════════════════

-- Catálogo de tipos de servicio
INSERT INTO service_types (code, name, description, active)
VALUES
    ('BAPTISM', 'Bautismo', 'Sacramento del Bautismo', TRUE),
    ('CONFIRMATION', 'Confirmacion', 'Sacramento de la Confirmacion', TRUE),
    ('MARRIAGE', 'Matrimonio', 'Sacramento del Matrimonio', TRUE),
    ('MASS', 'Misa Especial', 'Solicitud de misa especial', TRUE)
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    active = EXCLUDED.active,
    updated_at = NOW();

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICE 1: BAUTISMO (PENDING)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO services (tenant_id, service_type_id, description, scheduled_date, status, request_date)
SELECT 1, st.id, 'Bautismo de María Fernanda López García', '2024-11-15', 'PENDING', '2024-10-15 10:30:00'
FROM service_types st WHERE st.code = 'BAPTISM';

INSERT INTO service_participants (tenant_id, service_id, user_id, role)
VALUES
    (1, 1, 1, 'CHILD'),
    (1, 1, 2, 'FATHER'),
    (1, 1, 3, 'MOTHER'),
    (1, 1, 4, 'GODFATHER'),
    (1, 1, 5, 'GODMOTHER');

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICE 2: CONFIRMACIÓN (APPROVED)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO services (tenant_id, service_type_id, description, scheduled_date, status, request_date)
SELECT 1, st.id, 'Confirmación de Juan Carlos Rodríguez Pérez', '2024-12-01', 'APPROVED', '2024-09-20 14:15:00'
FROM service_types st WHERE st.code = 'CONFIRMATION';

INSERT INTO service_participants (tenant_id, service_id, user_id, role)
VALUES
    (1, 2, 2, 'CONFIRMED'),
    (1, 2, 3, 'FATHER'),
    (1, 2, 4, 'MOTHER'),
    (1, 2, 5, 'GODPARENT');

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICE 3: MATRIMONIO (PENDING)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO services (tenant_id, service_type_id, description, scheduled_date, status, request_date)
SELECT 1, st.id, 'Matrimonio de Pedro Sánchez y Ana María Torres', '2024-11-30', 'PENDING', '2024-10-01 16:00:00'
FROM service_types st WHERE st.code = 'MARRIAGE';

INSERT INTO service_participants (tenant_id, service_id, user_id, role)
VALUES
    (1, 3, 1, 'GROOM'),
    (1, 3, 2, 'BRIDE'),
    (1, 3, 3, 'GROOMS_FATHER'),
    (1, 3, 4, 'GROOMS_MOTHER'),
    (1, 3, 5, 'BRIDES_FATHER'),
    (1, 3, 6, 'BRIDES_MOTHER'),
    (1, 3, 4, 'GODFATHER'),
    (1, 3, 5, 'GODMOTHER');

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICE 4: MISA ESPECIAL (APPROVED) - ⚠️ AJUSTAR church_id UUID
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO services (tenant_id, service_type_id, church_id, description, scheduled_date, status, request_date, document_url)
SELECT 1, st.id, '550e8400-e29b-41d4-a716-446655440001'::UUID, 
       'Misa de Difuntos - Aniversario de José Martínez', '2024-11-02', 'APPROVED', 
       '2024-10-18 09:00:00', '["https://storage.example.com/misa-difuntos-123.pdf"]'
FROM service_types st WHERE st.code = 'MASS';

INSERT INTO service_participants (tenant_id, service_id, user_id, role)
VALUES (1, 4, 6, 'TITULAR');

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICE 5: BAUTISMO (COMPLETED) - Para probar certificado emitido
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO services (tenant_id, service_type_id, description, scheduled_date, status, request_date, certificate_id)
SELECT 1, st.id, 'Bautismo de Carlos Eduardo Gómez', '2024-10-05', 'COMPLETED', '2024-09-01 11:00:00', 1
FROM service_types st WHERE st.code = 'BAPTISM';

INSERT INTO service_participants (tenant_id, service_id, user_id, role)
VALUES
    (1, 5, 1, 'CHILD'),
    (1, 5, 2, 'FATHER'),
    (1, 5, 3, 'MOTHER'),
    (1, 5, 4, 'GODFATHER');

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICE 6: CONFIRMACIÓN (REJECTED) - Para probar rechazo
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO services (tenant_id, service_type_id, description, status, request_date, response_data)
SELECT 1, st.id, 'Confirmación de Laura Beatriz Díaz', 'REJECTED', '2024-10-10 13:30:00',
       'Documentación incompleta: Falta certificado de bautismo y carta del párroco'
FROM service_types st WHERE st.code = 'CONFIRMATION';

INSERT INTO service_participants (tenant_id, service_id, user_id, role)
VALUES (1, 6, 3, 'CONFIRMED');

-- ═════════════════════════════════════════════════════════════════════════════
-- PASO 2: PREPARATION (vg-ms-preparationservice)
-- ═════════════════════════════════════════════════════════════════════════════

-- Preparación para BAUTISMO (service_id = 1)
INSERT INTO preparation (service_id, type, session_date, status, attendance_status, notes, tenant_id)
VALUES
    (1, 'TITULAR', '2024-10-20', 'COMPLETED', 'PRESENT', 
     'Padres asistieron juntos. Mostraron interés y compromiso.', '1'),
    (1, 'GODPARENT', '2024-10-22', 'COMPLETED', 'PRESENT', 
     'Padrinos completaron la sesión de preparación.', '1');

-- Preparación para CONFIRMACIÓN (service_id = 2)
INSERT INTO preparation (service_id, type, session_date, status, attendance_status, exam_score, exam_passed, notes, tenant_id)
VALUES
    (2, 'TITULAR', '2024-10-05', 'COMPLETED', 'PRESENT', 85, TRUE, 
     'Confirmando demostró buen conocimiento del catecismo.', '1'),
    (2, 'TITULAR', '2024-10-12', 'COMPLETED', 'PRESENT', 92, TRUE, 
     'Excelente participación en la sesión.', '1'),
    (2, 'GODPARENT', '2024-10-15', 'IN_PROGRESS', 'PRESENT', NULL, NULL, 
     'Padrino asistió a la primera sesión.', '1');

-- Preparación para MATRIMONIO (service_id = 3)
INSERT INTO preparation (service_id, type, session_date, status, attendance_status, notes, tenant_id)
VALUES
    (3, 'TITULAR', '2024-10-08', 'COMPLETED', 'PRESENT',
     'Sesión 1: Fundamentos del matrimonio cristiano. Ambos novios asistieron.', '1'),
    (3, 'TITULAR', '2024-10-15', 'COMPLETED', 'PRESENT',
     'Sesión 2: Comunicación y resolución de conflictos.', '1'),
    (3, 'TITULAR', '2024-10-22', 'PENDING', NULL,
     'Sesión 3: Espiritualidad conyugal y vida familiar.', '1');

-- Preparación para BAUTISMO COMPLETADO (service_id = 5)
INSERT INTO preparation (service_id, type, session_date, status, attendance_status, notes, tenant_id)
VALUES
    (5, 'TITULAR', '2024-09-15', 'COMPLETED', 'PRESENT',
     'Preparación completada satisfactoriamente.', '1'),
    (5, 'GODPARENT', '2024-09-18', 'COMPLETED', 'PRESENT',
     'Padrino completó la sesión de preparación.', '1');

-- ═════════════════════════════════════════════════════════════════════════════
-- PASO 3: CELEBRATION (vg-ms-celebrationservice)
-- ═════════════════════════════════════════════════════════════════════════════
-- ⚠️ IMPORTANTE: Reemplazar los UUIDs con church_id reales de tu base de datos

-- Celebración para BAUTISMO (service_id = 1)
INSERT INTO celebration (service_id, church_id, event_date, event_time, status, tenant_id)
VALUES (1, '550e8400-e29b-41d4-a716-446655440001'::UUID, '2024-11-15', '10:00:00', 'SCHEDULED', 1);

-- Celebración para CONFIRMACIÓN (service_id = 2)
INSERT INTO celebration (service_id, church_id, event_date, event_time, status, tenant_id)
VALUES (2, '550e8400-e29b-41d4-a716-446655440002'::UUID, '2024-12-01', '16:00:00', 'SCHEDULED', 1);

-- Celebración para MATRIMONIO (service_id = 3)
INSERT INTO celebration (service_id, church_id, event_date, event_time, status, tenant_id)
VALUES (3, '550e8400-e29b-41d4-a716-446655440001'::UUID, '2024-11-30', '18:00:00', 'SCHEDULED', 1);

-- Celebración para MISA ESPECIAL (service_id = 4)
INSERT INTO celebration (service_id, church_id, event_date, event_time, status, tenant_id)
VALUES (4, '550e8400-e29b-41d4-a716-446655440001'::UUID, '2024-11-02', '09:00:00', 'SCHEDULED', 1);

-- Celebración REALIZADA para BAUTISMO (service_id = 5)
INSERT INTO celebration (service_id, church_id, event_date, event_time, status, tenant_id)
VALUES (5, '550e8400-e29b-41d4-a716-446655440002'::UUID, '2024-10-05', '11:00:00', 'REALIZED', 1);

-- ═════════════════════════════════════════════════════════════════════════════
-- PASO 4: CERTIFICATE (vg-ms-certificateservice)
-- ═════════════════════════════════════════════════════════════════════════════

-- Certificado de BAUTISMO (service_id = 5, celebration_id = 5) - FIRMADO
INSERT INTO certificate (
    tenant_id, service_id, celebration_id, certificate_type, certificate_number, book, folio,
    main_person_id, main_person_name, certificate_data, signed, signed_at, signed_by_user_id, issued_at
)
VALUES (
    1, 5, 5, 'BAPTISM', 'BAU-2024-0123', 'Libro de Bautismos III', '045',
    1, 'Carlos Eduardo Gómez Hernández',
    '{
       "baptizedName": "Carlos Eduardo Gómez Hernández",
       "birthDate": "2024-03-15",
       "baptismDate": "2024-10-05",
       "father": "Roberto Gómez Martínez",
       "mother": "Patricia Hernández López",
       "godfather": "Luis Fernando Ruiz",
       "godmother": "María Elena Castro",
       "minister": "Pbro. Juan Pablo Ramírez",
       "church": "Parroquia San José"
     }',
    TRUE, '2024-10-05 13:00:00', 10, '2024-10-05 13:00:00'
);

-- Certificado de CONFIRMACIÓN (service_id = 2, celebration_id = 2) - PENDIENTE
INSERT INTO certificate (
    tenant_id, service_id, celebration_id, certificate_type, certificate_number, book, folio,
    main_person_id, main_person_name, certificate_data, signed, issued_at
)
VALUES (
    1, 2, 2, 'CONFIRMATION', 'CONF-2024-0087', 'Libro de Confirmaciones II', '112',
    2, 'Juan Carlos Rodríguez Pérez',
    '{
       "confirmedName": "Juan Carlos Rodríguez Pérez",
       "birthDate": "2010-05-20",
       "confirmationDate": "2024-12-01",
       "father": "Carlos Rodríguez Silva",
       "mother": "María Pérez González",
       "godparent": "Miguel Ángel Torres",
       "minister": "Mons. Francisco Gutiérrez (Obispo)",
       "church": "Catedral Metropolitana"
     }',
    FALSE, NOW()
);

-- Certificado de MATRIMONIO (service_id = 3, celebration_id = 3) - PENDIENTE
INSERT INTO certificate (
    tenant_id, service_id, celebration_id, certificate_type, certificate_number, book, folio,
    main_person_id, main_person_name, certificate_data, signed, issued_at
)
VALUES (
    1, 3, 3, 'MARRIAGE', 'MAT-2024-0056', 'Libro de Matrimonios V', '089',
    1, 'Pedro Sánchez López',
    '{
       "groomName": "Pedro Sánchez López",
       "groomBirthDate": "1995-08-10",
       "brideName": "Ana María Torres Vega",
       "brideBirthDate": "1997-02-14",
       "marriageDate": "2024-11-30",
       "groomParents": {
         "father": "José Sánchez Ruiz",
         "mother": "Carmen López Díaz"
       },
       "brideParents": {
         "father": "Antonio Torres Medina",
         "mother": "Rosa Vega Morales"
       },
       "godfather": "Ricardo Gómez Herrera",
       "godmother": "Lucía Fernández Ríos",
       "minister": "Pbro. Miguel Ángel Castro",
       "church": "Parroquia Sagrada Familia"
     }',
    FALSE, NOW()
);

-- ═════════════════════════════════════════════════════════════════════════════
-- VERIFICACIÓN DE DATOS
-- ═════════════════════════════════════════════════════════════════════════════
-- Ejecutar estas queries para verificar que los datos se cargaron correctamente:
--
-- SELECT * FROM services ORDER BY id;
-- SELECT * FROM service_participants ORDER BY service_id, id;
-- SELECT * FROM preparation ORDER BY service_id, session_date;
-- SELECT * FROM celebration ORDER BY service_id;
-- SELECT * FROM certificate ORDER BY service_id;
--
-- Verificar conteos:
-- SELECT 'services' AS tabla, COUNT(*) AS registros FROM services
-- UNION ALL
-- SELECT 'service_participants', COUNT(*) FROM service_participants
-- UNION ALL
-- SELECT 'preparation', COUNT(*) FROM preparation
-- UNION ALL
-- SELECT 'celebration', COUNT(*) FROM celebration
-- UNION ALL
-- SELECT 'certificate', COUNT(*) FROM certificate;
-- ═════════════════════════════════════════════════════════════════════════════
