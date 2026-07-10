---
name: requesting-code-review
description: >
  Pedir code review antes de merge. Delega checklist a code-review-playbook.
  Trigger: feature lista, pedir review, pre-merge.
license: UNLICENSED
metadata:
  author: JARVIS Global
  version: "1.1.0"
  scope: [global]
  category: review
  auto_invoke:
    - "Pedir code review"
    - "Code review antes de merge"
  triggers: requesting review, pre-merge, pedir review
  related-skills:
    - code-review-playbook
    - receiving-code-review
    - verification-before-completion
    - branch-pr-ops
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

# Requesting code review

Antes de pedir review o abrir PR:

1. Invocar `verification-before-completion` (tests/analyze del stack).
2. Autorevisión con [`code-review-playbook`](../code-review-playbook/SKILL.md).
3. UI (si aplica): tema claro/oscuro, BuildContext tras async, a11y básica + skill de dominio `{producto}-ui-design`.
4. Abrir PR con `branch-pr-ops`.

Canónico de proceso/checklist: **code-review-playbook** (no `github-code-review` / `code-review-excellence`, deprecados).
