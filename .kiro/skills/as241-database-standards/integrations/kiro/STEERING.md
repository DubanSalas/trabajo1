---
inclusion: always
---

# Contexto Kiro — PRS241 DatabaseStorage

Este archivo es una referencia de integración. La fuente canónica de la skill,
incluido este contexto, reside en `skills/as241-database-standards/`.

## Auditoría

Ejecuta el auditor desde la raíz del repositorio:

```powershell
python skills/as241-database-standards/scripts/ai_standards_auditor.py `
  --all --root . --output PRS241_Reporte_TODOS.xlsx
```

Para una auditoría formal, primero lee el código y genera un `findings.json`
por microservicio según `SKILL.md`; luego genera el Excel con `--findings`.

## Recomendaciones

Todo hallazgo `NO_CUMPLE` u `OBSERVADO` debe explicar el cambio de
implementación con código Java, YAML, XML o SQL cuando corresponda. No usar
recomendaciones genéricas como “revisar”, “corregir” o “ejecutar”.

Los patrones base se encuentran en `scripts/ai_standards_auditor.py` bajo
`REMEDIATIONS`; deben adaptarse al nombre real del agregado y a la evidencia
del microservicio.
