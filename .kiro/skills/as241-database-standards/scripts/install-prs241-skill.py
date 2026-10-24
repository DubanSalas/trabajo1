#!/usr/bin/env python3
"""Instala la skill AS241 Database Standards para agentes compatibles."""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path


SKILL_ID = "as241-database-standards"
# El instalador forma parte de la propia skill; así el origen canónico y todos
# sus recursos viven bajo skills/as241-database-standards.
SOURCE_SKILL = Path(__file__).resolve().parents[1]


def target_for(agent: str, project: Path) -> Path:
    if agent == "codex":
        return Path.home() / ".codex" / "skills" / SKILL_ID
    # .agents/skills es compatible con OpenCode y otros agentes que implementan
    # Agent Skills. Antigravity y auto usan esta ubicación portable.
    return project / ".agents" / "skills" / SKILL_ID


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Instala la skill portable AS241 Database Standards"
    )
    parser.add_argument(
        "--agent",
        choices=("auto", "codex", "opencode", "antigravity"),
        default="auto",
        help="Agente destino. auto/opencode/antigravity instalan en .agents/skills del proyecto.",
    )
    parser.add_argument(
        "--project", default=".", help="Raíz del proyecto (por defecto: carpeta actual)."
    )
    parser.add_argument("--force", action="store_true", help="Reemplaza una instalación existente.")
    args = parser.parse_args()

    project = Path(args.project).resolve()
    if not project.is_dir():
        parser.error(f"El proyecto no existe: {project}")
    if not SOURCE_SKILL.is_dir():
        parser.error(f"No se encontró la skill fuente: {SOURCE_SKILL}")

    destination = target_for(args.agent, project)
    if destination.exists():
        if not args.force:
            parser.error(f"Ya existe: {destination}. Usa --force para actualizarla.")
        shutil.rmtree(destination)

    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(SOURCE_SKILL, destination, ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))

    print(f"[OK] Skill instalada: {destination}")
    if args.agent == "codex":
        print(f"Abre un chat nuevo y usa: ${SKILL_ID} Analiza todos los microservicios y genera el reporte PRS241 detallado.")
    elif args.agent == "opencode":
        print(f"En OpenCode usa: @{SKILL_ID} Analiza todos los microservicios y genera el reporte PRS241 detallado.")
    else:
        print("La skill quedó en .agents/skills. Usa el selector o la sintaxis de skills de tu agente.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
