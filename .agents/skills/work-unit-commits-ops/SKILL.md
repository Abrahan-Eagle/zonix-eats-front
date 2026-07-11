---
name: work-unit-commits-ops
description: >
  Commits por unidad de trabajo reviewable: un propósito, tests/docs con el código, historia clara.
  Puente a chained PRs. Trigger: split commits, work units, preparar PR, SDD apply sin PR gigante.
license: Apache-2.0
metadata:
  author: JARVIS Global (patch)
  version: "1.0-jarvis"
  scope: [global]
  category: git
  upstream: Gentleman-Programming/gentle-ai:work-unit-commits
  auto_invoke:
    - "Dividir implementación en commits reviewables"
    - "Preparar commits antes de abrir PR"
    - "Evitar PR monolítico desde SDD tasks"
    - "Crear commit"
  triggers: work unit commits, split commits, atomic commits, commit story, reviewable commits
  related-skills:
    - jarvis-core
    - git-commit
    - structured-commits-ops
    - chained-pr-ops
    - branch-pr-ops
    - test-driven-development
    - verification-before-completion
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

## JARVIS / Cursor (mandatory)

- **Precedencia:** `jarvis-core` > esta skill. Mensaje final: `git-commit`. Trailers de decisión: `structured-commits-ops`.
- **TDD:** tests con el comportamiento que verifican — ver `test-driven-development`.
- **PR >400 líneas:** promover grupos de commits a `chained-pr-ops`.
- Doc: [docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md](../../../docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md).

# Work Unit Commits Ops

## Overview

Un **commit = una unidad de trabajo entregable** (comportamiento, fix, migración o docs de usuario), no un tipo de archivo. Cada commit debe contar una historia que un revisor entienda solo con el diff.

## Cuándo usar

- Implementación multi-archivo que necesita varios commits antes del PR.
- SDD `speckit-implement` / tasks con riesgo de PR >400 líneas.
- Usuario pide commits atómicos o "split en work units".

## Reglas críticas

| Regla | Requisito |
|-------|-----------|
| Por unidad, no por capa | No `models` → `services` → `tests` si ninguno funciona solo |
| Tests con código | Mismo commit que el comportamiento que verifican |
| Docs con cambio visible | Docs en el commit del feature que documentan |
| Historia clara | El revisor entiende el *por qué* del commit |
| PR-ready | Cada commit candidato a PR encadenado si crece el diff |
| Guard SDD | Si forecast >400 líneas → planear slices antes de implementar |

## Checklist pre-commit

- [ ] Un propósito claro.
- [ ] El repo sigue coherente aplicando **solo** este commit.
- [ ] Tests/docs de la unidad incluidos.
- [ ] Rollback razonable sin revertir trabajo ajeno.
- [ ] Mensaje Conventional Commit describe el **resultado**, no la lista de archivos.

## Ejemplos de split

| Split débil | Split por unidad de trabajo |
|-------------|----------------------------|
| `add models` | `feat(auth): add token validation model and tests` |
| `add services` | `feat(auth): wire validation into login flow` |
| `add tests` | Tests incluidos en cada commit de comportamiento |

## Relación con PR

1. Construir la unidad mínima independiente.
2. Incluir verificación de esa unidad.
3. Commit con Conventional Commit (`git-commit`).
4. Si `git diff --stat` vs base se acerca a 400 líneas → `chained-pr-ops`.

## Comandos

```bash
git diff --stat
git diff --cached --stat
git log --oneline -5
```

## Anti-patrones

- Commits "WIP" o "fix stuff" sin unidad definida.
- Tests en commit separado del código que cubren.
- Un solo commit gigante antes de abrir PR.

## Skills relacionadas

- `git-commit` — generación Conventional Commits.
- `structured-commits-ops` — trailers de decisión en producto.
- `chained-pr-ops` — cuando el diff total supera presupuesto de review.
