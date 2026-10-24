---
name: as241-database-standards
description: >-
  Audits Java/Spring microservices against the PRS241 DatabaseStorage standard
  (Hexagonal + DDD + Reactive). Reads real source code to produce a detailed
  findings.json with exact file paths, line numbers, and evidence, then generates
  an Excel compliance report. Use when the user mentions PRS241, hexagonal, DDD,
  checklist, reporte de cumplimiento, findings, or auditar microservicio.
---

# PRS241 · Estándares DatabaseStorage (Hexagonal + DDD + Reactivo)

Verifica que cualquier microservicio `vg-ms-*` cumpla el **Checklist de Control y Auditoría PRS241**
(17 criterios, 5 categorías) leyendo el código fuente real y produciendo evidencia verificable.

Detalle de criterios: [checklist.md](checklist.md)

---

## Flujo obligatorio

```
Modo 1 — Kiro lee el código → genera findings.json
                ↓
Modo 2 — Script toma findings.json → genera Excel
```

Nunca saltes al Modo 2 sin haber ejecutado el Modo 1 primero.

---

## Modo 1 — Análisis y generación de findings.json

### Principios inquebrantables

1. **Evidencia o no existe.** Nunca marques CUMPLE sin haber leído el archivo y la línea concreta.
2. **No inventes rutas ni líneas.** Si no puedes verificarlo, márcalo como `OBSERVADO` y explica por qué.
3. **No modifiques el proyecto.** Solo lees. Prohibido editar código o crear archivos fuera de `findings.json`.
4. **Rutas completas siempre.** Incluye el nombre del microservicio en cada ruta: `vg-ms-castigos/src/main/java/...`

### Procedimiento

**Paso 1 — Localizar el microservicio**

Busca el directorio `vg-ms-*` indicado por el usuario. Si pide auditar todos, localiza todos los directorios `vg-ms-*` disponibles en el workspace y audítalos uno a uno.

**Paso 2 — Leer los archivos clave**

Para cada microservicio lee:
- `pom.xml` — dependencias
- Todos los `.java` en `src/main/java/` — modelos, repositorios, adaptadores, mappers, servicios
- `src/main/resources/application.yml` o `application.yaml` — configuración y credenciales

**Paso 3 — Evaluar los 17 criterios**

Para cada criterio del [checklist.md](checklist.md) determina:

| Estado | Cuándo usarlo |
|---|---|
| `CUMPLE` | Evidencia concreta y verificada de cumplimiento total |
| `OBSERVADO` | Cumple parcialmente o no se puede verificar del todo |
| `NO_CUMPLE` | Evidencia concreta de violación |

**Paso 4 — Construir el findings.json**

Escribe el archivo en `{microservicio}/findings.json` con este esquema EXACTO:

```json
{
  "proyecto": "vg-ms-nombre",
  "fecha": "yyyy-mm-dd",
  "auditor": "Kiro — as241-database-standards",
  "dictamen": "APROBADO | OBSERVADO | NO CUMPLE",
  "resumen": {
    "cumple": 0,
    "observado": 0,
    "no_cumple": 0,
    "total": 17,
    "porcentaje": 0.0
  },
  "criterios": [
    {
      "id": "HEX-01",
      "categoria": "Arquitectura Hexagonal y DDD",
      "nombre": "POJO puro en domain.model sin anotaciones de persistencia",
      "severidad": "CRÍTICA",
      "estado": "NO_CUMPLE",
      "archivos_evaluados": [
        "vg-ms-castigos/src/main/java/vg_ms/castigos/model/Castigo.java",
        "vg-ms-castigos/src/main/java/vg_ms/castigos/model/TipoCastigo.java"
      ],
      "evidencia": [
        {
          "archivo": "vg-ms-castigos/src/main/java/vg_ms/castigos/model/Castigo.java",
          "linea": 12,
          "contenido_actual": "@Document(collection = \"castigos\")",
          "problema": "Anotación @Document en modelo de dominio — viola el aislamiento DDD",
          "linea_sugerida": "Eliminar @Document. Moverlo a CastigoDocument.java en infrastructure/adapter/out/persistence/",
          "que_se_logra": "El dominio queda libre de dependencias técnicas. Se puede cambiar MongoDB por otra BD sin tocar el modelo de negocio."
        }
      ],
      "recomendacion": "Crear CastigoDocument.java en vg-ms-castigos/src/main/java/vg_ms/castigos/infrastructure/adapter/out/persistence/ con las anotaciones @Document y @Id. El modelo Castigo.java en domain/model debe ser un POJO puro con solo atributos Java estándar."
    },
    {
      "id": "SEC-03",
      "categoria": "Seguridad y Storage Offloading",
      "nombre": "Sin credenciales en texto plano en application.yml",
      "severidad": "CRÍTICA",
      "estado": "CUMPLE",
      "archivos_evaluados": [
        "vg-ms-castigos/src/main/resources/application.yaml"
      ],
      "evidencia": [
        {
          "archivo": "vg-ms-castigos/src/main/resources/application.yaml",
          "linea": 8,
          "contenido_actual": "password: ${MONGO_PASSWORD:}",
          "cumplimiento": "La contraseña se inyecta desde variable de entorno. No hay valor en texto plano.",
          "que_se_logra": "Las credenciales no quedan expuestas en el repositorio. Cualquier persona que clone el repo no puede conectarse a la BD sin las variables de entorno del servidor."
        }
      ],
      "recomendacion": ""
    }
  ],
  "criticos_fallando": ["HEX-01", "REC-02"],
  "limitaciones": [
    "No se ejecutaron pruebas dinámicas — solo análisis estático del código fuente.",
    "La conexión TLS/SSL no fue verificada en runtime, solo en configuración."
  ]
}
```

