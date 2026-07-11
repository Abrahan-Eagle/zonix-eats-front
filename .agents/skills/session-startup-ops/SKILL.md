---
name: session-startup-ops
description: >
  Protocolo de arranque de sesión (concepto ECC session-start, sin hooks).
  Checklist: active_context, Engram si activo, Roles/Skills, plan/handoff pendiente.
  Trigger: Iniciar sesión, retomar proyecto, session start.
license: UNLICENSED
metadata:
  author: JARVIS Global
  version: "1.0"
  scope: [global]
  category: ops
  auto_invoke:
    - "Iniciar sesión"
    - "Retomar proyecto"
  triggers: session start, arranque sesión, retomar, active_context
  related-skills:
    - jarvis-core
    - engram-memory-protocol
    - engram-router
    - context-updater
    - context-packs-ops
    - handoff
    - session-learner-ops
    - strategic-compact-ops
allowed-tools: [Read, Glob, Grep, Bash]
---

# Session startup ops

Equivalente conceptual a ECC `session-start.js`, como **protocolo** (no hook SSOT).

## Cuándo usar

- Primer mensaje de una sesión en un proyecto activo
- Tras compactación / cambio de agente (`handoff`)
- Cuando el usuario diga "retomar" o "continuar"

## Checklist (orden fijo)

1. **Gobierno:** leer `AGENTS.md` + `.cursorrules` del repo activo (si existen).
2. **Memoria file-based:** leer `docs/active_context.md` si existe.
3. **Handoff / plan pendiente:** buscar `.agents/plans/handoff_*.md` o `implementation_plan.md` recientes; resumir en 3–5 bullets.
4. **Engram (si MCP activo):** `mem_context` / `mem_search` del proyecto; no inventar si el MCP no responde.
5. **Declarar** `> Roles:` y `> Skills:` (bootstrap JARVIS).
6. **Context pack (opcional):** si la sesión es research / produce / review, declarar `> Context pack: research|produce|review` según `context-packs-ops` (cierra el enlace unidireccional con esa skill).
7. **activity-log (opcional):** si el producto usa `state/tasks/`, listar tareas `open` con el bin `activity-log`.

## Qué NO hacer

- No instalar hooks ECC ni cron/heartbeats
- No reescribir `active_context` en el arranque (eso es cierre → `context-updater` / `session-learner-ops`)
- No asumir Engram disponible

## Skills relacionadas

- `jarvis-core` — precedencia y directiva de memoria
- `handoff` — traspaso mid-task
- `context-packs-ops` — modos research/produce/review
- `engram-memory-protocol` — recuperación post-compactación
- `strategic-compact-ops` — cuándo sugerir compactar (no en arranque)
