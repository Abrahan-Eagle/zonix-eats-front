---
name: backlog-triage-ops
description: >
  Triage de backlog GitHub: auditar issues/PRs abiertos, clasificar disposición (merge, request-changes,
  close, needs-design), priorizar y generar reporte accionable. Trigger: triage backlog, auditar issues PRs, maintainer review.
license: Apache-2.0
metadata:
  author: JARVIS Global (patch)
  version: "1.0-jarvis"
  scope: [global]
  category: ops
  upstream: Gentleman-Programming/engram:backlog-triage
  auto_invoke:
    - "Triage backlog issues y PRs"
    - "Auditar open issues como maintainer"
    - "Clasificar PRs merge request-changes close"
  triggers: backlog triage, triage issues, triage PRs, maintainer audit, disposition report
  related-skills:
    - jarvis-core
    - branch-pr-ops
    - code-review-playbook
    - parallel-judge-ops
    - git-guardrails-ops
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

## JARVIS / Cursor (mandatory)

- **Precedencia:** `jarvis-core` > esta skill. Merge/push: `git-guardrails-ops` (solo OK usuario).
- **Generalizar filosofía:** leer `AGENTS.md` / `CONTRIBUTING.md` del **repo activo** y adaptar la tabla de principios antes de clasificar (no asumir labels Engram en productos JARVIS).
- **Review profunda de diff:** `code-review-playbook` o `parallel-judge-ops`.
- Doc: [docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md](../../docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md).

# Backlog Triage Ops

## Overview

Protocolo de maintainer para auditar issues y PRs abiertos, asignar **una** disposición por ítem, priorizar y producir reporte con comentarios sugeridos.

## Cuándo usar

- Auditoría periódica del backlog.
- Limpiar ruido antes de release.
- Priorizar qué mergear/revisar/cerrar.

## Disposiciones (exactamente una por ítem)

| Disposición | Uso |
|-------------|-----|
| **MERGE** | PR correcto, scoped, checks OK, proceso del repo cumplido |
| **REQUEST CHANGES** | Idea correcta; fixes específicos listados |
| **CLOSE** | Noise, duplicado, fuera de scope, proceso incumplido irreparable |
| **NEEDS DESIGN** | Idea válida; decisión arquitectónica antes de PR |
| **APPROVE ISSUE** | Issue claro, reproducible, in-scope (añadir label aprobación si aplica) |
| **REJECT ISSUE** | Vago, duplicado, discussion-only |

## Fases

### 1. Fetch backlog

```bash
gh issue list --repo owner/repo --state open --json number,title,labels,author,comments,body --limit 100
gh pr list --repo owner/repo --state open --json number,title,labels,author,body,reviews,commits --limit 50
```

### 2. Clasificar cada ítem

Para **issues:** ¿bug reproducible? ¿feature clara? ¿duplicado? ¿necesita diseño?

Para **PRs:** ¿linked issue si el repo exige? ¿checks OK? ¿scope tight? ¿convención commits/branch?

### 3. Inferir stance del maintainer

Revisar comentarios `MEMBER`/`OWNER` en issues/PRs — ground truth sobre filosofía escrita.

### 4. Priorizar buckets

Quick wins → process blockers → bugs reales → architectural → noise (cerrar).

### 5. Reporte

```markdown
## Triage Report — owner/repo — YYYY-MM-DD

### Summary
- Open issues: N | Open PRs: N
- MERGE: N | REQUEST CHANGES: N | CLOSE: N | ...

### PRs
| # | Title | Disposition | Reason |

### Issues
| # | Title | Disposition | Reason |

### Suggested comments
(bullets con texto listo para gh issue comment / pr review)
```

## Plantilla filosofía (adaptar por repo)

Antes de triage, completar en el reporte o en notas:

| Principio | En la práctica |
|-----------|----------------|
| Issue-first (si aplica) | PR sin issue → CLOSE o REQUEST CHANGES |
| Scope tight | PR sprawling → REQUEST CHANGES |
| Evidence-based review | REQUEST CHANGES con checkboxes concretos |
| Cerrar noise | Issues vagos → REJECT/CLOSE con path forward |

## Anti-patrones

- Dejar issues abiertos sin acción cuando son noise.
- REQUEST CHANGES vagos ("needs improvement").
- MERGE sin leer diff en PRs de alto riesgo.

## Skills relacionadas

- `branch-pr-ops` — convenciones pre-PR del repo.
- `code-review-playbook`, `parallel-judge-ops` — review de diffs.
