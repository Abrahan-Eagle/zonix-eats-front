---
name: strategic-compact-ops
description: >
  Compactación estratégica (concepto ECC strategic-compact, sin hooks).
  Sugiere compactar en hitos lógicos; preserva decisiones, verificación y TODOs vía handoff + Engram.
  Trigger: Compactar contexto, sesión larga, pre-loop, mid-task handoff.
license: UNLICENSED
metadata:
  author: JARVIS Global
  version: "1.0"
  scope: [global]
  category: ops
  auto_invoke:
    - "Compactar contexto"
    - "Sesión larga sugerir compactación"
  triggers: compact, compactación, strategic compact, contexto largo
  related-skills:
    - handoff
    - engram-memory-protocol
    - session-startup-ops
    - learning-loop-router
    - agent-loop-engineering
    - jarvis-core
allowed-tools: [Read, Edit, Write, Glob, Grep]
---

# Strategic compact ops

Equivalente conceptual a ECC `strategic-compact` / `suggest-compact.js`, como **protocolo** (no hooks PreCompact).

## Cuándo sugerir compactar

Proponer al usuario (HITL) cuando ocurra **cualquiera**:

1. Fin de fase del pipeline (Plan/Spec/Exec/Verify cerrada)
2. Antes de un loop largo (`agent-loop-engineering` / `skill-loop`)
3. >5 unidades de trabajo o >1 handoff pendiente sin documento
4. El usuario cambia de módulo/repo a mitad de sesión

## Qué preservar (antes de compactar)

| Artefacto | Destino |
|-----------|---------|
| Decisiones / trade-offs | bullets en `handoff` o Engram `mem_save` |
| Estado de verificación | comandos + exit codes recientes |
| TODOs abiertos | lista explícita en handoff |
| Lecciones candidatas | proponer vía `learning-loop` (no auto-escribir) |

## Procedimiento

1. Anunciar: "Sugiero compactar: [motivo]. ¿Procedo a escribir handoff?"
2. Con OK → skill **`handoff`** (documento `.agents/plans/handoff_*.md`)
3. Opcional Engram: `mem_save` de decisiones irreversibles
4. Tras compactación del cliente: **`session-startup-ops`** + `engram-memory-protocol` §post-compactación

## Qué NO hacer

- No instalar ni depender de hooks ECC `pre-compact` / `suggest-compact` (opt-in: `install-ecc-runtime.sh --with-hooks`)
- No borrar `active_context` ni skills
- No compactar en silencio sin OK del usuario

## Skills relacionadas

- `handoff` — traspaso/compactación mid-task
- `engram-memory-protocol` — recuperación post-compactación
- `session-startup-ops` — checklist al retomar
