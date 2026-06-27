---
name: jarvis-experts
description: >
  Panel de Expertos JARVIS (agencia de desarrollo virtual). Define roster de roles,
  criterios de activación, combinaciones recomendadas y plantilla de declaración.
  Trigger: Antes de planificar/ejecutar tareas técnicas o decisiones cross-rol.
license: UNLICENSED
metadata:
  author: JARVIS Global
  version: "2.1"
  scope: [global]
  auto_invoke:
    - "Cualquier tarea no trivial"
    - "Decisión cross-rol"
    - "Definir alcance de un módulo"
  triggers: experto, expertos, agencia, panel, rol, roles, jarvis-experts
  related-skills:
    - jarvis-core
    - agent-loop-engineering
    - fan-out-synthesize-ops
allowed-tools: [Read, Glob, Grep, Task]
---

# Panel de Expertos JARVIS (global)

## Cómo usar

1. **Identifica** 1–3 roles primarios para la tarea.
2. **Declara** al inicio: `> Roles: backend (Laravel) + AppSec`.
3. **Combina** roles secundarios automáticamente cuando la tarea lo exige.
4. **No spam:** no listar el roster entero ni declarar roles en tareas triviales.
5. Tras elegir roles, seguir precedencia en `jarvis-core`.

El roster detallado del **producto activo** está en `AGENTS.md` del repo. Esta skill define el patrón genérico.

## Roster genérico

| Área | Rol | Activar cuando… |
|------|-----|-----------------|
| Dirección | CTO / Tech lead | trade-offs, roadmap, CI/CD |
| Dirección | Arquitecto | diseño sistema, integraciones, escalabilidad |
| Desarrollo | Backend | APIs, servicios, BD, jobs |
| Desarrollo | Frontend / Mobile | UI, estado cliente, navegación |
| Plataforma | DevOps / SRE | deploy, observabilidad, incidentes |
| Calidad | QA / SDET | tests, fixtures, E2E |
| Calidad | AppSec | auth, secretos, OWASP |
| Producto | PM / UX / UX writer | scope, copy, flujos |
| Entrega | Delivery / BA | requisitos, stakeholders |
| Soporte | Technical writer | docs, repro bugs |

## Combinaciones típicas

| Tarea | Combinación |
|-------|-------------|
| Pantalla nueva | frontend + UX writer + a11y |
| Auth / tokens | backend + AppSec |
| Push / realtime | backend + frontend + integraciones |
| Migración BD | backend + DBA |
| Release | DevOps + QA |
| Copy y errores API | UX writer + backend o frontend |

## Especialización por producto

Consultar `AGENTS.md` del repo para dominio (`{producto}-*` skills en `.agents/skills/`).

## Delegation triggers (gentle-ai)

Mantén el hilo orquestador **delgado**. Cuando la tarea deja de ser pequeña, delegar vía **`fan-out-synthesize-ops`** (N workers paralelos → síntesis) es **obligatorio**, no opcional. Fuente: [gentle-ai README](https://github.com/Gentleman-Programming/gentle-ai/blob/main/README.md). Ver también `agent-loop-engineering`.

| Trigger | Comportamiento JARVIS |
|---------|----------------------|
| **Cualquier tarea no trivial** | `fan-out-synthesize-ops`: slice → N≥2 Task paralelos → síntesis → writer único → verify |
| Leer **4+ archivos** para entender un flujo | **Obligatorio** 2+ Task `explore` en **paralelo** (un mensaje); no secuencial en hilo principal |
| Tocar **2+ archivos no triviales** | Fan-out explore → writer único → verify (`fan-out-synthesize-ops` § Implement) |
| Commit, push o PR tras cambios de código | Review fresco salvo diff trivial — `verification-before-completion`; diff grande → `parallel-judge-ops` |
| cwd equivocado, worktree/git accident, merge recovery, test/env confuso | **Parar** y auditar (`systematic-debugging`) antes de continuar fan-out |
| Sesión monolítica larga con complejidad acumulada | Pausar, re-orquestar con fan-out (`handoff`, `brainstorming-ops`) o justificar por qué no |
| Review adversarial de diffs, conflictos, PR readiness o incidentes | Fase Verify: `parallel-judge-ops` o 2+ Task `readonly` (`doubt-driven-development` in-flight si una sola decisión) |

Objetivo: evitar caos accidental con **un orquestador responsable**, **workers paralelos para recaudar** y **un writer thread**.

## Anti-patrones

- Más de 3 roles declarados
- Rol sin justificación (CTO en fix de typo)
- Pedir permiso para activar AppSec en cambio de auth
- Explorar 6 archivos en el hilo principal sin delegar
- Explorar secuencialmente 4+ archivos en hilo principal sin Task paralelo
- Mezclar exploración + implementación + review en una sola vuelta monolítica
- Un solo worker cuando la tarea tiene 2+ ángulos independientes

## Referencias

- `AGENTS.md` del proyecto — roster y reglas locales
- `jarvis-core` — workflow modular
- `fan-out-synthesize-ops` — orquestación paralela obligatoria

---

## Overlay Zonix Glasses Front — jarvis-experts

Roles típicos: `frontend (Flutter) + UX`, `frontend + privacidad` (fotos faciales try-on).
