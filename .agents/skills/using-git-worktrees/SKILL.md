---
name: using-git-worktrees
description: >
  Worktree aislado para features Flutter proyecto. Base dev. Trigger: módulo UI grande.
license: UNLICENSED
metadata:
  version: "1.0.0"
  upstream: superpowers:using-git-worktrees
---

# Using git worktrees — proyecto activo

Mismas reglas que Backend: base **`dev`**, carpeta **`.worktrees/`** en gitignore.

**Spec Kitty:** repos con `.kittify/` usan `.worktrees/` por defecto para work packages. Cuando `kitty-router` está activo, alinear con esta skill (crear/remover worktrees, baseline, cierre con `finishing-a-development-branch`).

## Baseline tras crear worktree

```bash
cd .worktrees/feature/nombre-modulo
flutter pub get
flutter analyze
flutter test
```

## Cierre

`finishing-a-development-branch` + `git worktree remove` cuando el usuario confirme.
