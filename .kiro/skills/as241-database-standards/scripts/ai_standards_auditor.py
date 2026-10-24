#!/usr/bin/env python3
"""
==============================================================================
 Agente de IA Verificador de Estandares PRS - DatabaseStorage
 Estandar: Hexagonal + DDD + Reactivo (PRS241)

 Modos de uso:
   1. Desde findings.json (analisis hecho por Kiro - mas preciso):
      python ai_standards_auditor.py --findings vg-ms-x/findings.json --output reporte.xlsx

   2. Desde directorios (analisis por regex - fallback):
      python ai_standards_auditor.py --dirs ./vg-ms-x --output reporte.xlsx
      python ai_standards_auditor.py --dirs ./vg-ms-x ./vg-ms-y --output reporte.xlsx

   3. Todos los microservicios de una raiz (analisis por regex - fallback):
      python ai_standards_auditor.py --all --root . --output PRS241_Reporte_TODOS.xlsx
==============================================================================
"""

import os
import re
import sys
import json
import argparse
import smtplib
from datetime import datetime, timezone
from email import encoders
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

try:
    import openpyxl
    from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
    from openpyxl.utils import get_column_letter
except ImportError:
    print("[ERROR] Falta openpyxl. Ejecuta: pip install openpyxl")
    sys.exit(1)


# ==============================================================================
# CRITERIOS OFICIALES DEL CHECKLIST PRS (17 criterios)
# ==============================================================================
RULES = [
    {"id": "HEX-01", "cat": "Arquitectura Hexagonal y DDD",
     "name": "Modelos de dominio POJO puro (sin @Table/@Document/@Id/@Column)",
     "severity": "CRITICA",
     "logro": "El dominio queda libre de dependencias tecnicas. Se puede cambiar la BD sin tocar el modelo de negocio."},
    {"id": "HEX-02", "cat": "Arquitectura Hexagonal y DDD",
     "name": "Capa de servicio depende solo de puertos (interfaces RepositoryPort)",
     "severity": "ALTA",
     "logro": "La logica de negocio no conoce Spring Data ni MongoDB. Se puede reemplazar la persistencia sin modificar el servicio."},
    {"id": "HEX-03", "cat": "Arquitectura Hexagonal y DDD",
     "name": "Entidades y repositorios Spring Data aislados en infrastructure/persistence",
     "severity": "ALTA",
     "logro": "La infraestructura tecnica esta contenida. Cambiar de MongoDB a PostgreSQL solo requiere modificar el adaptador."},
    {"id": "HEX-04", "cat": "Arquitectura Hexagonal y DDD",
     "name": "Mappers bidireccionales entre Model y Entity/Document",
     "severity": "MEDIA",
     "logro": "Las entidades de BD nunca se filtran al dominio ni a la API. El contrato del dominio permanece estable."},
    {"id": "REC-01", "cat": "Stack Reactivo No Bloqueante",
     "name": "Sin dependencias JDBC/JPA bloqueantes en pom.xml",
     "severity": "CRITICA",
     "logro": "El microservicio no bloquea hilos en operaciones de BD. Soporta alta concurrencia sin saturar el servidor."},
    {"id": "REC-02", "cat": "Stack Reactivo No Bloqueante",
     "name": "Usa spring-data-mongodb-reactive o r2dbc + webflux en pom.xml",
     "severity": "CRITICA",
     "logro": "El stack completo es reactivo no bloqueante. Permite procesar miles de peticiones simultaneas."},
    {"id": "REC-03", "cat": "Stack Reactivo No Bloqueante",
     "name": "Repositorios extienden ReactiveMongoRepository / ReactiveCrudRepository",
     "severity": "CRITICA",
     "logro": "Todas las operaciones de BD retornan Mono/Flux. No hay bloqueo en ninguna capa de persistencia."},
    {"id": "REC-04", "cat": "Stack Reactivo No Bloqueante",
     "name": "Cero uso de .block() / .toStream() fuera de tests",
     "severity": "CRITICA",
     "logro": "El flujo reactivo no se interrumpe. Se evitan deadlocks y saturacion del event loop."},
    {"id": "NOM-01", "cat": "Nomenclatura (Strictly English)",
     "name": "Tablas/colecciones nombradas en ingles y plural",
     "severity": "MEDIA",
     "logro": "El esquema de BD es consistente y comprensible por cualquier desarrollador internacional del equipo."},
    {"id": "NOM-02", "cat": "Nomenclatura (Strictly English)",
     "name": "Columnas/campos en snake_case o camelCase en ingles",
     "severity": "MEDIA",
     "logro": "Los campos son predecibles y alineados con el estandar REST. Se evitan errores de mapeo por nombres mixtos."},
    {"id": "NOM-03", "cat": "Nomenclatura (Strictly English)",
     "name": "Clases, metodos y variables Java en ingles",
     "severity": "MEDIA",
     "logro": "El codigo es mantenible por cualquier miembro del equipo. Se evita deuda tecnica por nomenclatura inconsistente."},
    {"id": "TEN-01", "cat": "Multi-Tenancy y Soft Delete",
     "name": "Entidades contienen campo de tenant (tenantId / organization_id / institucion_id)",
     "severity": "CRITICA",
     "logro": "Cada registro esta asociado a una organizacion. Imposible que un tenant acceda a datos de otro."},
    {"id": "TEN-02", "cat": "Multi-Tenancy y Soft Delete",
     "name": "Consultas filtran por tenant/organizacion",
     "severity": "ALTA",
     "logro": "El aislamiento de datos entre organizaciones es efectivo. Cumple requisitos de privacidad y seguridad."},
    {"id": "TEN-03", "cat": "Multi-Tenancy y Soft Delete",
     "name": "Soft delete implementado (active/status/deleted_at); cero DELETE fisico",
     "severity": "ALTA",
     "logro": "Se conserva historial completo para auditoria. Los datos eliminados son recuperables y trazables."},
    {"id": "TEN-04", "cat": "Multi-Tenancy y Soft Delete",
     "name": "Auditoria temporal UTC (createdAt / updatedAt con LocalDateTime o Instant)",
     "severity": "MEDIA",
     "logro": "Trazabilidad temporal precisa y uniforme sin problemas de zona horaria entre servidores."},
    {"id": "SEC-01", "cat": "Seguridad y Storage Offloading",
     "name": "Cero binarios/Base64 en BD; archivos delegados a Cloudinary/MinIO (solo URL)",
     "severity": "ALTA",
     "logro": "La BD no se satura con archivos pesados. Las consultas son mas rapidas y el almacenamiento mas barato."},
    {"id": "SEC-02", "cat": "Seguridad y Storage Offloading",
     "name": "Conexion BD exige TLS/SSL (mongodb+srv:// / sslmode=require)",
     "severity": "ALTA",
     "logro": "Los datos en transito entre el microservicio y la BD estan cifrados. Se previene intercepcion de credenciales."},
    {"id": "SEC-03", "cat": "Seguridad y Storage Offloading",
     "name": "Credenciales inyectadas por variables de entorno ${VAR}; cero secretos en claro",
     "severity": "CRITICA",
     "logro": "Las credenciales no quedan expuestas en el repositorio. Nadie que clone el codigo puede conectarse a la BD de produccion."},
]

