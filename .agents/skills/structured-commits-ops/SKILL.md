---
name: structured-commits-ops
description: >
  Commits con trailers de decisión en proyecto activo. Complementa git-commit.
  Trigger: commit tras cambios de arquitectura UI/estado.
license: UNLICENSED
metadata:
  version: "1.1.0"
  auto_invoke:
    - "Crear commit"
  related-skills: [git-commit, work-unit-commits-ops, verification-before-completion]
---

# Structured commits ops — proyecto activo

Adaptado desde clawvis-openclaw.

Para commits por **unidad de trabajo** (historia reviewable, tests con código), ver `work-unit-commits-ops`. Esta skill añade **trailers de decisión** en el proyecto activo; no sustituye Conventional Commits base (`git-commit`).

## Scopes sugeridos

`onboarding`, `kyc`, `marketplace`, `chat`, `profiles`, `theme`, `config`, `agents`

## Mismo formato de trailers que Backend

Ver skill homónima en Backend; aplicar a commits Flutter/Dart.

## Checklist

- [ ] `flutter analyze` y `flutter test` según alcance
- [ ] Sin API keys en commit

---

## Overlay Zonix Glasses Front — structured-commits-ops

Scope commits por feature UI: `feat(optical):`, `fix(tryon):`.
