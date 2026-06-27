---
name: handoff
description: >
  Compactar la sesion actual en un documento de traspaso para continuar en otro agente o chat.
  Complementa session-learner-ops (cierre de modulo) y active_context.md.
  Trigger: Compactar o traspasar sesion.
license: UNLICENSED
metadata:
  version: "2.0.0"
  adapted_from: mattpocock/skills (handoff)
  related-skills: [session-learner-ops, writing-plans, executing-plans, jarvis-core]
  auto_invoke:
    - "Compactar o traspasar sesion"
---

# Handoff (global)

Para **traspasos a mitad de tarea**, no para cierre formal de módulo (usar `session-learner-ops`).

## Cuándo usar

- Fin de sesión con trabajo incompleto
- Cambio de agente / ventana / modelo
- El usuario pide "déjame un handoff" o "continúa en otro chat"

## Dónde guardar

`.agents/plans/handoff_<tema_corto>.md` — ejemplo: `handoff_auth_refactor.md`

No sobrescribir `walkthrough.md` ni `implementation_plan.md` aprobados.

## Plantilla obligatoria

```markdown
# Handoff: <titulo>

**Fecha:** YYYY-MM-DD
**Repo:** <nombre-del-repo>
**Rama:** <rama-actual>

## Objetivo
Qué se intentaba lograr.

## Hecho
- ...

## Pendiente
- [ ] ...

## Archivos tocados
- `path/relativo`

## Comandos útiles
```bash
# tests, build, etc.
```

## Contexto crítico
Decisiones, bloqueos, deuda descubierta.

## Siguiente paso recomendado
Una acción concreta para el siguiente agente.
```

## Relación con otras skills

| Situación | Skill |
|-----------|-------|
| Mitad de tarea | `handoff` |
| Módulo cerrado | `session-learner-ops` → `docs/active_context.md` |
| Plan aprobado pendiente | Referenciar `.agents/plans/implementation_plan.md` |
