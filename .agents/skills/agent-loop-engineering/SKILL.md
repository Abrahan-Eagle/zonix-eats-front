---
name: agent-loop-engineering
description: >
  Diseño de loops de agente concisos, reducidos y controlados: anatomía estímulo→iteración→stop,
  cuándo loop vs prompt, tipos de loop y mapeo a skills JARVIS.
  Trigger: agent loop engineering, diseñar un loop, no hagas prompts haz loops, goal mode, iterar hasta lograr objetivo.
license: UNLICENSED
metadata:
  author: JARVIS Global
  version: "1.0"
  scope: [global]
  category: engineering
  auto_invoke:
    - "Diseñar loop de agente"
    - "Agent loop engineering / no prompts haz loops"
    - "Decidir loop vs prompt simple"
    - "Iterar hasta lograr un objetivo medible"
  triggers: agent loop, agent loop engineering, loop vs prompt, goal mode, iterar hasta objetivo, no prompts haz loops
  related-skills:
    - jarvis-core
    - skill-loop-router
    - human-in-the-loop-ops
    - parallel-judge-ops
    - fan-out-synthesize-ops
    - test-driven-development
    - doubt-driven-development
    - verification-before-completion
    - jarvis-experts
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash, Task]
---

## JARVIS / Cursor (mandatory)

- **Precedencia:** `jarvis-core` > esta skill. Es disciplina de **diseño**, no ejecuta el loop por sí sola.
- **Gobernanza:** todo loop autónomo pasa por `human-in-the-loop-ops` (modo, terminación, gates) **antes** de correr.
- **Ejecución:** loop declarativo YAML+CLI → `skill-loop-router` → skill `skill-loop`. Orquestación paralela por defecto → `fan-out-synthesize-ops`. Verificación adversarial paralela → `parallel-judge-ops`.
- **Plataforma:** `/loop`, `/goal`, `goal mode` y dynamic workflows **no existen** en Cursor. Aproximación JARVIS: Task subagents + `using-git-worktrees` + `skill-loop` + `human-in-the-loop-ops`.
- Doc de origen: [docs/GENTLE_AI_LOOP_INTEGRATION.md](../../docs/GENTLE_AI_LOOP_INTEGRATION.md). Mapa: [docs/LOOP_AI_ECOSYSTEM.md](../../docs/LOOP_AI_ECOSYSTEM.md).

# Agent Loop Engineering

## Overview

Un **loop de agente** es: ante un estímulo, ejecutar por detrás una iteración interna (invisible al usuario) que **itera sobre sí misma hasta alcanzar un objetivo**. No es un prompt único: es una máquina de estados con criterio de éxito, tope y, casi siempre, un gate humano.

La tesis operativa: la IA es **probabilística, no determinística**. En cada vuelta puede caer en una salida improbable y, acumulando vueltas, **derivar** (goal drift). Por eso el poder no está en "darle todo y volver mañana", sino en loops **concisos, reducidos y controlados**.

## Cuándo usar

- Vas a diseñar o entender un proceso que **itera hasta un resultado** (impl→review→rework, test→fix, generate→judge→fix).
- Estás dudando entre **un prompt** y **un loop**.
- Te ofrecen un "goal mode" (llega al objetivo a cualquier costo de tokens) y quieres una alternativa controlada.
- Quieres mapear un patrón de loop a la skill JARVIS correcta.

**Cuándo NO usar:**

- Tarea de un solo paso con corrección obvia → un prompt directo basta.
- Operación mecánica (rename, formato, mover archivos).
- Ya sabes exactamente qué skill ejecutar (ve directo a `skill-loop` / `parallel-judge-ops`).

## Anatomía de un loop

```
estímulo → [ acción → observación → evaluación ] → ¿stop?
                ↑__________________________________|
                         (itera si no)
```

Todo loop bien diseñado define **cuatro piezas** antes de correr:

1. **Objetivo medible** — criterio de éxito empírico (tests green, sin hallazgos críticos, build OK). Si no se puede medir, no es un loop: es esperanza.
2. **Señal de evaluación** — qué decide continuar/parar en cada vuelta (test runner, judge LLM, lint, rúbrica).
3. **Stop condition + max iterations** — condición de éxito **y** techo de seguridad (escalar a humano al alcanzarlo). Ver `human-in-the-loop-ops`.
4. **Persistencia de estado** — progreso fuera del contexto del chat (`active_context.md`, `LOOP_STATE.md`, salida del CLI) para sobrevivir compactación.

## Principios: conciso, reducido, controlado

