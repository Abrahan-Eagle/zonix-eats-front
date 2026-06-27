---
name: engram-router
description: >
  Orquesta memoria persistente Engram (MCP) vs context-updater/handoff/active_context JARVIS.
  Trigger: engram, memoria persistente MCP, mem_save, sobrevivir compactación, engram setup cursor.
license: UNLICENSED
metadata:
  author: JARVIS Global
  version: "1.0"
  scope: [global]
  category: core
  auto_invoke:
    - "Memoria persistente Engram MCP"
    - "Configurar engram en Cursor"
    - "mem_save mem_search contexto entre sesiones"
  triggers: engram, memory MCP, mem_save, mem_search, persistent memory, engram setup
  related-skills:
    - jarvis-core
    - engram-memory-protocol
    - context-updater
    - handoff
    - session-learner-ops
    - learning-loop-router
    - agent-loop-engineering
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

# Engram Router

Router para [Engram](https://github.com/Gentleman-Programming/engram) (MIT): memoria persistente agent-agnostic vía MCP (`mem_*` tools). **Opt-in** — complementa, no sustituye, `docs/active_context.md` y `context-updater`.

Guía: [docs/ENGRAM_INTEGRATION.md](../../docs/ENGRAM_INTEGRATION.md). Ecosistema: [docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md](../../docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md).

## Detección runtime

```bash
command -v engram >/dev/null 2>&1 && engram version 2>/dev/null && echo ENGRAM_CLI
test -d "${HOME}/.cursor/skills/engram-memory-protocol" && echo ENGRAM_SKILL_INSTALLED
test -f skills/ops/engram-memory-protocol/SKILL.md && echo ENGRAM_SKILL_LIBRARY
test -d "${HOME}/.engram" && echo ENGRAM_DATA_DIR
```

Install runtime: `bash scripts/install-engram-runtime.sh` (OK usuario).

## Árbol de decisión

| Pedido | Ruta | No usar |
|--------|------|---------|
| Cierre módulo / walkthrough producto | `session-learner-ops`, `context-updater` | engram como único SSOT |
| Handoff mid-task | `handoff` + `active_context.md` | — |
| Aprendizajes sesión (scan/wrap-up) | `learning-loop-router` | engram como sustituto |
| Loop largo / compactación | `agent-loop-engineering` + **engram** si MCP instalado | — |
| Guardar decisión/bugfix/patrón cross-session | `engram-memory-protocol` (requiere MCP) | — |
| Conflictos entre memorias | `mem_judge` / `mem_compare` (MCP) | — |
| Instalar/configurar Engram | `install-engram-runtime.sh` | sync masivo skills Go/TUI engram |

## Flujo recomendado (Cursor)

1. Usuario adopta Engram → `bash scripts/install-engram-runtime.sh`.
2. Reiniciar Cursor para cargar MCP (`engram setup cursor`).
3. Durante trabajo: skill `engram-memory-protocol` tras decisiones no obvias.
4. Cierre: `mem_session_summary` (MCP) **y** `session-learner-ops` (JARVIS file-based) — capas complementarias.

## Limitaciones

- Requiere binario `engram` y MCP habilitado en Cursor.
- Cloud Engram es opt-in; local SQLite (`~/.engram/`) es SSOT por defecto.
- Skills Go/TUI del repo engram (`server-api`, `dashboard-htmx`, …) son **dominio engram**, no globales JARVIS.
