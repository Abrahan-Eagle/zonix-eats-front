---
name: brainstorming-ops
description: >
  OBLIGATORIO antes de tareas complejas en proyecto activo: pantallas, providers, navegación,
  flujos KYC/onboarding. Propone alternativas y obtiene aprobación antes de codificar.
  Trigger: Planificar módulo, feature ambiguo, rediseño UI.
license: UNLICENSED
metadata:
  author: proyecto Team
  version: "1.0.0"
  scope: [root]
  auto_invoke:
    - "Planificar desarrollo"
    - "Iniciar módulo"
  related-skills:
    - deep-interview-ops
    - jarvis-core
    - product-ui-design
---

# Brainstorming ops — proyecto activo

Adaptado desde clawvis-openclaw.

## Regla

**NO escribir código** hasta diseño aprobado por el usuario.

## Cuándo se activa

- Nueva pantalla o flujo (marketplace, chat, perfil, KYC)
- Cambios en Provider / navegación
- Tema, accesibilidad, responsive
- Integración API nueva en servicios

## Checklist

1. Leer `AGENTS.md`, `docs/active_context.md`, `{producto}-flutter-arch`, `{producto}-ui-design`.
2. Preguntas clarificadoras.
3. 2–3 alternativas (widgets, estado, rutas).
4. Plan en `.agents/plans/implementation_plan.md`.
5. OK del usuario.

## Secuencia

```
deep-interview-ops (si vago) → brainstorming-ops → task-pipeline-ops → ejecución
```

## Contexto proyecto

- Siempre `AppConfig.apiUrl` — sin URLs hardcodeadas.
- Provider + servicios por feature.
- Tema: `corral_x_theme.dart`.

---

## Overlay Zonix Glasses Front — brainstorming-ops

Antes de pantallas: catálogo monturas, try-on A/B, carrito óptica, panel aliado.

Leer flujos en `../zonix-glasses-back/docs/MODELO_NEGOCIO/FLUJOS_OPERATIVOS.md`.
