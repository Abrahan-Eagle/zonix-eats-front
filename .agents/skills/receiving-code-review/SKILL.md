---
name: receiving-code-review
description: >
  Recibir feedback de review con verificación. Delega estándares a code-review-playbook.
  Trigger: Comentarios post-revisión, address review feedback.
license: UNLICENSED
metadata:
  author: JARVIS Global
  version: "1.1.0"
  scope: [global]
  category: review
  auto_invoke:
    - "Recibir code review"
    - "Address review feedback"
  triggers: receiving review, address feedback, review comments
  related-skills:
    - code-review-playbook
    - requesting-code-review
    - verification-before-completion
    - comment-writer-ops
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

# Receiving code review

1. Leer cada comentario; clasificar must-fix vs nit.
2. Aplicar cambios; no marcar resuelto sin evidencia.
3. Re-verificar con `verification-before-completion` (tests/analyze).
4. Responder con `comment-writer-ops` (cálido, concreto).

Estándares de calidad: [`code-review-playbook`](../code-review-playbook/SKILL.md).