### Reglas de validación del findings.json

- `estado` solo puede ser: `CUMPLE`, `OBSERVADO`, `NO_CUMPLE`
- `evidencia` es obligatorio en CUMPLE y NO_CUMPLE — nunca lo omitas
- Los que tienen `NO_CUMPLE` o `OBSERVADO` deben incluir `linea_sugerida` y `recomendacion`
- `recomendacion` no puede decir solo “revisar”, “corregir” o “ejecutar”. Debe
  indicar el cambio concreto e incluir un fragmento mínimo de Java, YAML, SQL
  o XML cuando aplique. Usa los patrones de `REMEDIATIONS` del auditor como
  referencia y ajusta nombres, paquetes y tipos al código que sí verificaste.
- Los que tienen `CUMPLE` deben incluir `cumplimiento` y `que_se_logra`
- `archivos_evaluados` lista todos los archivos que leíste para evaluar ese criterio
- Rutas siempre completas desde la raíz del workspace: `vg-ms-nombre/src/...`
- `criticos_fallando` lista solo los IDs con severidad CRÍTICA que no cumplen
- `dictamen` se calcula así:
  - `NO CUMPLE` → si hay al menos 1 criterio CRÍTICO en NO_CUMPLE
  - `OBSERVADO` → si hay OBSERVADO pero ningún CRÍTICO en NO_CUMPLE
  - `APROBADO` → cero críticos fallando y porcentaje ≥ 80%

### Qué no hacer

- No marcar CUMPLE sin haber leído el archivo
- No inventar rutas, líneas o contenido de código
- No reportar `.block()` en archivos de test como violación
- No escribir el valor real de contraseñas o tokens en ningún campo

---

## Modo 2 — Generación del reporte Excel

Una vez generado el `findings.json`, ejecuta el script:

**Instalar dependencia si no está:**
```bash
pip install openpyxl
```

**Para un solo microservicio:**
```bash
python skills/as241-database-standards/scripts/ai_standards_auditor.py \
  --findings {ruta}/findings.json \
  --output PRS241_Reporte_{nombre-ms}.xlsx
```

**Para todos los microservicios a la vez:**
```bash
python skills/as241-database-standards/scripts/ai_standards_auditor.py \
  --dirs {ruta-ms-1} {ruta-ms-2} ... \
  --output PRS241_Reporte_TODOS.xlsx
```

**Para descubrir todos los microservicios automáticamente:**
```bash
python skills/as241-database-standards/scripts/ai_standards_auditor.py \
  --all --root . \
  --output PRS241_Reporte_TODOS.xlsx
```

`--all` busca los directorios inmediatos cuyo nombre comienza con `vg-ms-`
dentro de `--root`. Es el modo recomendado para el pipeline Regex global.

Tras ejecutar, informa al usuario:
- Que el `.xlsx` fue generado y dónde está
- El dictamen y % de cumplimiento de cada microservicio auditado
- Los criterios CRÍTICOS que están fallando (si los hay)

---

## Dictamen

| Dictamen | Criterio |
|---|---|
| **APROBADO** | Cero críticos fallando y ≥ 80% cumple |
| **OBSERVADO** | Cero críticos fallando pero hay observaciones |
| **NO CUMPLE** | Al menos 1 criterio CRÍTICO falla |

**Criterios CRÍTICOS:** HEX-01 · REC-01 · REC-02 · REC-03 · TEN-01 · SEC-03

---

## Referencias

- [checklist.md](checklist.md) — los 17 criterios detallados
- `PRS241_standards/README.md` — estándar completo
