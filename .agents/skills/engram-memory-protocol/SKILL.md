---
name: engram-memory-protocol
description: >
  Disciplina de memoria persistente con Engram MCP: mem_save, mem_search, mem_context,
  cierre de sesión y recuperación post-compactación. Trigger: guardar decisión en engram, mem_save, buscar memoria previa.
license: Apache-2.0
metadata:
  author: JARVIS Global (patch)
  version: "1.0-jarvis"
  scope: [global]
  category: ops
  upstream: Gentleman-Programming/engram:memory-protocol
  auto_invoke:
    - "Guardar decisión o bugfix en Engram"
    - "Buscar contexto previo mem_search mem_context"
    - "Cierre sesión con mem_session_summary"
  triggers: engram memory, mem_save, mem_search, mem_context, memory protocol, persistent memory
  related-skills:
    - engram-router
    - context-updater
    - handoff
    - session-learner-ops
    - agent-loop-engineering
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

## JARVIS / Cursor (mandatory)

- **Requiere:** Engram MCP activo (`engram setup cursor` vía `install-engram-runtime.sh`). Router: `engram-router`.
- **No sustituye:** `session-learner-ops`, `context-updater`, `docs/active_context.md` del producto — usar **ambas capas** cuando Engram esté instalado.
- **MCP tools:** invocar vía herramientas MCP del agente (`mem_save`, `mem_search`, `mem_context`, `mem_session_summary`, `mem_judge`, `mem_compare`).
- Doc: [docs/ENGRAM_INTEGRATION.md](../../docs/ENGRAM_INTEGRATION.md).

# Engram Memory Protocol

## Cuándo usar

- Decisión de arquitectura o implementación que debe sobrevivir sesiones.
- Bugfix con causa raíz no obvia.
- Patrón, gotcha o preferencia del usuario/proyecto.
- Antes de declarar done en trabajo largo o tras compactación.
- Usuario referencia trabajo previo del proyecto → buscar antes de responder.

**Cuándo NO usar:**

- Engram no instalado → `context-updater` + `handoff` + `active_context.md`.
- Operación mecánica sin aprendizaje durable.

## Save rules

Tras decision / bugfix / pattern / config change, llamar **`mem_save`** con:

- **title** conciso
- **type:** `architecture` | `decision` | `bugfix` | `pattern` | `config` (según aplique)
- **Contenido estructurado:** What / Why / Where / Learned
- **`topic_key`** estable para temas que evolucionan

## Search rules

| Situación | Tool |
|-----------|------|
| Recuperar contexto reciente | `mem_context` primero |
| Buscar keyword/tema | `mem_search` |
| Antes de trabajo similar | `mem_search` proactivo |
| Primer mensaje con referencia al proyecto | `mem_search` con keywords del usuario **antes** de responder |

## Conflict surfacing

Si dos memorias pueden contradecirse → `mem_judge` / `mem_compare` (beta upstream). Documentar resolución al usuario; no auto-borrar sin OK.

## Session close

Antes de "listo" en trabajo significativo:

1. `mem_session_summary` — goal, discoveries, accomplished, next steps, archivos relevantes.
2. Además: `session-learner-ops` / `context-updater` en capa JARVIS file-based.

Tras compactación de contexto:

1. Guardar summary en Engram.
2. `mem_search` / `mem_context` para recuperar.
3. Continuar trabajo.

## Anti-patrones

- Confiar solo en chat (sin save) en loops largos.
- Duplicar en Engram lo que ya está en `active_context.md` sin consolidar.
- `mem_save` con texto vago ("fixed stuff").

## Skills relacionadas

- `engram-router` — install y precedencia vs JARVIS memory.
- `agent-loop-engineering` — persistencia entre vueltas de loop.
