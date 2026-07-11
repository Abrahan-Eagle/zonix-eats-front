---
name: fan-out-synthesize-ops
description: >
  Orquestación por defecto JARVIS: Map-Reduce agentico / Fan-out-and-synthesize — N subagentes en paralelo
  recaudan contexto → sesión principal (orquestador) sintetiza → writer único aplica → verify.
  Trigger: tarea no trivial, explorar codebase, investigar bug, auditoría módulo, feature multi-archivo.
license: UNLICENSED
metadata:
  author: JARVIS Global
  version: "1.0"
  scope: [global]
  category: ops
  auto_invoke:
    - "Cualquier tarea no trivial"
    - "Explorar codebase"
    - "Investigar bug"
    - "Auditoría módulo"
    - "Implementar feature multi-archivo"
  triggers: fan-out, fan out, map-reduce, scatter-gather, orchestrator worker, subagentes paralelos, fan-out-and-synthesize, synthesize workers
  related-skills:
    - jarvis-core
    - jarvis-experts
    - agent-loop-engineering
    - parallel-judge-ops
    - doubt-driven-development
    - human-in-the-loop-ops
    - verification-before-completion
    - systematic-debugging
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash, Task]
---

## JARVIS / Cursor (mandatory)

- **Precedencia:** `jarvis-core` > `jarvis-experts` > esta skill. Gobernanza de coste: `human-in-the-loop-ops`.
- **Workers = Task** en **un mismo mensaje** desde la sesión principal. Research/review: `readonly: true`. Implementación: un writer sin readonly.
- **Prohibido** anidar Task desde un subagent — escalar a la sesión principal.
- **Verify adversarial:** fase Verify de alto riesgo → `parallel-judge-ops` (especialización de esta skill).
- **Duda in-flight (1 decisión):** `doubt-driven-development` — no sustituye fan-out general.
- Doc de origen: [docs/LOOP_AI_ECOSYSTEM.md](../../../docs/LOOP_AI_ECOSYSTEM.md) — patrón Fan-out-and-synthesize.

# Fan-out Synthesize Ops (Map-Reduce agentico)

## Overview

Patrón de orquestación **obligatorio** para tareas no triviales en JARVIS:

1. **Slice** — el orquestador (sesión principal) descompone la tarea en slices **independientes** (sin orden ni estado compartido mutable).
2. **Fan-out** — lanza **N ≥ 2** subagentes en **paralelo** (un solo turno, múltiples Task).
3. **Barrier** — espera todas las salidas antes de continuar.
4. **Synthesize** — orquestador consolida: dedup, resuelve conflictos, identifica gaps, decide siguiente paso.
5. **Write** (opcional) — **un** writer thread aplica cambios (nunca N writers en paralelo sobre el mismo árbol).
6. **Verify** — fan-out de reviewers o `parallel-judge-ops` antes de declarar listo.

Sinónimos aceptados: **Fan-out-and-synthesize** (Anthropic), **Map-Reduce agentico**, **Scatter-Gather**.

El orquestador mantiene el hilo **delgado**: no hace exploración pesada inline cuando puede delegar workers paralelos.

## Cuándo es obligatorio

- Explorar, planificar, implementar, auditar, debuggear o cerrar un módulo.
- Leer **4+ archivos** o tocar **2+ archivos no triviales**.
- Investigación amplia, auditoría 360°, feature multi-capa (API + UI + tests).
- Cualquier tarea donde el usuario no pidió explícitamente respuesta directa y trivial.

## Cuándo está exento

- **Trivial:** sí/no, typo, rename mecánico, una línea obvia, confirmación.
- Usuario pide **respuesta directa** sin delegación ("solo dime X").
- **Token budget agotado** o tarea requiere >4 workers → escalar al usuario (`human-in-the-loop-ops`).
- Subagent activo (no puede fan-out) → escalar a sesión principal.

## Procedimiento

```
Fan-out-and-synthesize:
- [ ] 1. SLICE — descomponer en 2–4 slices independientes + criterio de éxito por slice
- [ ] 2. FAN-OUT — lanzar N Task en un mismo mensaje (readonly salvo writer dedicado)
- [ ] 3. BARRIER — recoger todas las salidas; no actuar con partial results salvo emergencia
- [ ] 4. SYNTHESIZE — dedup, conflictos, gaps, decisión (plan / fix / escalar)
- [ ] 5. WRITE — un writer si hay cambios de código (gate humano si irreversible)
- [ ] 6. VERIFY — 2+ reviewers o parallel-judge-ops → verification-before-completion
```

### 1. Slice (descomponer)

