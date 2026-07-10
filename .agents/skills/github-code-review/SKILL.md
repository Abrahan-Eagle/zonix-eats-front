---
name: github-code-review
description: >
  DEPRECATED — usar code-review-playbook. Stub de compatibilidad para manifests legacy.
  Trigger: Code review GitHub (redirige a playbook).
license: UNLICENSED
metadata:
  author: JARVIS Global
  version: "2.0.0"
  scope: [global]
  category: review
  status: deprecated
  superseded_by: code-review-playbook
  auto_invoke:
    - "Code review GitHub"
  triggers: github code review, deprecated
  related-skills:
    - code-review-playbook
    - branch-pr-ops
    - comment-writer-ops
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

# github-code-review (DEPRECATED)

**No usar.** Canónico: [`code-review-playbook`](../code-review-playbook/SKILL.md).

Archivo histórico: [`archive/skills/review/github-code-review/`](../../../archive/skills/review/github-code-review/).

Para PRs: `code-review-playbook` + `branch-pr-ops` + `gh`. No requiere `ruv-swarm` / Claude Flow.
