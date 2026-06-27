---
name: cognitive-doc-design-ops
description: >
  Diseñar docs con baja carga cognitiva: lead with answer, progressive disclosure, checklists
  para review. Trigger: README, RFC, onboarding, descripción PR, guías densas o difíciles de escanear.
license: Apache-2.0
metadata:
  author: JARVIS Global (patch)
  version: "1.0-jarvis"
  scope: [global]
  category: planning
  upstream: Gentleman-Programming/gentle-ai:cognitive-doc-design
  auto_invoke:
    - "Redactar o mejorar README, RFC, onboarding o guía"
    - "Escribir descripción de PR o notas para review"
    - "Doc largo, denso o difícil de escanear"
  triggers: cognitive doc design, baja carga cognitiva, PR description, onboarding doc, README structure, review-facing docs
  related-skills:
    - jarvis-core
    - docs-alignment-ops
    - chained-pr-ops
    - branch-pr-ops
    - writing-plans
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

## JARVIS / Cursor (mandatory)

- **Precedencia:** `jarvis-core` > esta skill. **Exactitud vs código:** `docs-alignment-ops`.
- **PRs encadenados:** enlazar PR anterior/siguiente y "qué revisar primero" — ver `chained-pr-ops`.
- **Comentarios humanos en review:** `comment-writer-ops` (tono); esta skill cubre **estructura** del doc.
- Doc: [docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md](../../docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md).

# Cognitive Doc Design Ops

## Cuándo usar

- Crear o editar documentación que alguien debe entender rápido, retener o usar durante review.
- PR descriptions, guías de contribución, arquitectura, onboarding.
- Doc que se siente largo, denso o difícil de escanear.

**Cuándo NO usar:** solo verificar que docs = código → `docs-alignment-ops`.

## Patrones críticos

| Patrón | Regla |
|--------|-------|
| Lead with the answer | Decisión, acción u outcome primero; contexto después |
| Progressive disclosure | Happy path primero; detalles, edge cases y refs después |
| Chunking | Secciones pequeñas; listas planas cortas |
| Signposting | Headings, labels, callouts, resúmenes para orientar al lector |
| Recognition over recall | Tablas, checklists, ejemplos y plantillas > prosa memorizable |
| Review empathy | El revisor verifica intent sin reconstruir toda la historia |

## Forma por defecto

Usar esta estructura salvo que el repo tenga plantilla más fuerte:

```markdown
# <Título orientado al outcome>

<Un párrafo: qué cambió, a quién ayuda y por qué importa.>

## Quick path

1. <Primera acción>
2. <Segunda acción>
3. <Verificación o resultado esperado>

## Details

| Topic | Decision |
|-------|----------|
| <área> | <explicación concisa> |

## Checklist

- [ ] <El lector puede confirmar esto>
- [ ] <El lector puede confirmar aquello>

## Next step

<Enlace o acción que continúa el flujo.>
```

## PR y docs de review

Reducir burnout del revisor haciendo explícito el camino de review:

- Qué revisar **primero**.
- Qué queda **fuera de scope** a propósito.
- Enlaces al PR **anterior y siguiente** si la cadena es encadenada (`chained-pr-ops`).
- Una sección = una decisión o unidad de trabajo.
- Checklists para criterios de aceptación y verificación.

## Comandos

```bash
# Markdown cambiado en la rama actual
git diff --name-only -- '*.md'

# Carga cognitiva del PR (líneas cambiadas)
gh pr view <PR_NUMBER> --json additions,deletions,changedFiles
```

## Skills relacionadas

- `docs-alignment-ops` — docs describen comportamiento actual del código.
- `chained-pr-ops` — PRs >400 líneas y navegación entre slices.
- `comment-writer-ops` — redactar comentarios humanos en review/issues.
