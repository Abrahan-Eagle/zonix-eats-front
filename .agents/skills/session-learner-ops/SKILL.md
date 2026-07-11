---
name: session-learner-ops
description: >
  Tras cerrar módulo UI: patrones en docs/active_context.md y walkthrough.
  Trigger: Terminar módulo Frontend.
license: UNLICENSED
metadata:
  version: "1.1.0"
  auto_invoke:
    - "Terminar módulo"
  related-skills: [jarvis-core, verification-before-completion, continuous-learning-v2]
---

# Session learner ops — proyecto activo

Adaptado desde clawvis-openclaw.

## Destinos

- `docs/active_context.md` — memoria viva
- `.agents/plans/walkthrough.md` — cierre módulo

## HITL ligero (reglas de colaboración producto)

1. **Proponer** el resumen de patrones / párrafo para `active_context` + walkthrough.
2. Esperar **OK del usuario**.
3. Solo entonces **escribir** en disco.

Alineado con “preguntar antes de actuar” en CorralX/Zonix/`AGENTS.md`. No auto-escribir cierres de módulo.

## Ejemplos de buenos patrones

- "Chat AppBar: `onSurface` en dark mode, no `onPrimary`"
- "Tabs Mi Perfil: filled primary en modo claro"

## Anti-patrones

- "Mejorar UX" sin detalle
- Duplicar lo ya en `{producto}-ui-design`

Mismo proceso y plantilla que Backend.

## ECC instincts (opcional)

Si el repo producto tiene ECC hooks activos (`install-ecc-runtime.sh --with-hooks`), complementar con skill `continuous-learning-v2` para instincts y `/evolve`. **Cierre canónico JARVIS:** siempre `docs/active_context.md` vía esta skill primero.

Si hubo auditoría Cyber Neo en la sesión, enlazar path del reporte MD en `active_context` (hallazgos Critical/High) — forense: [CYBER_NEO_FORENSE_JARVIS.md](../../../docs/CYBER_NEO_FORENSE_JARVIS.md).

Opcional tras cierre canónico: si el usuario pide consolidación profunda de señales de sesión, invocar `learning-loop-router` → wrap-up — ver [LEARNING_LOOP_INTEGRATION.md](../../../docs/LEARNING_LOOP_INTEGRATION.md). No sustituye este skill.

Si la sesión usó `skill-loop run` y el workflow terminó (`done`), documentar resultado del loop en `active_context` (iteraciones, skill final) — ver [SKILL_LOOP_INTEGRATION.md](../../../docs/SKILL_LOOP_INTEGRATION.md). Cierre canónico sigue siendo este skill.

---

## Overlay Zonix Glasses Front — session-learner-ops

Actualizar `docs/active_context.md` y punteros a canon back en `docs/CONTEXTO_IA.md`.
