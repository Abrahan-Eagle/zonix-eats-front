---
name: deep-interview-ops
description: >
  Entrevista socrática antes de tareas ambiguas en proyecto activo. Gate claridad mínima 3.5/5.
  Trigger: UI vaga, flujo KYC/onboarding sin spec, cambios navegación global.
license: UNLICENSED
metadata:
  version: "1.1.0"
  auto_invoke:
    - "Requisitos ambiguos"
  related-skills:
    - brainstorming-ops
    - speckit-clarify
    - jarvis-core
---

# Deep interview ops — proyecto activo

> Con Spec Kit (`.specify/`), preferir `speckit-clarify` para clarificación estructurada de `spec.md`.

Adaptado desde clawvis-openclaw.

## Gate

```
NO EJECUTAR SI CLARIDAD PROMEDIO < 3.5 / 5.0
```

## Secuencia

`deep-interview-ops` → `brainstorming-ops` → ejecución

## 6 dimensiones

| Dimensión | Pregunta guía |
|-----------|---------------|
| Alcance | ¿Qué pantallas/widgets? ¿Web + móvil? |
| Criterio de éxito | ¿Analyze + tests + criterio UX? |
| Restricciones | ¿Tema claro/oscuro? ¿Offline? |
| Dependencias | ¿API lista en backend `dev`? |
| Riesgos | ¿BuildContext async? ¿Permisos cámara? |
| Contexto | ¿Stitch assets? ¿Walkthrough previo? |

## Casos típicos proyecto

- Onboarding + KYC UI
- Chat legibilidad / realtime
- Marketplace filtros y cards
- Mi Perfil / documentos rancho

---

## Overlay Zonix Glasses Front — deep-interview-ops

Clarificar UX try-on, permisos cámara, offline catálogo, multi-tenant óptica aliada.
