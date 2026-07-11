---
name: comment-writer-ops
description: >
  Redactar comentarios de colaboración cálidos y directos: PR, issues, reviews, Slack.
  Trigger: feedback de review, respuesta a issue, comentario GitHub o mensaje async al equipo.
license: Apache-2.0
metadata:
  author: JARVIS Global (patch)
  version: "1.0-jarvis"
  scope: [global]
  category: review
  upstream: Gentleman-Programming/gentle-ai:comment-writer
  auto_invoke:
    - "Redactar comentario de PR o issue"
    - "Escribir feedback de code review para humano"
    - "Respuesta de maintainer o mensaje async al equipo"
  triggers: comment writer, PR comment, review feedback, issue reply, collaboration comment, Slack update
  related-skills:
    - jarvis-core
    - code-review-playbook
    - receiving-code-review
    - requesting-code-review
    - cognitive-doc-design-ops
    - chained-pr-ops
allowed-tools: [Read, Glob, Grep, Bash]
---

## JARVIS / Cursor (mandatory)

- **Precedencia:** `jarvis-core` > esta skill. **Proceso de review:** `code-review-playbook`; **estructura del PR body:** `cognitive-doc-design-ops`.
- **Review técnico profundo:** `parallel-judge-ops` genera hallazgos; esta skill **redacta** cómo comunicarlos.
- Doc: [docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md](../../../docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md).

# Comment Writer Ops

## Cuándo usar

Cada vez que escribes un comentario que leerá otro humano:

- Comentarios en PR o issue de GitHub.
- Feedback de review y requested changes.
- Respuestas de maintainer.
- Slack, Discord o updates async del proyecto.

## Reglas de voz

| Regla | Requisito |
|-------|-----------|
| Be useful fast | Punto accionable primero; no recapitular todo el PR antes del feedback |
| Be warm and direct | Compañero reflexivo, no bot corporativo |
| Keep it short | 1–3 párrafos cortos o lista compacta |
| Explain why | Razón técnica al pedir un cambio |
| Avoid pile-ons | El issue de mayor valor, no cada preferencia menor |
| Match target context language | Hilo en español → comentario en español; en inglés → inglés; contexto mixto → idioma del mensaje objetivo. Si el usuario pide idioma/tono explícito, obedecer. Español: neutro/profesional salvo tono regional claro en el hilo |
| No em dashes | Comas, puntos o paréntesis en su lugar |

## Fórmula del comentario

```text
<Observación o petición directa>

<Por qué importa, solo si hace falta>

<Acción concreta siguiente>
```

## Ejemplos

### Pedir cambio

```markdown
Buen enfoque en general. Separaría esto en otro commit porque mezcla lógica de validación con wiring de UI.

Así el revisor se centra en una cosa y el rollback es más limpio si falla la integración.
```

### Aprobar con nota

```markdown
Aprobado. El scope está claro y el cambio está bien acotado.

En el siguiente PR, enlaza el anterior y el siguiente para que la cadena sea navegable.
```

### Pedir split

```markdown
Este PR supera el presupuesto de 400 líneas; hay que partirlo o justificar `size:exception`.

Orden sugerido: base + tests primero, luego integración, luego docs. Cada review con inicio y fin claros.
```

## Comandos

```bash
# Contexto del PR antes de redactar feedback
gh pr view <PR_NUMBER> --json title,body,additions,deletions,changedFiles
```

## Skills relacionadas

- `code-review-playbook` — qué revisar y checklists técnicos.
- `receiving-code-review` / `requesting-code-review` — flujo post-review en producto activo.
- `cognitive-doc-design-ops` — estructura del cuerpo del PR, no comentarios inline.
