# Reporte Consolidado de Estándares PRS241 - Módulo de Solicitudes

## Fecha: 23 de octubre de 2026
## Microservicios evaluados: 4 (requests, preparation, celebration, certificate)

---

## 1. Perfil de Estándares (run_standards.py - 5 checkers oficiales)

| Microservicio | Arquitectura | BD | Backend | Seguridad | Reportes PRS3 | Perfil |
|---|---|---|---|---|---|---|
| vg-ms-requests | 100.0% APROBADO | 100.0% APROBADO | 100.0% CUMPLE | 97.7% OBSERVADO | 100.0% APROBADO | 100/100/100/97.7/100 |
| vg-ms-preparation | 100.0% APROBADO | 100.0% APROBADO | 100.0% CUMPLE | 97.7% OBSERVADO | 100.0% APROBADO | 100/100/100/97.7/100 |
| vg-ms-celebration | 100.0% APROBADO | 100.0% APROBADO | 100.0% CUMPLE | 97.7% OBSERVADO | 100.0% APROBADO | 100/100/100/97.7/100 |
| vg-ms-certificate | 100.0% APROBADO | 100.0% APROBADO | 100.0% CUMPLE | 97.7% OBSERVADO | 100.0% APROBADO | 100/100/100/97.7/100 |

**Referencia (vg-ms-organizationservice):** 100/100/100/97.7/100

**Conclusión:** Los 4 microservicios alcanzan el perfil objetivo exacto de `vg-ms-organizationservice`.

---

## 2. Revisión de Arquitectura (architecture_checker.py - estándar PRS241 v4)

| Microservicio | Resultado | Cumple | No cumple | No aplica | Revisión manual |
|---|---|---|---|---|---|
| vg-ms-requests | APROBADO (100.0%) | 38 | 0 | 1 | 4 |
| vg-ms-preparation | APROBADO (100.0%) | 38 | 0 | 1 | 4 |
| vg-ms-celebration | APROBADO (100.0%) | 38 | 0 | 1 | 4 |
| vg-ms-certificate | APROBADO (100.0%) | 37 | 0 | 2 | 4 |

**Conclusión:** Los 4 microservicios tienen 100% APROBADO en el checker de arquitectura.

---

## 3. Pruebas Unitarias (mvn -o clean test)

| Microservicio | Pruebas | Fallos | Errores | BUILD |
|---|---|---|---|---|
| vg-ms-requestsservice | 23 | 0 | 0 | SUCCESS |
| vg-ms-preparationservice | 30 | 0 | 0 | SUCCESS |
| vg-ms-celebrationservice | 20 | 0 | 0 | SUCCESS |
| vg-ms-certificateservice | 21 | 0 | 0 | SUCCESS |

**Total pruebas:** 94 (todas pasando)

---

## 4. Única observación residual (SEC-003)

Los 4 microservicios tienen **97.7% en Seguridad** por una sola regla:

- **SEC-003 (PARCIAL):** Los clientes de Keycloak (`prs-frontend` y `fideiNexus`) mantienen *Direct Access Grants* y aceptan *cualquier redirect URI*.
- Esta observación es **idéntica a la de `vg-ms-organizationservice`**.
- Está cubierta con `findings.json` de revisión manual (2026-10-22) en el kit para los 4 servicios.
- **No se puede corregir desde el código del microservicio** (depende de la configuración de Keycloak en PRS-GATEWAY).

---

## 5. Archivos generados

### Reportes de estándares (run_standards.py)
- `estandares-requests/` → 5 archivos JSON + XLSX + resumen
- `estandares-preparation/` → 5 archivos JSON + XLSX + resumen
- `estandares-celebration/` → 5 archivos JSON + XLSX + resumen
- `estandares-certificate/` → 5 archivos JSON + XLSX + resumen

### Reportes de arquitectura (architecture_checker.py)
- `vg-ms-requestsservice-hexagonal/report.json` + `report.xlsx`
- `vg-ms-celebrationservice-hexagonal/report.json` + `report.xlsx`
- `vg-ms-certificateservice-hexagonal/report.json` + `report.xlsx`

### Revisiones manuales de seguridad (findings.json)
- `quality-kit/servicios/vg-ms-requests/reportes/security/findings.json`
- `quality-kit/servicios/vg-ms-preparation/reportes/security/findings.json`
- `quality-kit/servicios/vg-ms-celebration/reportes/security/findings.json`
- `quality-kit/servicios/vg-ms-certificate/reportes/security/findings.json`

---

## 6. Resumen ejecutivo

| Aspecto | Estado |
|---------|--------|
| Perfil estándares (5 checkers) | ✅ 100/100/100/97.7/100 en los 4 micros |
| Arquitectura PRS241 (81 criterios) | ✅ 100% APROBADO en los 4 micros |
| Pruebas unitarias | ✅ 94 pruebas pasando (23+30+20+21) |
| Dependencias bloqueantes | ✅ Eliminadas (spring-webflux + reactor-netty) |
| CORS por variable de entorno | ✅ Configurado |
| Soft delete documentado | ✅ Implementado |
| Puertos con tenant explícito (SEC-009) | ✅ Implementado |
| Tenant isolation (SEC-010/020) | ✅ Implementado y testeado |
| SEC-003 (Keycloak) | ⚠️ PARCIAL (igual que organization, externo al código) |
| Estructura de carpetas vacías | ✅ Creadas |
| .gitlab-ci.yml con standards-check | ✅ Presente en los 4 |
| .gitlab-ci.yml con test/sonar/notify | ✅ Presente en los 3 (requests, celebration, certificate) |
| JMeter (.jmx) | ✅ Creado en los 3 |
| SonarQube en pom.xml | ✅ Configurado en los 3 |
| Slack notifications | ✅ Job creado (falta webhook real) |

---

## Conclusión

Los 4 microservicios backend del módulo de Solicitudes (`vg-ms-requests`, `vg-ms-preparation`, `vg-ms-celebration`, `vg-ms-certificate`) cumplen el **perfil objetivo exacto** de `vg-ms-organizationservice` (100/100/100/97.7/100) en todos los checkers oficiales del kit `vg-ms-eventservice:codex/standards-kit`.

La única observación residual (SEC-003 PARCIAL) es idéntica a la de `organization` y depende de la configuración de Keycloak en PRS-GATEWAY, no del código del microservicio.

**El backend está listo para el commit manual del usuario.** El frontend se adapta después (push manual del usuario), según lo acordado.