| Principio | Qué significa | Anti-patrón |
|-----------|---------------|-------------|
| **Conciso** | Cada vuelta hace **una** cosa verificable | Una vuelta gigante que mezcla impl + review + deploy |
| **Reducido** | Mínimo contexto y mínimo alcance por iteración | Pasar toda la sesión/historial a cada vuelta (acelera el drift) |
| **Controlado** | Criterio de stop + max iterations + gate humano | "Anda, hacé todo y nos vemos" / confiar 100 % |

## Loop vs prompt (decisión)

| Situación | Elige |
|-----------|-------|
| Resultado verificable que requiere varias pasadas | **Loop** |
| Salida única, corrección obvia | **Prompt** |
| Objetivo claro pero camino incierto, alto valor | **Loop** con max iterations + gate |
| "Goal mode" (cualquier costo de tokens) | **Loop acotado** con token budget + escalamiento, no goal mode abierto |

> `goal mode` llega al objetivo pero consume tokens sin techo. En JARVIS: replícalo como loop-until-done **con `token budget` y `max iterations`** documentados en `human-in-the-loop-ops`.

## Tipos de loop → skill JARVIS

| Patrón | Descripción | Skill / herramienta |
|--------|-------------|---------------------|
| **Test-driven loop** | test que falla → código → triangula (happy path, edge cases) → refactor → repite hasta green | `test-driven-development` + `verification-before-completion` |
| **Impl→review→rework** | loop declarativo multi-skill (YAML + router LLM) | `skill-loop-router` → `skill-loop` + CLI |
| **Judge-evaluate-iterate** | evaluador adversarial con rúbrica → fixes → re-juzga | `doubt-driven-development` (in-flight) |
| **Jueces paralelos ("día del juicio")** | 2+ jueces independientes → orquestador valida → fix → itera | `parallel-judge-ops` |
| **Fan-out + síntesis (default JARVIS)** | N subagentes en paralelo → barrera → orquestador sintetiza → writer único | **`fan-out-synthesize-ops`** |
| **Loop largo / overnight** | iterar con tests + stop hook | `skill-loop` + `human-in-the-loop-ops` + `create-hook` |

## Procedimiento

1. **Enmarca el objetivo** en 1–2 líneas con criterio de éxito **medible**.
2. **Decide loop vs prompt** con la tabla de arriba. Si es prompt, sal de esta skill.
3. **Elige el tipo de loop** y su skill JARVIS.
4. **Define gobernanza** con `human-in-the-loop-ops`: modo (HITL/HOTL/automation-bounded), stop condition, max iterations, token budget, acciones irreversibles con gate.
5. **Define persistencia** de estado entre vueltas (para sobrevivir compactación; ver engram en el doc de integración).
6. **Ejecuta** vía la skill elegida (con OK del usuario si es `skill-loop run` o aplica fixes irreversibles).
7. **Cierra** con `verification-before-completion` y `session-learner-ops`.

## Delegation triggers

Cuando el loop crece más allá de una vuelta pequeña, aplicar `fan-out-synthesize-ops` y la tabla de `jarvis-experts` (fuente: gentle-ai): exploración 4+ archivos → 2+ Task explore en paralelo; 2+ archivos no triviales → fan-out explore → writer único + verify; commit/PR → verificación; sesión monolítica → pausar o re-orquestar.

## Anti-patrones

- **Confiar 100 % en la IA** ("commit, push, todo a prod, nos vemos mañana") — la IA deriva; el humano sigue siendo responsable.
- **Goal mode abierto** sin token budget ni max iterations — caro e impredecible.
- **Loop sin criterio de éxito medible** — no sabes cuándo parar.
- **Vuelta gorda** que mezcla varias responsabilidades — rompe "conciso".
- **Re-correr el mismo artefacto sin cambio** esperando otro resultado — solo quema tokens.
- **Loop sin gate** en acciones irreversibles — ver `git-guardrails-ops`, `approval-gate`.
- **Juez único** para auto-evaluarse (self-preferential bias) — usa `parallel-judge-ops` o `doubt-driven-development`.

## Skills relacionadas

- `jarvis-core` — precedencia y alcance.
- `jarvis-experts` — delegation triggers (hilo orquestador delgado).
- `human-in-the-loop-ops` — gates, terminación, umbrales.
- `skill-loop-router` / `skill-loop` — ejecución de loops YAML+CLI.
- `parallel-judge-ops` — patrón dual-judge ("día del juicio"; fase Verify).
- `fan-out-synthesize-ops` — orquestación Map-Reduce por defecto.
- `test-driven-development`, `doubt-driven-development`, `verification-before-completion` — señales de evaluación.