RULE_MAP = {r["id"]: r for r in RULES}

# Remediaciones reutilizables para el modo Regex y como respaldo de findings.json.
# No son un parche ciego: muestran el patrón que el equipo debe adaptar al agregado
# y paquete concreto que reporta la auditoría.
REMEDIATIONS = {
    "HEX-01": {
        "linea": "// domain/model/Order.java: sin @Document, @Table, @Id ni @Column",
        "recomendacion": "Mueve las anotaciones de Spring Data a `infrastructure/adapter/out/persistence/OrderDocument.java` y deja el modelo de dominio como POJO:\n```java\npublic class Order { private UUID id; private UUID tenantId; }\n@Document(\"orders\") class OrderDocument { @Id String id; UUID tenantId; }\n```",
    },
    "HEX-02": {
        "linea": "public interface OrderRepositoryPort { Mono<Order> save(Order order); }",
        "recomendacion": "Declara el contrato en `domain/port/out` y haz que el caso de uso dependa solo de ese contrato. La implementación que usa Spring Data debe permanecer en infraestructura:\n```java\n@RequiredArgsConstructor\nclass SaveOrderUseCase { private final OrderRepositoryPort repository; }\n```",
    },
    "HEX-03": {
        "linea": "infrastructure/adapter/out/persistence/OrderPersistenceAdapter.java",
        "recomendacion": "Crea el adaptador, entidad/documento y repositorio Spring Data dentro de `infrastructure/adapter/out/persistence`. El adaptador implementa el puerto del dominio; no expongas `ReactiveMongoRepository` ni entidades técnicas desde `domain` o `application`.",
    },
    "HEX-04": {
        "linea": "OrderDocument toDocument(Order order); Order toDomain(OrderDocument document);",
        "recomendacion": "Agrega un mapper bidireccional y úsalo en el adaptador antes de guardar y antes de retornar datos:\n```java\n@Component class OrderPersistenceMapper {\n  OrderDocument toDocument(Order value) { /* copiar campos */ }\n  Order toDomain(OrderDocument value) { /* copiar campos */ }\n}\n```",
    },
    "REC-01": {
        "linea": "<!-- eliminar spring-boot-starter-data-jpa / jdbc; usar driver R2DBC -->",
        "recomendacion": "Elimina dependencias bloqueantes de `pom.xml` y reemplázalas por R2DBC o Mongo reactivo. Para PostgreSQL:\n```xml\n<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-r2dbc</artifactId></dependency>\n<dependency><groupId>org.postgresql</groupId><artifactId>r2dbc-postgresql</artifactId></dependency>\n```",
    },
    "REC-02": {
        "linea": "<artifactId>spring-boot-starter-webflux</artifactId>",
        "recomendacion": "Añade WebFlux y un driver reactivo, según la base de datos elegida. MongoDB:\n```xml\n<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-webflux</artifactId></dependency>\n<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-mongodb-reactive</artifactId></dependency>\n```",
    },
    "REC-03": {
        "linea": "interface OrderRepository extends ReactiveMongoRepository<OrderDocument, String> {}",
        "recomendacion": "Implementa el repositorio con una interfaz reactiva y retorna `Mono` o `Flux` en el puerto y adaptador:\n```java\ninterface OrderRepository extends ReactiveCrudRepository<OrderEntity, UUID> {}\nMono<Order> findByIdAndTenantId(UUID id, UUID tenantId);\n```",
    },
    "REC-04": {
        "linea": "return repository.save(entity).map(mapper::toDomain);",
        "recomendacion": "Elimina `.block()` y `.toStream()` del flujo de producción. Propaga el publisher hasta el controlador o compónlo con operadores reactivos:\n```java\nreturn repository.findById(id)\n    .switchIfEmpty(Mono.error(new NotFoundException()))\n    .map(mapper::toDomain);\n```",
    },
    "NOM-01": {
        "linea": "@Document(collection = \"orders\")",
        "recomendacion": "Renombra la tabla o colección a un sustantivo en inglés, minúscula y plural cuando corresponda. Actualiza la anotación y cualquier migración asociada:\n```java\n@Table(\"orders\") // no: pedidos, Ordenes, orderTable\n```",
    },
    "NOM-02": {
        "linea": "@Column(\"created_at\") private Instant createdAt;",
        "recomendacion": "Mapea campos de base de datos en `snake_case` e inglés y conserva atributos Java en `camelCase`:\n```java\n@Column(\"organization_id\") private UUID organizationId;\n@Column(\"created_at\") private Instant createdAt;\n```",
    },
    "NOM-03": {
        "linea": "Mono<Order> findById(UUID id);",
        "recomendacion": "Renombra clases, métodos y variables al inglés semántico y actualiza todas sus referencias. Ejemplo:\n```java\n// obtenerPedidos() -> findOrders()\nFlux<Order> findByTenantId(UUID tenantId);\n```",
    },
    "TEN-01": {
        "linea": "@Indexed @Field(\"tenant_id\") private UUID tenantId;",
        "recomendacion": "Añade el identificador de aislamiento a la entidad/documento y crea el índice correspondiente. Para MongoDB:\n```java\n@Indexed\n@Field(\"tenant_id\")\nprivate UUID tenantId;\n```\nPara SQL, crea una migración con `tenant_id NOT NULL` e índice compuesto según la consulta.",
    },
    "TEN-02": {
        "linea": "Flux<Order> findByTenantId(UUID tenantId);",
        "recomendacion": "Incluye el tenant/organización en cada método del puerto, repositorio y adaptador; nunca uses `findAll()` para datos de negocio:\n```java\nFlux<OrderDocument> findByTenantIdAndStatus(UUID tenantId, String status);\n```\nObtén `tenantId` desde el contexto autenticado antes de invocar el caso de uso.",
    },
    "TEN-03": {
        "linea": "return repository.save(entity.withStatus(Status.INACTIVE));",
        "recomendacion": "Reemplaza el borrado físico por una actualización de estado y excluye registros inactivos en las búsquedas:\n```java\nMono<Void> deactivate(UUID id, UUID tenantId) {\n  return repository.findByIdAndTenantId(id, tenantId)\n      .flatMap(item -> repository.save(item.withStatus(Status.INACTIVE))).then();\n}\n```",
    },
    "TEN-04": {
        "linea": "@Column(\"created_at\") private Instant createdAt;",
        "recomendacion": "Incorpora marcas UTC de creación y actualización en la entidad/documento y asígnalas al persistir:\n```java\nprivate Instant createdAt;\nprivate Instant updatedAt;\nentity.setUpdatedAt(Instant.now());\n```",
    },
    "SEC-01": {
        "linea": "private String attachmentUrl; // URL HTTPS, no byte[] ni Base64",
        "recomendacion": "Sube el archivo a MinIO o Cloudinary desde un adaptador de storage y persiste únicamente la URL resultante:\n```java\nreturn storagePort.upload(file)\n    .map(StorageObject::url)\n    .flatMap(url -> repository.save(entity.withAttachmentUrl(url)));\n```",
    },
    "SEC-02": {
        "linea": "spring: data: mongodb: uri: ${MONGODB_URI}",
        "recomendacion": "Usa una URI TLS en la variable de entorno, sin credenciales en el repositorio. Ejemplo MongoDB Atlas:\n```yaml\nspring:\n  data:\n    mongodb:\n      uri: ${MONGODB_URI} # mongodb+srv://...\n```\nPara R2DBC PostgreSQL, configura `?sslMode=require` en `R2DBC_URL`.",
    },
    "SEC-03": {
        "linea": "password: ${DB_PASSWORD}",
        "recomendacion": "Sustituye cada secreto literal por una variable de entorno sin valor por defecto sensible y rota el secreto expuesto:\n```yaml\nspring:\n  r2dbc:\n    password: ${DB_PASSWORD}\n  data:\n    mongodb:\n      uri: ${MONGODB_URI}\n```",
    },
}