Antes de lanzar workers, escribe en 3–5 líneas:

- Objetivo global medible.
- Lista de slices (cada uno **independiente**, ángulo distinto).
- Qué **no** incluye cada slice (evitar solapamiento).

Ejemplo auditoría módulo commerce:

| Worker | Slice |
|--------|-------|
| W1 | Rutas + controllers + contrato API |
| W2 | Services + state machine + tests backend |
| W3 | Front services + pantallas + errores API |

### 2. Fan-out (workers paralelos)

- **N default:** 2–4 según complejidad. Máximo 4 por vuelta; más → segunda vuelta o escalar.
- **Un solo mensaje** con N invocaciones Task.
- Cada prompt incluye: slice acotado, criterio de éxito, rutas/paths, **sin** veredicto esperado.
- Workers **no** saben que existen otros workers.

**Roster por fase:**

| Fase | Workers sugeridos | readonly |
|------|-------------------|----------|
| **Explore** | 2–3× `explore` (quick/medium/thorough según alcance) | sí |
| **Plan** | dominio producto + riesgos/AppSec en paralelo | sí |
| **Implement** | explore paralelo **antes** de escribir; luego 1× writer | explore sí, writer no |
| **Debug** | 2–3 hipótesis independientes (`explore` o `generalPurpose`) | sí |
| **Verify** | 2+ reviewers o `parallel-judge-ops` | sí |
| **Audit** | por capa/módulo/rol (API, tests, front, seguridad) | sí |

Skills dominio del producto (`{producto}-*`) van en el **prompt** del worker, no sustituyen el patrón.

### 3. Barrier

No implementes ni cierres con resultados parciales. Si un worker falla o timeout, relanzar ese slice o escalar.

### 4. Synthesize (orquestador)

La sesión principal **relee** y decide — no rubber-stamp:

- **Dedup** — mismo hallazgo en varios workers → sube prioridad.
- **Conflictos** — releer código/artefacto; disenso es señal, no votación por mayoría.
- **Gaps** — slice vacío o insuficiente → segunda vuelta fan-out acotada.
- **Salida:** plan accionable, lista de fixes, o pregunta al usuario si bloqueado.

### 5. Write (writer único)

- **Un** subagente (o sesión principal) escribe código tras síntesis.
- Nunca dos writers en paralelo sobre los mismos archivos.
- Fixes irreversibles (push, deploy, migración prod) → gate humano (`git-guardrails-ops`).

### 6. Verify

- Diff no trivial → fan-out 2+ reviewers **o** `parallel-judge-ops`.
- Cerrar con `verification-before-completion` (evidencia fresca del stack).

## Terminación (definir antes de correr)

```markdown
## Loop termination (fan-out-synthesize)
- Success: síntesis completa + verify green + verification-before-completion
- Workers por vuelta: N (2–4, max 4)
- Max fan-out rounds: R (default 2; escalar a humano si insuficiente)
- Token budget: documentar si sesión larga; pausar y handoff si agotado
- Gate: acciones irreversibles requieren OK humano
```

Ver `human-in-the-loop-ops` para umbrales HITL/HOTL.

## Relación con otras skills

| Skill | Relación |
|-------|----------|
| `parallel-judge-ops` | Especialización **Verify** adversarial (2+ jueces, loop re-juicio) |
| `doubt-driven-development` | 1 revisor fresco **in-flight** sobre una decisión — complemento, no sustituto |
| `agent-loop-engineering` | Diseño de loops que **contienen** fan-out como paso |
| `jarvis-experts` | Delegation triggers alineados a fan-out obligatorio |
| `systematic-debugging` | Si entorno/git/tests confuso → parar fan-out y auditar primero |

## Anti-patrones

- Orquestador lee 6+ archivos secuencialmente en hilo principal sin Task paralelo.
- **Un solo worker** cuando la tarea claramente tiene 2+ ángulos independientes.
- Slices **solapados** (dos workers revisan lo mismo) — desperdicio de tokens.
- **Rubber-stamp** en síntesis (aceptar reportes sin releer artefactos).
- **N writers** en paralelo sobre el mismo módulo.
- Fan-out para typo / sí-no / una línea (coste > beneficio).
- Anidar Task desde subagent.

## Skills relacionadas

- `jarvis-core` — precedencia y flujo modular.
- `jarvis-experts` — roles + delegation triggers.
- `agent-loop-engineering` — loops que embeden fan-out.
- `parallel-judge-ops` — verify adversarial.
- `human-in-the-loop-ops` — coste, terminación, gates.
- `verification-before-completion` — cierre con evidencia.
