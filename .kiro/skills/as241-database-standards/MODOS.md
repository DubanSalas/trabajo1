# Modos de Generación del Reporte PRS241

---

## Modo 1 — Sin agente (Regex Fallback)

**Cuándo usarlo:** En el pipeline de GitLab CI, en la VPS, o cuando no tienes Kiro disponible.

**Qué hace:** El script escanea el código fuente con expresiones regulares y detecta si cada criterio cumple o no. No requiere intervención humana ni agente de IA.

**Alcance:** El script agrega una línea sugerida y un patrón de implementación
con código para cada incumplimiento. Es una guía base: se debe adaptar el
nombre del agregado, paquete y campos al microservicio auditado.

**Comando:**
```bash
python skills/as241-database-standards/scripts/ai_standards_auditor.py \
  --dirs ../vg-ms-alertas ../vg-ms-castigos \
  --output reporte_cumplimiento_prs241_YYYYMMDD_HHMM.xlsx
```

### Auditoria global

Para auditar todos los microservicios que comienzan con `vg-ms-` en una misma
carpeta, no hace falta enumerarlos uno por uno:

```bash
python skills/as241-database-standards/scripts/ai_standards_auditor.py \
  --all --root . \
  --output PRS241_Reporte_TODOS.xlsx
```

`--root .` significa "desde la carpeta actual". El buscador solo toma los
directorios inmediatos `vg-ms-*`, por lo que no analiza directorios de ejemplo,
dependencias o submodulos por accidente. `--all` y `--dirs` son excluyentes.

---

## Modo 2 — Con agente Kiro (findings.json)

**Cuándo usarlo:** Cuando necesitas un reporte detallado con evidencia real — para una evaluación, revisión de PRS, o auditoría formal.

**Qué hace:** Kiro lee el código fuente real, evalúa cada criterio con evidencia concreta (archivo, línea exacta, contenido actual) y genera un `findings.json`. Luego el script convierte ese JSON en el Excel con todos los campos completos.

**Resultado:** El Excel incluye Ubicación, Problema hallado y línea, Línea sugerida, Recomendación y Qué se logra al cumplir — todo con evidencia real.

**Paso 1 — Pedir a Kiro que analice:**
```
"Analiza vg-ms-castigos y genera el findings.json con el estándar PRS241"
```

**Paso 2 — Generar el Excel:**
```bash
python skills/as241-database-standards/scripts/ai_standards_auditor.py \
  --findings vg-ms-castigos/findings.json \
  --output reporte_cumplimiento_prs241_YYYYMMDD_HHMM.xlsx
```

---

## Comparación

| | Modo 1 (Regex) | Modo 2 (Kiro findings.json) |
|---|---|---|
| Requiere Kiro | No | Sí |
| Corre en pipeline | Sí | No |
| Ubicación | ✅ | ✅ |
| Problema hallado y línea | Parcial | ✅ Completo |
| Línea sugerida | ✅ Patrón base | ✅ Específica a la evidencia |
| Recomendación | ✅ Con código base | ✅ Con código y contexto real |
| Qué se logra | ✅ | ✅ |
| Velocidad | Rápido | Más lento (Kiro lee el código) |

---

## Archivos del skill

| Archivo | Descripción |
|---|---|
| `SKILL.md` | Instrucciones para Kiro — cómo analizar y generar el findings.json |
| `checklist.md` | Los 17 criterios oficiales del estándar PRS241 |
| `MODOS.md` | Este archivo — explica los dos modos de generación del reporte |
| `scripts/ai_standards_auditor.py` | Script Python que genera el Excel |
