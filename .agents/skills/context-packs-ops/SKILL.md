---
name: context-packs-ops
description: >
  Modos de sesión ligeros research / produce / review (concepto ECC contexts/, sin inyección runtime).
  Define qué skills primar y qué evitar por modo.
  Trigger: Modo research, modo produce, modo review, context pack.
license: UNLICENSED
metadata:
  author: JARVIS Global
  version: "1.0"
  scope: [global]
  category: ops
  auto_invoke:
    - "Modo research"
    - "Modo produce"
    - "Modo review"
  triggers: context pack, research mode, produce mode, review mode
  related-skills:
    - fan-out-synthesize-ops
    - deep-interview-ops
    - test-driven-development
    - code-review-playbook
    - parallel-judge-ops
    - jarvis-core
allowed-tools: [Read, Glob, Grep]
---

# Context packs ops

Equivalente ligero a ECC `contexts/{dev,review,research}.md` **embebido** (sin directorio inyectable ni plugin).

Declarar al inicio: `> Context pack: research|produce|review`.

## research

**Primar:** `fan-out-synthesize-ops`, `deep-interview-ops`, `brainstorming-ops`, explore Task readonly.  
**Evitar:** commits, migraciones, deploy, escritura masiva sin plan aprobado.  
**Salida:** hallazgos con evidencia `archivo:línea` + plan corto.

## produce

**Primar:** `test-driven-development`, skill dominio `{producto}-*`, `task-pipeline-ops` / Spec Kit.  
**Evitar:** reabrir diseño si el plan ya está aprobado; scope creep.  
**Salida:** código + tests + verificación fresca.

## review

**Primar:** `code-review-playbook`, `parallel-judge-ops`, `llm-as-judge-ops`, `verification-before-completion`.  
**Evitar:** reimplementar features en el mismo turno de review.  
**Salida:** hallazgos P1/P2/P3 + disposition (merge / request-changes / needs-design).

## Cambio de modo

| De → A | Condición |
|--------|-----------|
| research → produce | usuario aprueba plan / spec |
| produce → review | diff listo o pre-PR |
| review → produce | request-changes con alcance claro |

## Qué NO hacer

- No vendorizar `contexts/*.md` de ECC al global
- No mezclar produce+review en el mismo writer sin separación (usar parallel-judge readonly)

## Skills relacionadas

- `session-startup-ops` — elegir pack al retomar
- `fan-out-synthesize-ops` — research default
- `ecc-router` — packs runtime ECC solo con install opt-in