# ==============================================================================
# ESTILOS
# ==============================================================================
FILL_PASS   = PatternFill("solid", fgColor="16A34A")
FILL_OBS    = PatternFill("solid", fgColor="D97706")
FILL_FAIL   = PatternFill("solid", fgColor="DC2626")
FILL_HEADER = PatternFill("solid", fgColor="1E3A8A")
FILL_SUBHDR = PatternFill("solid", fgColor="3B82F6")
FILL_ZEBRA  = PatternFill("solid", fgColor="F1F5F9")
FILL_GRP_ID  = PatternFill("solid", fgColor="1E3A8A")
FILL_GRP_RES = PatternFill("solid", fgColor="166534")
FILL_GRP_LOG = PatternFill("solid", fgColor="0E7490")
PROB_FILLS = [
    PatternFill("solid", fgColor="92400E"),
    PatternFill("solid", fgColor="5B21B6"),
    PatternFill("solid", fgColor="065F46"),
    PatternFill("solid", fgColor="9F1239"),
]

FONT_TITLE = Font(name="Calibri", size=14, bold=True, color="FFFFFF")
FONT_HDR   = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
FONT_GRP   = Font(name="Calibri", size=10, bold=True, color="FFFFFF")
FONT_BOLD  = Font(name="Calibri", size=10, bold=True)
FONT_NORM  = Font(name="Calibri", size=10)
FONT_CODE  = Font(name="Consolas", size=9)
FONT_SMALL = Font(name="Calibri", size=9, italic=True, color="64748B")

BORDER = Border(
    left=Side(style="thin",   color="CBD5E1"),
    right=Side(style="thin",  color="CBD5E1"),
    top=Side(style="thin",    color="CBD5E1"),
    bottom=Side(style="thin", color="CBD5E1"),
)
ALIGN_C = Alignment(horizontal="center", vertical="center")
ALIGN_L = Alignment(horizontal="left",   vertical="center")
ALIGN_W = Alignment(horizontal="left",   vertical="center", wrap_text=True)

MAX_PROBLEMAS = 4


def _status_fill(status):
    s = status.upper()
    if s in ("CUMPLE", "APROBADO"):
        return FILL_PASS
    if s in ("OBSERVADO", "PARCIAL"):
        return FILL_OBS
    return FILL_FAIL


def _cell(ws, row, col, value, font=None, fill=None, align=None, border=True):
    c = ws.cell(row=row, column=col, value=value)
    if font:  c.font      = font
    if fill:  c.fill      = fill
    if align: c.alignment = align
    if border: c.border   = BORDER
    return c


def _score(results):
    total, max_pts = 0, 0
    weights = {"CRITICA": 3, "ALTA": 2, "MEDIA": 1}
    for rule_id, (status, _, _e) in results.items():
        w = weights.get(RULE_MAP[rule_id]["severity"], 1)
        max_pts += w
        total += w if status == "CUMPLE" else (w * 0.5 if status == "OBSERVADO" else 0)
    pct   = round(total / max_pts * 100, 1) if max_pts else 0
    critical_fail = any(
        RULE_MAP[rule_id]["severity"] == "CRITICA" and status == "NO CUMPLE"
        for rule_id, (status, _, _e) in results.items()
    )
    label = "NO CUMPLE" if critical_fail else ("APROBADO" if pct >= 80 else "OBSERVADO")
    cumple = sum(1 for s, _, _e in results.values() if s == "CUMPLE")
    obs    = sum(1 for s, _, _e in results.values() if s == "OBSERVADO")
    fail   = sum(1 for s, _, _e in results.values() if s not in ("CUMPLE", "OBSERVADO"))
    return pct, label, cumple, obs, fail


