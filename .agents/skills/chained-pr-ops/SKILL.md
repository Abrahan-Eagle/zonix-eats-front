---
name: chained-pr-ops
description: >
  Divide PRs grandes en cadenas reviewables (stacked o feature-branch chain): regla 400 líneas,
  diagrama de dependencias, integración gh. Trigger: PR supera 400 líneas, stacked PRs, chained PRs, review slices.
license: Apache-2.0
metadata:
  author: JARVIS Global (patch)
  version: "1.0-jarvis"
  scope: [global]
  category: git
  upstream: Gentleman-Programming/gentle-ai:chained-pr
  auto_invoke:
    - "PR supera 400 líneas o presupuesto de review"
    - "Stacked PRs o chained PRs"
    - "Dividir diff grande en slices reviewables"
  triggers: chained PR, stacked PR, PR 400 lines, review slices, split PR
  related-skills:
    - jarvis-core
    - work-unit-commits-ops
    - branch-pr-ops
    - git-guardrails-ops
    - code-review-playbook
    - verification-before-completion
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

## JARVIS / Cursor (mandatory)

- **Precedencia:** `jarvis-core` > esta skill. Commits atómicos: `work-unit-commits-ops`. Abrir PR: `branch-pr-ops`.
- **Push/merge:** solo con orden explícita del usuario — `git-guardrails-ops`.
- **Review pre-merge:** `code-review-playbook` o `parallel-judge-ops` en PRs de alto riesgo.
- Doc: [docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md](../../../docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md).

# Chained PR Ops

## Overview

Divide cambios que superan el **presupuesto de review** (~400 líneas `additions + deletions`, o el límite del repo) en PRs encadenadas que un revisor puede abordar en ~60 minutos cada una.

## Cuándo usar

- PR planificado o actual >400 líneas cambiadas.
- SDD/plan marca riesgo alto de tamaño de PR.
- Usuario pide stacked PRs, review slices o reducir carga del revisor.

**Cuándo NO usar:**

- PR ≤400 líneas y enfocado → PR único (`branch-pr-ops`).
- Diff generado/vendor que no se puede partir limpiamente → pedir `size:exception` al maintainer.

## Reglas duras

| Regla | Requisito |
|-------|-----------|
| Presupuesto | ≤400 líneas por PR salvo `size:exception` documentada |
| Review time | ~≤60 min por PR |
| Unidad | Un deliverable por PR; tests/docs con la unidad que verifican |
| Contexto | Cada PR declara inicio, fin, dependencias previas, follow-up, out-of-scope |
| Diagrama | Cada PR hijo incluye diagrama de cadena con el actual marcado |
| Estrategia | No mezclar stacked vs feature-branch chain tras elegir una |

## Estrategias

| Estrategia | Cuándo | Target branch |
|------------|--------|---------------|
| **Stacked PRs** | Cada slice puede integrarse a `main` de forma independiente | `main` (base = PR anterior mergeado o branch intermedio) |
| **Feature Branch Chain** | La feature debe integrarse entera antes de `main` | Tracker draft → PR#1 → PR#2 → … → merge tracker |

## Procedimiento

1. Estimar líneas (`git diff --stat` vs base) e identificar unidades de trabajo independientes.
2. Si supera presupuesto y no hay estrategia cacheada → preguntar stacked vs feature-branch chain.
3. Crear branches/PRs solo con la estrategia elegida (`gh pr create`, `git checkout -b`).
4. Añadir **Chain Context** a cada cuerpo de PR (sin reemplazar template del repo).
5. Verificar cada PR: CI/tests/docs, scope de rollback, diff limpio (solo la unidad actual).
6. Tracker en feature-branch chain: draft/no-merge hasta que todos los hijos estén revisados.

## Plantilla Chain Context

```markdown
## Chain Context
- Strategy: stacked | feature-branch-chain
- Position: PR 2 of 4
- Depends on: #123 (merged) / branch `feat/tracker`
- This PR: <qué entrega>
- Next: <qué sigue>
- Out of scope: <qué NO incluye>

```mermaid
flowchart LR
  PR1[#123 base] --> PR2["#124 current"]
  PR2 --> PR3[#125 next]
```
📍 = PR actual
```

## Anti-patrones

- Un PR monolítico >400 líneas "para terminar rápido".
- Mezclar estrategias a mitad de cadena.
- Diff sucio (archivos fuera de la unidad) — retarget/rebase hasta limpiar.
- Push sin OK usuario.

## Skills relacionadas

- `work-unit-commits-ops` — commits que alimentan cada PR de la cadena.
- `branch-pr-ops` — checklist issue-first y naming antes de abrir PR.
- `git-guardrails-ops` — push/merge.
