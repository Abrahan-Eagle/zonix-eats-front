---
name: branch-pr-ops
description: >
  Workflow branch + PR: naming conventional, checklist pre-PR, issue linking, presupuesto review,
  gh integration. Adaptable al AGENTS.md del repo. Trigger: crear PR, abrir pull request, branch naming.
license: Apache-2.0
metadata:
  author: JARVIS Global (patch)
  version: "1.0-jarvis"
  scope: [global]
  category: git
  upstream: Gentleman-Programming/gentle-ai:branch-pr
  auto_invoke:
    - "Crear o preparar pull request"
    - "Naming de branch y checklist pre-PR"
    - "Abrir PR con gh"
  triggers: branch PR, pull request, create PR, branch naming, issue-first PR
  related-skills:
    - jarvis-core
    - git-commit
    - work-unit-commits-ops
    - chained-pr-ops
    - git-guardrails-ops
    - code-review-playbook
    - verification-before-completion
    - speckit-taskstoissues
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

## JARVIS / Cursor (mandatory)

- **Precedencia:** `jarvis-core` > esta skill. Push/merge: `git-guardrails-ops` (solo OK usuario).
- **Commits:** `verification-before-completion` → `git-commit` → `work-unit-commits-ops`.
- **PR >400 líneas:** `chained-pr-ops` antes de abrir.
- **Issues desde tasks:** `speckit-taskstoissues` (opcional, OK usuario).
- Adaptar reglas issue-first / labels al `AGENTS.md` y CI del **repo activo** (no asumir labels de gentle-ai/engram).
- Doc: [docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md](../../../docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md).

# Branch & PR Ops

## Overview

Workflow estándar para branch → implement → test → commit → PR, con presupuesto de review y enlace a issue cuando el repo lo exige.

## Cuándo usar

- Crear branch para fix/feature.
- Preparar o abrir PR (`gh pr create`).
- Checklist antes de pedir review.

## Workflow

```
1. Leer AGENTS.md / CONTRIBUTING del repo (issue-first, labels, tests)
2. Branch desde main/develop según convención del producto
3. Implementar + tests (TDD si aplica)
4. verification-before-completion
5. Commits work-unit (work-unit-commits-ops + git-commit)
6. Contar líneas: si >400 → chained-pr-ops
7. gh pr create con template del repo
8. code-review-playbook / parallel-judge-ops si alta stakes
```

## Branch naming (default JARVIS)

Patrón recomendado:

```
^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)/[a-z0-9._-]+$
```

Ejemplos: `feat/user-login`, `fix/checkout-race`, `docs/api-update`.

Si el producto define otro patrón (ej. `feature/TICKET-123-desc`), seguir el producto.

## Presupuesto de review

- Objetivo: **≤400 líneas** (`additions + deletions`) por PR.
- Excepción: `size:exception` o equivalente documentado con maintainer.
- Supera presupuesto → `chained-pr-ops`, no forzar un PR único.

## PR body mínimo

```markdown
## Linked issue
Closes #N   <!-- si el repo exige issue-first -->

## Summary
Qué hace y por qué.

## Changes
| Area | Change |
|------|--------|

## Test plan
- [ ] Comandos ejecutados con evidencia fresca
- [ ] Manual si aplica

## Checklist
- [ ] Convención de commits del repo
- [ ] Sin secretos en diff
- [ ] Dentro de presupuesto o excepción documentada
```

## Comandos

```bash
git checkout main && git pull
git checkout -b feat/short-description

gh issue view N --repo owner/repo   # si issue-first
gh pr create --title "feat(scope): summary" --body-file /tmp/pr-body.md
gh pr checks
```

## Anti-patrones

- PR sin leer CONTRIBUTING/AGENTS del repo.
- Force push a main/master.
- `Co-Authored-By` de IA si el repo lo prohíbe.
- Abrir PR monolítico >400 líneas sin chained plan.

## Skills relacionadas

- `work-unit-commits-ops`, `chained-pr-ops`, `git-guardrails-ops`, `code-review-playbook`.
