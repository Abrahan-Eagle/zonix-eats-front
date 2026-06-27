---
name: human-in-the-loop-ops
description: >
  Gobernanza humana en bucles agénticos: HITL/HOTL/automation-bounded, umbrales de confianza,
  condiciones de terminación y escalamiento. Trigger: human-in-the-loop, HITL, diseñar loop con gates.
license: UNLICENSED
metadata:
  author: JARVIS Global
  version: "1.0"
  scope: [global]
  category: ops
  auto_invoke:
    - "Human-in-the-loop diseño de loop"
    - "Gates humanos antes de acción irreversible"
    - "HITL HOTL umbrales de confianza"
    - "Condiciones de terminación bucle autónomo"
  triggers: HITL, HOTL, human-in-the-loop, gate humano, comprehension debt, cognitive surrender
  related-skills:
    - jarvis-core
    - git-guardrails-ops
    - skill-loop-router
    - learning-loop-router
    - doubt-driven-development
    - code-review-playbook
    - verification-before-completion
    - llm-as-judge-ops
    - parallel-judge-ops
    - approval-gate
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash, Task]
---

# Human-in-the-Loop Ops (HITL)

Gobernanza operativa para bucles agénticos y decisiones autónomas: **cuándo** el humano aprueba, supervisa o queda fuera del bucle.

Guía ecosistema: [docs/LOOP_AI_ECOSYSTEM.md](../../docs/LOOP_AI_ECOSYSTEM.md).

## IRON LAW

1. **`jarvis-core` precede** — esta skill no inicia módulos ni sustituye `speckit-implement` sin OK usuario.
2. **Ninguna acción irreversible** (push/merge, deploy, migración destructiva, publicación RRSS, borrado masivo) sin gate humano **explícito** — ver `git-guardrails-ops`, `approval-gate` (OpenClaw).
3. **Loops autónomos** (`skill-loop run`, `loop-operator`) requieren condiciones de terminación y escalamiento definidas **antes** de ejecutar.
4. **No dictamen legal** — referencias regulatorias (EU AI Act Art. 14) son orientación; consultar asesor humano en sistemas de alto riesgo.

## Espectro de autonomía

| Modo | Mecánica | Cuándo usar | Ejemplos |
|------|----------|-------------|----------|
| **HITL** (guardián) | El agente propone; la acción **bloqueada** hasta aprobación humana explícita | Alto riesgo, irreversible, regulado, datos sensibles | Deploy prod, migración BD, publicación cliente, Rx/farmacéutico, KYC aprobación |
| **HOTL** (supervisor) | El agente actúa autónomo dentro de parámetros; humano observa y puede **override** | Operación continua con dashboard; intervención solo en desviación | CI loops, monitoreo, skill-loop con límite de iteraciones |
| **Automation-bounded** | Sin supervisión ni alertas; dominio de **riesgo cero** reversible | Tareas mecánicas, logs, formateo, tests locales | `flutter analyze`, lint, captura de estado en archivo |

Transición dinámica: si la confianza del agente o del evaluador cae, **escalar** de automation-bounded → HOTL → HITL.

## Umbrales de confianza (heurística)

Usar cuando hay score o veredicto (tests, judge LLM, clasificador):

| Confianza | Ruta |
|-----------|------|
| Alta (ej. tests 100 %, judge sin must_fix) | Continuar en HOTL o automation-bounded |
| Media (ambigüedad, edge cases) | HOTL — presentar resumen al usuario antes del siguiente paso |
| Baja (ej. <70 % o hallazgos críticos) | HITL — bloquear hasta OK explícito |

Documentar el umbral elegido en el plan o en `skill-loop.yml` / handoff.

## Condiciones de terminación de bucle

Antes de `skill-loop run` o loops prolongados, definir:

```markdown
## Loop termination
- Success: <criterio medible> (ej. tests green, speckit-analyze sin gaps críticos)
- Max iterations: <N> (escalar a humano si se alcanza sin success)
- Failure: <condición de abort> (ej. 3 crashes consecutivos, credenciales faltantes)
- Escalation: presentar estado + pedir dirección al usuario (no reintentar el mismo artefacto sin cambio)
- Token budget: <N> tokens máximo si el usuario lo pide (Anthropic dynamic workflows); al alcanzarlo → escalamiento humano
```

**Loop-until-done (Anthropic):** para trabajo de tamaño desconocido, iterar hasta condición de stop explícita (sin hallazgos nuevos, tests green, criterio de rúbrica cumplido) en lugar de un N fijo de pasadas — siempre con **max iterations** como techo de seguridad en `human-in-the-loop-ops`.

Persistir progreso fuera del contexto del chat: `docs/active_context.md`, `.agents/plans/`, `LOOP_STATE.md` en handoff, o salida del CLI del loop.

**Stop-hook como enforcer (L-threads):** bloquear el cierre del turno/loop hasta que pasen tests o exista promesa de completitud verificable — no confiar en que el modelo “cree” que terminó. Implementación en Cursor: skill `create-hook` (hooks `Stop` / `PostToolUse`) — **skill de plataforma Cursor IDE** (`~/.cursor/skills-cursor/`), no catálogo JARVIS global. Complementa max iterations y criterios de éxito documentados arriba.

## Riesgos cognitivos

| Riesgo | Mitigación JARVIS |
|--------|-------------------|
| **Comprehension debt** (código que el equipo no entiende) | `code-review-playbook` obligatorio pre-merge; walkthrough en cierre módulo |
| **Cognitive surrender** (aceptar salidas del modelo sin escrutinio) | `doubt-driven-development` en alta stakes; `verification-before-completion` con evidencia fresca |
| Bucles infinitos / costo | Max iterations + abort documentado; `skill-loop` con `done` explícito |

## Cruces JARVIS

| Necesidad | Skill |
|-----------|-------|
| Push / merge | `git-guardrails-ops` |
| Publicación RRSS / gates AG | `approval-gate` (OpenClaw) |
| Loop YAML impl→review | `skill-loop-router` + OK usuario para `skill-loop run` |
| Aprendizajes sesión | `learning-loop-router` (no sustituye gates irreversibles) |
| Revisión adversarial in-flight | `doubt-driven-development` |
| Review pre-merge | `code-review-playbook` |
| Declarar "listo" | `verification-before-completion` |
| Stop hook que bloquea hasta tests green | `create-hook` (Cursor IDE, no catálogo JARVIS) |

## EU AI Act Art. 14 (referencia)

Sistemas de IA de **alto riesgo** pueden requerir supervisión humana efectiva, competencia del operador y capacidad de intervención. En productos JARVIS (KYC, salud, finanzas): preferir **HITL** en decisiones que afecten personas, y documentar quién aprueba. No sustituye auditoría legal.

## Checklist rápido (diseñar loop)

- [ ] Modo HITL / HOTL / automation-bounded elegido y documentado
- [ ] Criterios de éxito medibles
- [ ] Max iteraciones + ruta de escalamiento
- [ ] Acciones irreversibles listadas con gate humano
- [ ] Persistencia de estado fuera del contexto del chat
- [ ] L-threads: stop hook o verificación automatizada antes de declarar done
- [ ] Review humano planificado antes de merge/deploy