# ==============================================================================
# MODO A — CARGAR DESDE findings.json
# ==============================================================================
def load_findings(findings_path):
    with open(findings_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    results   = {}
    criterios = {c["id"]: c for c in data.get("criterios", [])}

    for rule in RULES:
        rid = rule["id"]
        if rid not in criterios:
            results[rid] = (
                "OBSERVADO",
                ["Criterio no evaluado en findings.json"],
                [{
                    "problema": "No se adjuntó evidencia para evaluar este criterio.",
                    "linea_sugerida": REMEDIATIONS[rid]["linea"],
                    "recomendacion": REMEDIATIONS[rid]["recomendacion"],
                }],
            )
            continue

        c     = criterios[rid]
        state = c.get("estado", "OBSERVADO").upper().replace("_", " ")
        if "NO CUMPLE" in state:
            state = "NO CUMPLE"

        evidencias = c.get("evidencia", [])
        issues     = []
        evidence   = []
        remediation = REMEDIATIONS[rid]
        rec        = c.get("recomendacion", "") or remediation["recomendacion"]

        for ev in evidencias:
            # Inyectamos la recomendacion del criterio en cada evidencia
            ev_copy = dict(ev)
            if state != "CUMPLE" and not ev_copy.get("linea_sugerida"):
                ev_copy["linea_sugerida"] = remediation["linea"]
            if state != "CUMPLE" and rec and not ev_copy.get("recomendacion"):
                ev_copy["recomendacion"] = rec
            evidence.append(ev_copy)

            archivo  = ev_copy.get("archivo", "")
            linea    = ev_copy.get("linea", "")
            actual   = ev_copy.get("contenido_actual", "")
            problema = ev_copy.get("problema", ev_copy.get("cumplimiento", ""))
            issues.append(f"{archivo} linea {linea} -> {actual} | {problema}")

        if state != "CUMPLE" and rec:
            issues.append(f"Recomendacion: {rec}")

        results[rid] = (state, issues, evidence)

    return results, data


# ==============================================================================
# MODO B — ANALISIS POR REGEX (fallback)
# ==============================================================================
class Auditor:
    def __init__(self, path):
        self.path       = os.path.abspath(path)
        self.name       = os.path.basename(self.path)
        self.java_files = []
        self.pom        = ""
        self.yaml       = ""
        self._load()

    def _load(self):
        skip = {".git", "target", ".mvn", ".idea", "node_modules"}
        for root, dirs, files in os.walk(self.path):
            dirs[:] = [d for d in dirs if d not in skip]
            for f in files:
                fp = os.path.join(root, f)
                if f.endswith(".java"):
                    self.java_files.append(fp)
                elif f == "pom.xml" and not self.pom:
                    self._read(fp, "pom")
                elif f in ("application.yaml", "application.yml") and not self.yaml:
                    self._read(fp, "yaml")

    def _read(self, fp, target):
        try:
            with open(fp, "r", encoding="utf-8", errors="ignore") as fh:
                content = fh.read()
            if target == "pom":
                self.pom = content
            else:
                self.yaml = content
        except Exception:
            pass

    def _java_content(self, path_filter=None):
        result = []
        for fp in self.java_files:
            rel = os.path.relpath(fp, self.path).replace("\\", "/")
            if path_filter and path_filter not in rel:
                continue
            try:
                with open(fp, "r", encoding="utf-8", errors="ignore") as fh:
                    result.append((rel, fh.read()))
            except Exception:
                pass
        return result

    @staticmethod
    def _redact_sensitive_line(line):
        """Mantiene evidencia de configuración insegura sin revelar secretos."""
        key_value = re.match(r"^(\s*[^:#]+:\s*).*$", line)
        if key_value:
            return f"{key_value.group(1)}[REDACTED]"
        return "Configuración con secreto en texto plano [REDACTED]"

    def run(self):
        results = {}

        issues = []
        anns   = re.compile(r"@(Table|Document|Entity|Column|Field)\b")
        for rel, content in self._java_content():
            if "/model/" in rel or "/domain/model" in rel:
                for lno, line in enumerate(content.splitlines(), 1):
                    if anns.search(line) and not line.strip().startswith("//"):
                        issues.append(f"{self.name}/{rel} linea {lno} -> {line.strip()}")
        results["HEX-01"] = ("NO CUMPLE", issues, []) if issues else ("CUMPLE", [], [])

        has_port = any("/port/" in rel or "RepositoryPort" in c or "OutputPort" in c
                       for rel, c in self._java_content())
        results["HEX-02"] = ("CUMPLE", [], []) if has_port else (
            "OBSERVADO", ["No se detecto interfaz de puerto en capa de dominio"], [])

        has_persist = any("persistence" in rel or "infrastructure" in rel or "adapter" in rel
                          for rel, _ in self._java_content())
        results["HEX-03"] = ("CUMPLE", [], []) if has_persist else (
            "OBSERVADO", ["No se encontro paquete de persistencia en infraestructura"], [])

        has_mapper = any("mapper" in rel.lower() or "Mapper" in c for rel, c in self._java_content())
        results["HEX-04"] = ("CUMPLE", [], []) if has_mapper else (
            "OBSERVADO", ["No se encontro clase *Mapper.java"], [])

        blocking = [d for d in ["spring-boot-starter-data-jpa", "hibernate-core",
                                 "mysql-connector-java", "spring-boot-starter-jdbc"] if d in self.pom]
        results["REC-01"] = ("NO CUMPLE", [f"pom.xml contiene: {', '.join(blocking)}"], []) if blocking \
            else ("CUMPLE", [], [])

        has_reactive = ("spring-boot-starter-data-mongodb-reactive" in self.pom
                        or "spring-boot-starter-data-r2dbc" in self.pom) \
                       and "spring-boot-starter-webflux" in self.pom
        results["REC-02"] = ("CUMPLE", [], []) if has_reactive else (
            "NO CUMPLE", ["Falta spring-data-mongodb-reactive/r2dbc o webflux en pom.xml"], [])

        reactive_repos = ["ReactiveMongoRepository", "ReactiveCrudRepository",
                          "R2dbcRepository", "ReactiveSortingRepository"]
        has_rrepo = any(any(rr in c for rr in reactive_repos)
                        for rel, c in self._java_content()
                        if "repository" in rel.lower() or "Repository" in rel)
        results["REC-03"] = ("CUMPLE", [], []) if has_rrepo else (
            "NO CUMPLE", ["No se detectaron repositorios que extiendan interfaces reactivas"], [])

        block_issues = []
        for rel, c in self._java_content():
            if "/test/" in rel:
                continue
            for lno, line in enumerate(c.splitlines(), 1):
                s = line.strip()
                if re.search(r"\.block\s*\(", s) and not s.startswith("//"):
                    block_issues.append(f"{self.name}/{rel} linea {lno} -> {s}")
        results["REC-04"] = ("NO CUMPLE", block_issues, []) if block_issues else ("CUMPLE", [], [])

        table_names   = re.findall(
            r'@(?:Table|Document|Collection)\s*\(\s*(?:collection\s*=\s*)?["\']([^"\']+)["\']',
            " ".join(c for _, c in self._java_content()))
        spanish_table = [n for n in table_names if re.search(
            r'[aeiouAEIOU]|alerta|usuario|entidad|catalogo|recurso|incidente', n, re.I)]
        results["NOM-01"] = ("OBSERVADO", [f"Nombre sospechoso: {n}" for n in spanish_table], []) \
            if spanish_table else ("CUMPLE", [], [])

        spanish_fields = []
        for rel, c in self._java_content():
            for lno, line in enumerate(c.splitlines(), 1):
                if re.search(r'\b(fechaCreacion|estaActivo|descripcionAlerta|primerNombre|apellidoPaterno)\b', line):
                    spanish_fields.append(f"{self.name}/{rel} linea {lno} -> {line.strip()}")
        results["NOM-02"] = ("OBSERVADO", spanish_fields, []) if spanish_fields else ("CUMPLE", [], [])

        spanish_code = []
        for rel, c in self._java_content():
            for lno, line in enumerate(c.splitlines(), 1):
                if re.search(r'\b(obtener|guardar|eliminar|buscar|listar|crear|actualizar)[A-Z][a-zA-Z]+\s*\(', line):
                    spanish_code.append(f"{self.name}/{rel} linea {lno} -> {line.strip()}")
        results["NOM-03"] = ("OBSERVADO", spanish_code[:5], []) if spanish_code else ("CUMPLE", [], [])

        tenant_fields = ["organizationId", "organization_id", "tenantId", "tenant_id",
                         "institucionId", "institucion_id", "entidadId", "entidad_id"]
        has_tenant = any(any(tf in c for tf in tenant_fields) for _, c in self._java_content())
        results["TEN-01"] = ("CUMPLE", [], []) if has_tenant else (
            "OBSERVADO", ["No se detecto campo de multi-tenancy"], [])
        results["TEN-02"] = ("CUMPLE", [], []) if has_tenant else (
            "OBSERVADO", ["Sin campo de tenant — consultas posiblemente globales"], [])

        soft_keys = ["active", "isActive", "status", "deletedAt", "deleted_at", "INACTIVE"]
        has_soft  = any(any(sk in c for sk in soft_keys) for _, c in self._java_content())
        results["TEN-03"] = ("CUMPLE", [], []) if has_soft else (
            "OBSERVADO", ["No se detectaron flags de soft delete"], [])

        audit_keys = ["createdAt", "created_at", "updatedAt", "updated_at", "LocalDateTime", "Instant"]
        has_audit  = any(any(ak in c for ak in audit_keys) for _, c in self._java_content())
        results["TEN-04"] = ("CUMPLE", [], []) if has_audit else (
            "OBSERVADO", ["No se detectaron campos de auditoria temporal"], [])

        has_offload = ("cloudinary" in self.pom.lower() or "minio" in self.pom.lower()
                       or any("mediaUrl" in c for _, c in self._java_content()))
        results["SEC-01"] = ("CUMPLE", [], []) if has_offload else (
            "OBSERVADO", ["No se detecto integracion con Cloudinary/MinIO"], [])

        has_ssl = any(kw in self.yaml for kw in ["mongodb+srv://", "sslmode=require", "ssl=true", "ssl: true"])
        results["SEC-02"] = ("CUMPLE", [], []) if has_ssl else (
            "OBSERVADO", ["URI de BD no especifica TLS/SSL en application.yml"], [])

        hardcoded = []
        if self.yaml:
            for lno, line in enumerate(self.yaml.splitlines(), 1):
                s = line.strip()
                sensitive_key = re.search(r'\b(password|secret|token|api[_-]?key)\s*:', s, re.I)
                inline_secret = sensitive_key and not s.startswith("#") and (
                    "${" not in s or re.search(r'\$\{[^}:]+:[^}]+\}', s)
                )
                credentialed_uri = re.search(
                    r'(?:mongodb(?:\+srv)?|postgresql|r2dbc:postgresql)://[^:\s]+:[^@\s]+@', s, re.I)
                if inline_secret or credentialed_uri:
                    redacted = self._redact_sensitive_line(s)
                    hardcoded.append(f"{self.name}/application.yml linea {lno} -> {redacted}")
        results["SEC-03"] = ("NO CUMPLE", hardcoded, []) if hardcoded else ("CUMPLE", [], [])

        return results


def discover_microservice_dirs(root):
    """Devuelve los directorios inmediatos ``vg-ms-*`` de una raiz, ordenados."""
    root_path = os.path.abspath(root)
    if not os.path.isdir(root_path):
        raise ValueError(f"La raiz no existe o no es un directorio: {root}")

    services = []
    with os.scandir(root_path) as entries:
        for entry in entries:
            if entry.is_dir() and entry.name.startswith("vg-ms-"):
                services.append(entry.path)
    return sorted(services, key=lambda path: os.path.basename(path).lower())


# ==============================================================================
# EXTRACTOR DE EVIDENCIAS PARA EL EXCEL
# ==============================================================================
def _get_evidencias(raw, rule_id):
    """
    Devuelve lista de hasta MAX_PROBLEMAS dicts:
    [{ ubicacion, problema_linea, linea_sugerida, recomendacion }, ...]
    """
    status, issues, evidence = raw
    remediation = REMEDIATIONS[rule_id]
    out = []

    if evidence:
        for ev in evidence[:MAX_PROBLEMAS]:
            archivo  = ev.get("archivo", "")
            linea    = ev.get("linea", "")
            actual   = ev.get("contenido_actual", "")
            sug      = ev.get("linea_sugerida", "")
            rec      = ev.get("recomendacion", "-")
            problema = ev.get("problema", ev.get("cumplimiento", ""))

            nombre    = archivo
            # Dejar ruta desde src/ quitando el prefijo del microservicio
            if "/src/" in archivo:
                nombre = "src/" + archivo.split("/src/", 1)[1]
            elif "/" in archivo:
                nombre = archivo.split("/")[-1]
            ubicacion = f"{nombre}  linea {linea}"
            prob_txt  = f"linea {linea}: {actual}"
            if problema:
                prob_txt += f"\n{problema}"

            out.append({
                "ubicacion":      ubicacion,
                "problema_linea": prob_txt,
                "linea_sugerida": sug if sug else remediation["linea"],
                "recomendacion":  rec if rec else remediation["recomendacion"],
            })
    else:
        for iss in issues[:MAX_PROBLEMAS]:
            out.append({
                "ubicacion":      iss,
                "problema_linea": iss,
                "linea_sugerida": remediation["linea"],
                "recomendacion":  remediation["recomendacion"],
            })

    return out


# ==============================================================================
# GENERADOR DE EXCEL
# ==============================================================================
def build_excel(all_results, output_path, findings_meta=None):
    wb = openpyxl.Workbook()

    COL_PROB_START = 6
    COLS_PER_PROB  = 4
    COL_LOGRO      = COL_PROB_START + MAX_PROBLEMAS * COLS_PER_PROB  # 22
    TOTAL_COLS     = COL_LOGRO
    SUB_HEADERS    = ["Ubicacion", "Problema hallado y linea", "Linea sugerida", "Recomendacion"]
    SUB_WIDTHS     = [26, 38, 33, 42]

    # ── RESUMEN GENERAL ──────────────────────────────────────────────────────
    ws = wb.active
    ws.title = "Resumen General"
    ws.merge_cells("A1:I2")
    c = ws["A1"]
    c.value     = "REPORTE DE CUMPLIMIENTO PRS241 - DatabaseStorage (Hexagonal + DDD + Reactivo)"
    c.font      = FONT_TITLE
    c.fill      = FILL_HEADER
    c.alignment = ALIGN_C

    ws.merge_cells("A3:I3")
    ws["A3"].value     = (f"Generado {datetime.now(timezone.utc).strftime('%d/%m/%Y %H:%M:%S')} UTC  "
                          f"| Fuente: {'findings.json (Kiro)' if findings_meta else 'regex (fallback)'}")
    ws["A3"].font      = Font(name="Calibri", size=10, italic=True, color="64748B")
    ws["A3"].alignment = ALIGN_C

    for col, h in enumerate(["Microservicio", "% Cumplimiento", "Dictamen",
                              "CUMPLE", "OBSERVADO", "NO CUMPLE",
                              "Criticos OK", "Criticos FAIL", "Fuente"], 1):
        _cell(ws, 5, col, h, font=FONT_HDR, fill=FILL_SUBHDR, align=ALIGN_C)

    ws.column_dimensions["A"].width = 32
    ws.column_dimensions["B"].width = 18
    ws.column_dimensions["C"].width = 14
    ws.column_dimensions["I"].width = 24
    for col in range(4, 9):
        ws.column_dimensions[get_column_letter(col)].width = 14

    row = 6
    for ms_name, results in all_results.items():
        pct, label, cumple, obs, fail = _score(results)
        cok   = sum(1 for rid, (s, _, _e) in results.items()
                    if RULE_MAP[rid]["severity"] == "CRITICA" and s == "CUMPLE")
        cfail = sum(1 for rid, (s, _, _e) in results.items()
                    if RULE_MAP[rid]["severity"] == "CRITICA" and s != "CUMPLE")
        fuente = "Kiro findings.json" if (findings_meta and ms_name in findings_meta) else "Regex"
        fill_z = FILL_ZEBRA if row % 2 == 0 else None
        _cell(ws, row, 1, ms_name,       font=FONT_BOLD,  fill=fill_z, align=ALIGN_L)
        _cell(ws, row, 2, f"{pct}%",     font=FONT_NORM,  fill=fill_z, align=ALIGN_C)
        _cell(ws, row, 3, label,         font=FONT_HDR,   fill=_status_fill(label), align=ALIGN_C)
        _cell(ws, row, 4, cumple,        font=FONT_NORM,  fill=fill_z, align=ALIGN_C)
        _cell(ws, row, 5, obs,           font=FONT_NORM,  fill=fill_z, align=ALIGN_C)
        _cell(ws, row, 6, fail,          font=FONT_NORM,  fill=fill_z, align=ALIGN_C)
        _cell(ws, row, 7, cok,           font=FONT_NORM,  fill=fill_z, align=ALIGN_C)
        _cell(ws, row, 8, cfail,         font=FONT_NORM,  fill=fill_z, align=ALIGN_C)
        _cell(ws, row, 9, fuente,        font=FONT_SMALL, fill=fill_z, align=ALIGN_C)
        ws.row_dimensions[row].height = 20
        row += 1
    ws.freeze_panes = "A6"

    # ── PESTAÑA POR MICROSERVICIO ─────────────────────────────────────────────
    for ms_name, results in all_results.items():
        safe_name       = ms_name[:31]
        ws2             = wb.create_sheet(title=safe_name)
        last_col_letter = get_column_letter(TOTAL_COLS)

        # Titulo
        ws2.merge_cells(f"A1:{last_col_letter}2")
        c = ws2["A1"]
        c.value     = f"Auditoria PRS241 - {ms_name}"
        c.font      = FONT_TITLE
        c.fill      = FILL_HEADER
        c.alignment = ALIGN_C

        # Metricas
        pct, label, cumple, obs, fail = _score(results)
        fuente = "Kiro findings.json" if (findings_meta and ms_name in findings_meta) else "Regex"
        ws2.merge_cells(f"A3:{last_col_letter}3")
        c = ws2["A3"]
        c.value     = (f"Cumplimiento: {pct}%  |  Dictamen: {label}  |  "
                       f"Cumple: {cumple}  Observado: {obs}  No Cumple: {fail}  |  Fuente: {fuente}")
        c.font      = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
        c.fill      = _status_fill(label)
        c.alignment = ALIGN_C

        # Fila 4: grupos de columnas
        def _grp(fila, c1, c2, lbl, fill):
            if c1 != c2:
                ws2.merge_cells(f"{get_column_letter(c1)}{fila}:{get_column_letter(c2)}{fila}")
            for col in range(c1, c2 + 1):
                ws2.cell(fila, col).fill   = fill
                ws2.cell(fila, col).border = BORDER
            cell = ws2.cell(fila, c1)
            cell.value     = lbl
            cell.font      = FONT_GRP
            cell.alignment = ALIGN_C

        _grp(4, 1, 4, "IDENTIFICACION",         FILL_GRP_ID)
        _grp(4, 5, 5, "RESULTADO",              FILL_GRP_RES)
        for i in range(MAX_PROBLEMAS):
            c1 = COL_PROB_START + i * COLS_PER_PROB
            _grp(4, c1, c1 + COLS_PER_PROB - 1, f"PROBLEMA {i + 1}", PROB_FILLS[i])
        _grp(4, COL_LOGRO, COL_LOGRO, "QUE SE LOGRA AL CUMPLIR", FILL_GRP_LOG)

        # Fila 5: nombres de columna
        for col, h in enumerate(["ID", "Categoria", "Criterio", "Severidad"], 1):
            _cell(ws2, 5, col, h, font=FONT_GRP, fill=FILL_GRP_ID, align=ALIGN_C)
        _cell(ws2, 5, 5, "Estado", font=FONT_GRP, fill=FILL_GRP_RES, align=ALIGN_C)
        for i in range(MAX_PROBLEMAS):
            c1 = COL_PROB_START + i * COLS_PER_PROB
            for j, sh in enumerate(SUB_HEADERS):
                _cell(ws2, 5, c1 + j, sh, font=FONT_GRP, fill=PROB_FILLS[i], align=ALIGN_C)
        _cell(ws2, 5, COL_LOGRO, "Que se logra", font=FONT_GRP, fill=FILL_GRP_LOG, align=ALIGN_C)

        # Anchos
        ws2.column_dimensions["A"].width = 10
        ws2.column_dimensions["B"].width = 24
        ws2.column_dimensions["C"].width = 36
        ws2.column_dimensions["D"].width = 11
        ws2.column_dimensions["E"].width = 13
        for i in range(MAX_PROBLEMAS):
            c1 = COL_PROB_START + i * COLS_PER_PROB
            for j, w in enumerate(SUB_WIDTHS):
                ws2.column_dimensions[get_column_letter(c1 + j)].width = w
        ws2.column_dimensions[get_column_letter(COL_LOGRO)].width = 42

        # Datos fila a fila
        row = 6
        for rule in RULES:
            rid    = rule["id"]
            raw    = results.get(rid, ("OBSERVADO", ["No evaluado"], []))
            status = raw[0]
            fill_z = FILL_ZEBRA if row % 2 == 0 else None

            evidencias = _get_evidencias(raw, rid)

            _cell(ws2, row, 1, rid,              font=FONT_CODE, fill=fill_z, align=ALIGN_C)
            _cell(ws2, row, 2, rule["cat"],      font=FONT_NORM, fill=fill_z, align=ALIGN_W)
            _cell(ws2, row, 3, rule["name"],     font=FONT_NORM, fill=fill_z, align=ALIGN_W)
            _cell(ws2, row, 4, rule["severity"], font=FONT_BOLD, fill=fill_z, align=ALIGN_C)
            _cell(ws2, row, 5, status,           font=FONT_HDR,
                  fill=_status_fill(status), align=ALIGN_C)

            for i in range(MAX_PROBLEMAS):
                c1 = COL_PROB_START + i * COLS_PER_PROB
                if status == "CUMPLE" or i >= len(evidencias):
                    for j in range(COLS_PER_PROB):
                        _cell(ws2, row, c1 + j, "-", font=FONT_SMALL, fill=fill_z, align=ALIGN_C)
                else:
                    ev = evidencias[i]
                    _cell(ws2, row, c1 + 0, ev["ubicacion"],      font=FONT_CODE, fill=fill_z, align=ALIGN_W)
                    _cell(ws2, row, c1 + 1, ev["problema_linea"], font=FONT_CODE, fill=fill_z, align=ALIGN_W)
                    _cell(ws2, row, c1 + 2, ev["linea_sugerida"], font=FONT_NORM, fill=fill_z, align=ALIGN_W)
                    _cell(ws2, row, c1 + 3, ev["recomendacion"],  font=FONT_NORM, fill=fill_z, align=ALIGN_W)

            _cell(ws2, row, COL_LOGRO, rule.get("logro", ""),
                  font=FONT_SMALL, fill=fill_z, align=ALIGN_W)
            ws2.row_dimensions[row].height = 50
            row += 1

        ws2.freeze_panes = "A6"

    wb.save(output_path)
    print(f"[OK] Excel generado: {output_path}")


# ==============================================================================
# ENVIO DE CORREO
# ==============================================================================
def send_email(recipient, xlsx_path, all_results, gmail_user, gmail_app_password):
    ms_count  = len(all_results)
    summaries = []
    for ms, results in all_results.items():
        pct, label, c, o, f = _score(results)
        color = '#16a34a' if label == 'APROBADO' else ('#d97706' if label == 'OBSERVADO' else '#dc2626')
        summaries.append(
            f"<tr>"
            f"<td style='padding:6px 12px;border:1px solid #e2e8f0'>{ms}</td>"
            f"<td style='padding:6px 12px;border:1px solid #e2e8f0;text-align:center'><b>{pct}%</b></td>"
            f"<td style='padding:6px 12px;border:1px solid #e2e8f0;text-align:center;color:{color}'>"
            f"<b>{label}</b></td>"
            f"<td style='padding:6px 12px;border:1px solid #e2e8f0;text-align:center'>{c} / {o} / {f}</td>"
            f"</tr>"
        )
    html = f"""
<html><body style="font-family:Calibri,sans-serif;color:#1e293b;max-width:800px;margin:auto">
  <div style="background:#1e3a8a;padding:24px;border-radius:8px 8px 0 0">
    <h2 style="color:white;margin:0">Reporte PRS241 - DatabaseStorage</h2>
  </div>
  <div style="background:#f8fafc;padding:20px;border:1px solid #e2e8f0;">
    <p>Generado el <b>{datetime.now(timezone.utc).strftime('%d/%m/%Y %H:%M UTC')}</b>. Auditados: <b>{ms_count}</b> microservicios.</p>
    <table style="width:100%;border-collapse:collapse;margin-top:16px">
      <thead>
        <tr style="background:#1e3a8a;color:white">
          <th style="padding:8px 12px">Microservicio</th>
          <th style="padding:8px 12px">%</th>
          <th style="padding:8px 12px">Dictamen</th>
          <th style="padding:8px 12px">C/O/F</th>
        </tr>
      </thead>
      <tbody>{"".join(summaries)}</tbody>
    </table>
  </div>
</body></html>
"""
    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"[PRS241] Reporte {datetime.now(timezone.utc).strftime('%d/%m/%Y')}"
    msg["From"]    = gmail_user
    msg["To"]      = recipient
    msg.attach(MIMEText(html, "html"))
    with open(xlsx_path, "rb") as fh:
        part = MIMEBase("application", "octet-stream")
        part.set_payload(fh.read())
        encoders.encode_base64(part)
        part.add_header("Content-Disposition", f"attachment; filename={os.path.basename(xlsx_path)}")
        msg.attach(part)
    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
        server.login(gmail_user, gmail_app_password)
        server.sendmail(gmail_user, recipient, msg.as_string())
    print(f"[OK] Correo enviado a {recipient}")


# ==============================================================================
# PUNTO DE ENTRADA
# ==============================================================================
def main():
    parser = argparse.ArgumentParser(description="Verificador de Estandares PRS241")
    parser.add_argument("--findings", nargs="+", help="findings.json generados por Kiro")
    parser.add_argument("--dirs",     nargs="+", help="Directorios de microservicios (regex fallback)")
    parser.add_argument("--all", action="store_true",
                        help="Detecta todos los directorios vg-ms-* inmediatos dentro de --root")
    parser.add_argument("--root", default=".",
                        help="Raiz donde --all busca microservicios (por defecto: directorio actual)")
    parser.add_argument("--output", default=f"reporte_cumplimiento_prs241_{datetime.now().strftime('%Y%m%d_%H%M')}.xlsx")
    parser.add_argument("--email",    default="")
    parser.add_argument("--gmail-user",     default=os.environ.get("GMAIL_USER", ""))
    parser.add_argument("--gmail-password", default=os.environ.get("GMAIL_APP_PASSWORD", ""))
    args = parser.parse_args()

    if args.all and args.dirs:
        print("[ERROR] Usa --all o --dirs, no ambos a la vez.")
        sys.exit(1)

    if not args.findings and not args.dirs and not args.all:
        print("[ERROR] Debes indicar --findings, --dirs o --all --root <ruta>")
        sys.exit(1)

    all_results   = {}
    findings_meta = {}

    if args.findings:
        for fp in args.findings:
            if not os.path.isfile(fp):
                print(f"[WARN] No encontrado: {fp}")
                continue
            print(f"\n{'='*60}")
            print(f"[*] Cargando findings: {fp}")
            print(f"{'='*60}")
            results, meta = load_findings(fp)
            ms_name = meta.get("proyecto", os.path.basename(os.path.dirname(fp)))
            all_results[ms_name]   = results
            findings_meta[ms_name] = meta
            pct, label, c, o, f = _score(results)
            print(f"    Resultado: {label} ({pct}%)  cumple:{c} obs:{o} fail:{f}")

    regex_dirs = args.dirs
    if args.all:
        try:
            regex_dirs = discover_microservice_dirs(args.root)
        except ValueError as exc:
            print(f"[ERROR] {exc}")
            sys.exit(1)

        if not regex_dirs:
            print(f"[ERROR] No se encontraron directorios vg-ms-* en: {os.path.abspath(args.root)}")
            sys.exit(1)

        print(f"[*] Microservicios detectados en {os.path.abspath(args.root)}: "
              f"{', '.join(os.path.basename(path) for path in regex_dirs)}")

    if regex_dirs:
        for d in regex_dirs:
            if not os.path.isdir(d):
                print(f"[WARN] Directorio no encontrado: {d}")
                continue
            print(f"\n{'='*60}")
            print(f"[*] Auditando (regex): {os.path.basename(d)}")
            print(f"{'='*60}")
            auditor = Auditor(d)
            print(f"    Java files: {len(auditor.java_files)}")
            results = auditor.run()
            all_results[auditor.name] = results
            pct, label, c, o, f = _score(results)
            print(f"    Resultado: {label} ({pct}%)  cumple:{c} obs:{o} fail:{f}")

    if not all_results:
        print("[ERROR] Sin datos para auditar.")
        sys.exit(1)

    build_excel(all_results, args.output, findings_meta=findings_meta if findings_meta else None)

    if args.email and args.gmail_user and args.gmail_password:
        send_email(args.email, args.output, all_results, args.gmail_user, args.gmail_password)
    elif args.email:
        print("[WARN] Faltan credenciales Gmail.")
    else:
        print("[INFO] Sin correo configurado - solo se genera el Excel.")


if __name__ == "__main__":
    main()
