---
name: git-guardrails-ops
description: >
  Protección git: bloquea push a main, advierte en dev, exige confirmación antes de comandos destructivos.
  Trigger: Hacer git push o merge, comando git destructivo.
license: UNLICENSED
metadata:
  version: "2.0.0"
  adapted_from: mattpocock/skills (git-guardrails-claude-code)
  related-skills: [git-commit, structured-commits-ops, finishing-a-development-branch, using-git-worktrees, jarvis-core]
  auto_invoke:
    - "Hacer git push o merge"
    - "Comando git destructivo"
---

# Git guardrails ops (global)

Refuerza: **NUNCA push/merge sin orden explícita del usuario**.

## Flujo de ramas (típico)

Consultar `AGENTS.md` del proyecto para ramas y entornos. Patrón habitual:

| Rama | Uso |
|------|-----|
| `dev` / `develop` | Desarrollo y staging |
| `main` | Producción |

**Flujo:** rama de desarrollo → probar → merge a `main` solo con orden explícita.

## Comandos prohibidos sin orden explícita

- `git push` (cualquier rama remota)
- `git push origin main` / merge a `main`
- `git push --force` / `git push -f`
- `git merge` hacia `main`
- `git reset --hard`
- `git clean -fd` / `git clean -fdx`
- `git branch -D` en ramas compartidas

## Comandos permitidos sin push

- `git status`, `git diff`, `git log`
- `git add`, `git commit` (commits locales)
- `git stash`, crear ramas locales

## Hooks (opcional por proyecto)

Si el repo define `.githooks/`, el usuario activa manualmente:

```bash
chmod +x .githooks/pre-push
git config core.hooksPath .githooks
```

## Checklist antes de push (agente)

1. ¿El usuario pidió explícitamente push/merge?
2. ¿Rama correcta según `AGENTS.md`?
3. ¿Tests/analyze del stack pasaron si hubo cambios de código?
4. ¿Commits locales con mensaje conventional?

Si alguna respuesta es no → **detener** y pedir confirmación.

---

## Overlay Zonix Glasses Front — git-guardrails-ops

Sin push/merge sin OK. Ramas `dev` / `main`.
