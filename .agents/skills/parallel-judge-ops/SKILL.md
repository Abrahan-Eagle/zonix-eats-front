---
name: parallel-judge-ops
description: >
  Patrón "día del juicio": 2+ jueces adversariales en paralelo e independientes → orquestador valida
  real vs ruido → subagente aplica fixes → itera hasta sin hallazgos o max iterations.
  Trigger: día del juicio, jueces paralelos, verificación adversarial paralela, dual judge, validar artefacto con varios revisores.
license: UNLICENSED
metadata:
  author: JARVIS Global
  version: "1.0"
  scope: [global]
  category: ops
  auto_invoke:
    - "Día del juicio / jueces paralelos"
    - "Verificación adversarial paralela de un artefacto"
    - "Validar diff/PR con 2+ revisores independientes"
  triggers: día del juicio, jueces paralelos, dual judge, parallel judge, verificación adversarial paralela, judgment day
  related-skills:
    - jarvis-core
    - agent-loop-engineering
    - doubt-driven-development
    - code-review-playbook
    - human-in-the-loop-ops
    - llm-as-judge-ops
    - verification-before-completion
    - fan-out-synthesize-ops
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash, Task]
---

## JARVIS / Cursor (mandatory)

- **Precedencia:** `jarvis-core` > `fan-out-synthesize-ops` > esta skill. Esta skill es la **fase Verify adversarial** del patrón fan-out general.
- **Jueces = Task `readonly`** desde la sesión principal (`subagent_type: code-reviewer`, `security-reviewer` o `generalPurpose`). **No anidar Task** desde un subagent: si estás dentro de uno, escala a la sesión principal.
- **Diferencia con `doubt-driven-development`:** doubt-driven es **in-flight** con 1 revisor fresco; esta skill es verificación **adversarial paralela** (2+ jueces independientes) sobre un artefacto terminado o casi.
- **Diferencia con `llm-as-judge-ops`:** un juez + rúbrica + score pre-gate; parallel-judge = 2+ jueces frescos en paralelo.
- **Fixes irreversibles** (push, deploy, migración) requieren gate humano — ver `git-guardrails-ops`, `approval-gate`.
- Doc de origen: [docs/GENTLE_AI_LOOP_INTEGRATION.md](../../../docs/GENTLE_AI_LOOP_INTEGRATION.md).

# Parallel Judge Ops ("día del juicio")

## Overview

Patrón de verificación adversarial: se lanzan **dos o más jueces en paralelo** que **no se conocen entre sí** (contextos aislados), cada uno con el **mismo objetivo y criterios**. Reportan hallazgos clasificados; un **orquestador** decide qué es real vs ruido y lanza un subagente que aplica fixes solo a lo válido. Se **itera** hasta que no queden hallazgos o se alcance el tope.

El valor está en la **independencia**: jueces que comparten contexto comparten puntos ciegos. Varios jueces frescos y separados cubren más superficie que uno solo (y evitan el self-preferential bias de auto-evaluarse).

## Cuándo usar

- Artefacto de **alto valor o alto riesgo** (diff grande, módulo crítico, cambio de API pública) antes de cerrar/mergear.
- Quieres **más cobertura** que una sola revisión y reducir falsos negativos.
- Como paso **`Verify`** dentro de `fan-out-synthesize-ops`, un loop mayor (`skill-loop`, `agent-loop-engineering`), o antes de merge/PR de alto riesgo.

**Cuándo NO usar:**

- Cambio trivial (rename, formato, una línea obvia) → coste injustificado.
- Duda in-flight sobre **una** decisión mientras construyes → `doubt-driven-development`.
- Review estándar pre-merge sin necesidad de paralelismo → `code-review-playbook`.

## Procedimiento

```
Día del juicio:
- [ ] 1. OBJETIVO+CRITERIOS — definidos y compartidos a todos los jueces
- [ ] 2. JUECES — lanzar 2+ Task readonly en paralelo, contextos aislados
- [ ] 3. HALLAZGOS — cada juez devuelve critical / warning / suggestion
- [ ] 4. ORQUESTADOR — consolida, dedup, decide real vs ruido
- [ ] 5. FIX — subagente aplica solo lo válido (gate humano si irreversible)
- [ ] 6. RE-JUICIO — repetir hasta sin hallazgos o max iterations
```

### 1. Objetivo + criterios

Define en pocas líneas **qué** deben revisar y **contra qué** (la rúbrica). Ejemplo: "Verifica que el diff cumple el contrato X; busca race conditions, edge cases no manejados, fugas, y violaciones de convención del repo."

### 2. Lanzar jueces en paralelo

Invoca **2+ Task** en un **mismo mensaje** (paralelos), cada uno `readonly: true`. Pasa **objetivo + criterios + artefacto**, NO el veredicto que esperas. Prompt **adversarial** ("encuentra qué está mal", no "¿está bien?"). Cada juez ignora la existencia de los demás.

Sugerencia de roster (según dominio): `code-reviewer` + `security-reviewer`; o dos `generalPurpose` con rúbricas complementarias.

### 3. Hallazgos clasificados

Cada juez devuelve hallazgos en 3 niveles: **critical** (rompe el contrato), **warning** (riesgo real), **suggestion** (mejora opcional).

### 4. Orquestador decide (real vs ruido)

Tú (sesión principal) **no rubricas a ciegas**. Para cada hallazgo:

- **Dedup** — el mismo problema reportado por varios jueces sube de prioridad.
- **Válido + accionable** → va a fix.
- **Trade-off válido** → documentar, decidir con el usuario.
- **Ruido** → el juez no tenía contexto; descartar y, si conviene, añadir ese contexto a los criterios de la próxima vuelta.

Disenso entre jueces es **información**, no empate a resolver por mayoría: relee el artefacto.

### 5. Aplicar fixes

Lanza un subagente (o aplica directamente) **solo** sobre los hallazgos válidos. Si algún fix es **irreversible**, gate humano antes (`git-guardrails-ops` / `approval-gate`).

### 6. Re-juicio (loop)

Vuelve a juzgar el artefacto corregido. **Para** cuando: no hay hallazgos nuevos sustantivos, **o** se alcanza `max iterations` (escala al usuario, no grindees una vuelta más), **o** el usuario dice "ship it".

## Terminación (definir antes de correr)

```markdown
## Loop termination (parallel-judge)
- Success: 0 hallazgos critical y 0 warning sin resolver
- Jueces por vuelta: N (>=2), independientes
- Max iterations: M (escalar a humano si se alcanza)
- Failure: jueces siguen reportando críticos tras M vueltas → artefacto no listo
- Gate: fixes irreversibles requieren OK humano
```

Ver `human-in-the-loop-ops` para el detalle de umbrales y escalamiento.

## Anti-patrones

- **Juez único** o jueces que comparten contexto → puntos ciegos compartidos.
- **Pasar el veredicto esperado** al juez → sesga hacia aprobación.
- **Rubber-stamp** del orquestador (aceptar todo sin releer el artefacto).
- **Loop sin tope** → re-juzgar indefinidamente.
- **Resolver disenso por mayoría** sin releer.
- **Aplicar fixes irreversibles** sin gate humano.
- Usar este patrón para cambios triviales (coste > beneficio).

## Skills relacionadas

- `fan-out-synthesize-ops` — orquestación Map-Reduce general; esta skill = fase Verify adversarial.
- `agent-loop-engineering` — diseño del loop que contiene este patrón.
- `doubt-driven-development` — variante in-flight con 1 revisor fresco.
- `code-review-playbook` — review estándar pre-merge.
- `human-in-the-loop-ops` — terminación, umbrales, gates.
- `verification-before-completion` — cierre con evidencia fresca.
