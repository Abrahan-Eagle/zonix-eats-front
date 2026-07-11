# AGENTS.md - Zonix Glasses Frontend (Flutter)

> Instrucciones para agentes de IA en el frontend móvil de Zonix Glasses.
> Mantenimiento de skills: [MAINTENANCE_SKILLS.md](MAINTENANCE_SKILLS.md).

> **Memoria viva:** [`docs/active_context.md`](docs/active_context.md) — leer al iniciar.

## Cambios recientes

- **2026-06-27:** Espejo hub back v3.1 — forense doc-vs-doc PASS (repaso subagentes); código congelado; front en pausa hasta post-HITL.
- **2026-06-18:** Proyecto Zonix Glasses; skills globales JARVIS por referencia; paquete `zonix_glasses`, ID nativo `com.zonix.glasses`.

---

## Project Overview

| Métrica | Valor |
| -------- | ----- |
| **Producto** | Zonix Glasses |
| **Framework** | Flutter / Dart |
| **Paquete** | `zonix_glasses` |
| **Plataformas** | Android, iOS, Web |
| **API Backend** | `../zonix-glasses-back/` (Laravel REST) |
| **Estado** | Diseño negocio v3.1 — doc-vs-doc PASS; UI **en pausa** hasta post-HITL legal/seguridad |
| **Agentes IA** | Cursor + skills globales JARVIS |

---

## Contexto entre sesiones

1. `.cursorrules`
2. `AGENTS.md`
3. `docs/active_context.md`
4. `docs/CONTEXTO_IA.md`

---

## Arquitectura (convenciones)

- Estructura modular por features bajo `lib/features/`
- Estado: **Provider** + servicios HTTP
- Config: **`AppConfig.apiUrl`** — sin URLs hardcodeadas
- Auth: headers vía helper compartido (ej. `AuthHelper.getAuthHeaders()`)
- Tiempo real: Pusher + FCM cuando el producto lo requiera

---

## Collaboration Rules

1. **Preguntar** antes de cambios amplios o ambiguos
2. **No push/merge** sin orden explícita
3. **Usuario prueba primero** en emulador/dispositivo
4. Commits solo cuando el usuario lo pida
5. **Skills de dominio:** prefijo `zonix-glasses-*` en `.agents/skills/`

---

## Git Workflow

`dev` → pruebas → `main` → producción

---

## Setup Commands

```bash
flutter pub get
flutter run -d <device>
flutter analyze
flutter test
```

Variables de entorno: [docs/ENV_VARIABLES.md](docs/ENV_VARIABLES.md).

---

## Skills — Capas (Paso C activo)

Sincronización: ver [../zonix-glasses-back/docs/ZONIX_GLASSES_JARVIS_INTEGRATION.md](../zonix-glasses-back/docs/ZONIX_GLASSES_JARVIS_INTEGRATION.md).

```bash
export JARVIS_SKILLS_LIBRARY=/var/www/html/proyectos/AIPP/jarvis-skills-library
./scripts/sync-global-skills-from-library.sh && ./scripts/check-global-skills-sync.sh && python3 .agents/skills/sync.sh
```

---

## Available Skills

<!-- SKILLS-START -->
| Skill | Descripción | Ruta |
|-------|-------------|------|
| `agent-loop-engineering` | Diseño de loops de agente concisos, reducidos y controlados: anatomía estímulo→iteración→stop, cuándo loop vs prompt, tipos de loop y mapeo a skills JARVIS. | [.agents/skills/agent-loop-engineering/SKILL.md](.agents/skills/agent-loop-engineering/SKILL.md) |
| `backlog-triage-ops` | Triage de backlog GitHub: auditar issues/PRs abiertos, clasificar disposición (merge, request-changes, close, needs-design), priorizar y generar reporte accionable. | [.agents/skills/backlog-triage-ops/SKILL.md](.agents/skills/backlog-triage-ops/SKILL.md) |
| `brainstorming-ops` | OBLIGATORIO antes de tareas complejas en proyecto activo: pantallas, providers, navegación, flujos KYC/onboarding. Propone alternativas y obtiene aprobación antes de codificar. | [.agents/skills/brainstorming-ops/SKILL.md](.agents/skills/brainstorming-ops/SKILL.md) |
| `branch-pr-ops` | Workflow branch + PR: naming conventional, checklist pre-PR, issue linking, presupuesto review, gh integration. Adaptable al AGENTS.md del repo. | [.agents/skills/branch-pr-ops/SKILL.md](.agents/skills/branch-pr-ops/SKILL.md) |
| `chained-pr-ops` | Divide PRs grandes en cadenas reviewables (stacked o feature-branch chain): regla 400 líneas, diagrama de dependencias, integración gh. | [.agents/skills/chained-pr-ops/SKILL.md](.agents/skills/chained-pr-ops/SKILL.md) |
| `clean-architecture` | Clean Architecture, SOLID principles, dependency injection, separation of concerns. | [.agents/skills/clean-architecture/SKILL.md](.agents/skills/clean-architecture/SKILL.md) |
| `code-review-playbook` | Use this skill when conducting or improving code reviews. Provides structured review processes, conventional comments patterns, language-specific checklists, and feedback templates. | [.agents/skills/code-review-playbook/SKILL.md](.agents/skills/code-review-playbook/SKILL.md) |
| `cognitive-doc-design-ops` | Diseñar docs con baja carga cognitiva: lead with answer, progressive disclosure, checklists para review. | [.agents/skills/cognitive-doc-design-ops/SKILL.md](.agents/skills/cognitive-doc-design-ops/SKILL.md) |
| `comment-writer-ops` | Redactar comentarios de colaboración cálidos y directos: PR, issues, reviews, Slack. | [.agents/skills/comment-writer-ops/SKILL.md](.agents/skills/comment-writer-ops/SKILL.md) |
| `context-packs-ops` | Modos de sesión ligeros research / produce / review (concepto ECC contexts/, sin inyección runtime). Define qué skills primar y qué evitar por modo. | [.agents/skills/context-packs-ops/SKILL.md](.agents/skills/context-packs-ops/SKILL.md) |
| `context-updater` | Actualizar el contexto de sesión para que la IA "recuerde" entre sesiones. Resumir cambios relevantes en docs/active_context.md al cerrar o finalizar una sesión de trabajo significativa. | [.agents/skills/context-updater/SKILL.md](.agents/skills/context-updater/SKILL.md) |
| `deep-interview-ops` | Entrevista socrática antes de tareas ambiguas en proyecto activo. Gate claridad mínima 3.5/5. | [.agents/skills/deep-interview-ops/SKILL.md](.agents/skills/deep-interview-ops/SKILL.md) |
| `docs-alignment-ops` | Alinear documentación con código: docs describen comportamiento actual, mismo PR que el cambio, ejemplos verificables. | [.agents/skills/docs-alignment-ops/SKILL.md](.agents/skills/docs-alignment-ops/SKILL.md) |
| `doubt-driven-development` | Revisión adversarial in-flight de decisiones no triviales: CLAIM → EXTRACT → DOUBT → RECONCILE → STOP. | [.agents/skills/doubt-driven-development/SKILL.md](.agents/skills/doubt-driven-development/SKILL.md) |
| `engram-memory-protocol` | Disciplina de memoria persistente con Engram MCP: mem_save, mem_search, mem_context, cierre de sesión y recuperación post-compactación. | [.agents/skills/engram-memory-protocol/SKILL.md](.agents/skills/engram-memory-protocol/SKILL.md) |
| `engram-router` | Orquesta memoria persistente Engram (MCP) vs context-updater/handoff/active_context JARVIS. | [.agents/skills/engram-router/SKILL.md](.agents/skills/engram-router/SKILL.md) |
| `enhance-prompt` | Transforms vague UI ideas into polished, Stitch-optimized prompts. Enhances specificity, adds UI/UX keywords, injects design system context, and structures output for better generation results. | [.agents/skills/enhance-prompt/SKILL.md](.agents/skills/enhance-prompt/SKILL.md) |
| `executing-plans` | Ejecutar plan Flutter paso a paso. | [.agents/skills/executing-plans/SKILL.md](.agents/skills/executing-plans/SKILL.md) |
| `fan-out-synthesize-ops` | Orquestación por defecto JARVIS: Map-Reduce agentico / Fan-out-and-synthesize — N subagentes en paralelo recaudan contexto → sesión principal (orquestador) sintetiza → writer único aplica → verify. | [.agents/skills/fan-out-synthesize-ops/SKILL.md](.agents/skills/fan-out-synthesize-ops/SKILL.md) |
| `finishing-a-development-branch` | Cerrar feature Flutter: analyze + test, opciones merge/PR. | [.agents/skills/finishing-a-development-branch/SKILL.md](.agents/skills/finishing-a-development-branch/SKILL.md) |
| `flutter-animations` | Comprehensive guide for implementing animations in Flutter. Use when adding motion and visual effects to Flutter apps: implicit animations (AnimatedContainer, AnimatedOpacity, TweenAnimationBuilder), explicit animations (AnimationController, Tween, AnimatedWidget/AnimatedBuilder), hero animations (shared element transitions), staggered animations (sequential/overlapping), and physics-based animations. Includes workflow for choosing the right animation type, implementation patterns, and best practices for performance and user experience. | [.agents/skills/flutter-animations/SKILL.md](.agents/skills/flutter-animations/SKILL.md) |
| `flutter-expert` | Flutter advanced patterns, widgets, lifecycle, state management, performance. | [.agents/skills/flutter-expert/SKILL.md](.agents/skills/flutter-expert/SKILL.md) |
| `git-commit` | Execute git commit with conventional commit message analysis, intelligent staging, and message generation. Use when user asks to commit changes, create a git commit, or mentions "/commit". Supports: (1) Auto-detecting type and scope from changes, (2) Generating conventional commit messages from diff, (3) Interactive commit with optional type/scope/description overrides, (4) Intelligent file staging for logical grouping | [.agents/skills/git-commit/SKILL.md](.agents/skills/git-commit/SKILL.md) |
| `git-guardrails-ops` | Protección git: bloquea push a main, advierte en dev, exige confirmación antes de comandos destructivos. | [.agents/skills/git-guardrails-ops/SKILL.md](.agents/skills/git-guardrails-ops/SKILL.md) |
| `github-code-review` | DEPRECATED — usar code-review-playbook. Stub de compatibilidad para manifests legacy. | [.agents/skills/github-code-review/SKILL.md](.agents/skills/github-code-review/SKILL.md) |
| `handoff` | Compactar la sesion actual en un documento de traspaso para continuar en otro agente o chat. Complementa session-learner-ops (cierre de modulo) y active_context.md. | [.agents/skills/handoff/SKILL.md](.agents/skills/handoff/SKILL.md) |
| `human-in-the-loop-ops` | Gobernanza humana en bucles agénticos: HITL/HOTL/automation-bounded, umbrales de confianza, condiciones de terminación y escalamiento. | [.agents/skills/human-in-the-loop-ops/SKILL.md](.agents/skills/human-in-the-loop-ops/SKILL.md) |
| **`jarvis-core`** | **Protocolo base del sistema JARVIS para cualquier proyecto. Define honestidad, foco de negocio y flujo de trabajo modular.** | [.agents/skills/jarvis-core/SKILL.md](.agents/skills/jarvis-core/SKILL.md) |
| `jarvis-experts` | Panel de Expertos JARVIS (agencia de desarrollo virtual). Define roster de roles, criterios de activación, combinaciones recomendadas y plantilla de declaración. | [.agents/skills/jarvis-experts/SKILL.md](.agents/skills/jarvis-experts/SKILL.md) |
| `mobile-developer` | Mobile development patterns, platform-specific code, deep linking, push notifications. | [.agents/skills/mobile-developer/SKILL.md](.agents/skills/mobile-developer/SKILL.md) |
| `notebooklm-router` | Orquesta consulta RAG a Google NotebookLM (corpus grande/duradero con citas) vía MCP `notebooklm-mcp` vs subida directa al contexto y vs Engram (memoria cross-session). | [.agents/skills/notebooklm-router/SKILL.md](.agents/skills/notebooklm-router/SKILL.md) |
| `parallel-judge-ops` | Patrón "día del juicio": 2+ jueces adversariales en paralelo e independientes → orquestador valida real vs ruido → subagente aplica fixes → itera hasta sin hallazgos o max iterations. | [.agents/skills/parallel-judge-ops/SKILL.md](.agents/skills/parallel-judge-ops/SKILL.md) |
| `playwright-skill` | Complete browser automation with Playwright. Auto-detects dev servers, writes clean test scripts to /tmp. Test pages, fill forms, take screenshots, check responsive design, validate UX, test login flows, check links, automate any browser task. Use when user wants to test websites, automate browser interactions, validate web functionality, or perform any browser-based testing. | [.agents/skills/playwright-skill/SKILL.md](.agents/skills/playwright-skill/SKILL.md) |
| `qa-testing-playwright` | E2E web testing with Playwright. Use when writing tests, debugging flakes, or setting up CI with selectors, sharding, and network mocking. | [.agents/skills/qa-testing-playwright/SKILL.md](.agents/skills/qa-testing-playwright/SKILL.md) |
| `react:components` | Converts Stitch designs into modular Vite and React components using system-level networking and AST-based validation. | [.agents/skills/react-components/SKILL.md](.agents/skills/react-components/SKILL.md) |
| `receiving-code-review` | Recibir feedback de review con verificación. Delega estándares a code-review-playbook. | [.agents/skills/receiving-code-review/SKILL.md](.agents/skills/receiving-code-review/SKILL.md) |
| `remotion` | Generate walkthrough videos from Stitch projects using Remotion with smooth transitions, zooming, and text overlays | [.agents/skills/remotion/SKILL.md](.agents/skills/remotion/SKILL.md) |
| `requesting-code-review` | Pedir code review antes de merge. Delega checklist a code-review-playbook. | [.agents/skills/requesting-code-review/SKILL.md](.agents/skills/requesting-code-review/SKILL.md) |
| `responsive-design` | Implement modern responsive layouts using container queries, fluid typography, CSS Grid, and mobile-first breakpoint strategies. Use when building adaptive interfaces, implementing fluid layouts, or creating component-level responsive behavior. | [.agents/skills/responsive-design/SKILL.md](.agents/skills/responsive-design/SKILL.md) |
| `session-learner-ops` | Tras cerrar módulo UI: patrones en docs/active_context.md y walkthrough. | [.agents/skills/session-learner-ops/SKILL.md](.agents/skills/session-learner-ops/SKILL.md) |
| `session-startup-ops` | Protocolo de arranque de sesión (concepto ECC session-start, sin hooks). Checklist: active_context, Engram si activo, Roles/Skills, plan/handoff pendiente. | [.agents/skills/session-startup-ops/SKILL.md](.agents/skills/session-startup-ops/SKILL.md) |
| `shadcn-ui` | Expert guidance for integrating and building applications with shadcn/ui components, including component discovery, installation, customization, and best practices. | [.agents/skills/shadcn-ui/SKILL.md](.agents/skills/shadcn-ui/SKILL.md) |
| `skill-creator` | Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations. | [.agents/skills/skill-creator/SKILL.md](.agents/skills/skill-creator/SKILL.md) |
| `strategic-compact-ops` | Compactación estratégica (concepto ECC strategic-compact, sin hooks). Sugiere compactar en hitos lógicos; preserva decisiones, verificación y TODOs vía handoff + Engram. | [.agents/skills/strategic-compact-ops/SKILL.md](.agents/skills/strategic-compact-ops/SKILL.md) |
| `structured-commits-ops` | Commits con trailers de decisión en proyecto activo. Complementa git-commit. | [.agents/skills/structured-commits-ops/SKILL.md](.agents/skills/structured-commits-ops/SKILL.md) |
| `systematic-debugging` | Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes | [.agents/skills/systematic-debugging/SKILL.md](.agents/skills/systematic-debugging/SKILL.md) |
| `task-pipeline-ops` | Pipeline multi-paso proyecto activo: Plan → Spec → Exec → Verify → Fix (máx. 3). | [.agents/skills/task-pipeline-ops/SKILL.md](.agents/skills/task-pipeline-ops/SKILL.md) |
| `test-driven-development` | Use when implementing any feature or bugfix, before writing implementation code | [.agents/skills/test-driven-development/SKILL.md](.agents/skills/test-driven-development/SKILL.md) |
| `ui-router` | Orquesta precedencia UI/UX: skill dominio del producto, ui-ux-pro-max, responsive-design. | [.agents/skills/ui-router/SKILL.md](.agents/skills/ui-router/SKILL.md) |
| `ui-ux-pro-max` | UI/UX design intelligence: design system generator, 67+ styles, palettes, typography, UX guidelines, charts, google-fonts domain, stacks Flutter/React/Next/Vue/Tailwind/shadcn. | [.agents/skills/ui-ux-pro-max/SKILL.md](.agents/skills/ui-ux-pro-max/SKILL.md) |
| `using-git-worktrees` | Worktree aislado para features Flutter proyecto. Base dev. | [.agents/skills/using-git-worktrees/SKILL.md](.agents/skills/using-git-worktrees/SKILL.md) |
| `verification-before-completion` | OBLIGATORIO antes de declarar cualquier tarea completada en cualquier proyecto. Ejecuta verificación fresca del stack y solo entonces afirma éxito. | [.agents/skills/verification-before-completion/SKILL.md](.agents/skills/verification-before-completion/SKILL.md) |
| `webapp-testing` | Toolkit for interacting with and testing local web applications using Playwright. Supports verifying frontend functionality, debugging UI behavior, capturing browser screenshots, and viewing browser logs. | [.agents/skills/webapp-testing/SKILL.md](.agents/skills/webapp-testing/SKILL.md) |
| `work-unit-commits-ops` | Commits por unidad de trabajo reviewable: un propósito, tests/docs con el código, historia clara. Puente a chained PRs. | [.agents/skills/work-unit-commits-ops/SKILL.md](.agents/skills/work-unit-commits-ops/SKILL.md) |
| `writing-plans` | Plan bite-sized Flutter antes de codificar. .agents/plans/implementation_plan.md | [.agents/skills/writing-plans/SKILL.md](.agents/skills/writing-plans/SKILL.md) |
| **`zonix-glasses-ui-patterns`** | **UI Flutter óptica B2B2C: fórmulas, catálogo monturas, carrito, panel aliado.** | [.agents/skills/zonix-glasses-ui-patterns/SKILL.md](.agents/skills/zonix-glasses-ui-patterns/SKILL.md) |
| **`zonix-glasses-virtual-tryon`** | **Try-on virtual IA: captura rostro, overlay monturas, modo recomendación.** | [.agents/skills/zonix-glasses-virtual-tryon/SKILL.md](.agents/skills/zonix-glasses-virtual-tryon/SKILL.md) |
| `zoom-out` | Explicar código o un cambio en el contexto del sistema completo del proyecto activo (módulos, capas, flujos). Uso bajo demanda. | [.agents/skills/zoom-out/SKILL.md](.agents/skills/zoom-out/SKILL.md) |
<!-- SKILLS-END -->

---

## Auto-invoke Skills

<!-- AUTO-INVOKE-START -->
| Acción | Skill |
|--------|-------|
| Abrir PR con gh | `branch-pr-ops` |
| Actualizar docs tras cambio de código | `docs-alignment-ops` |
| Address review feedback | `receiving-code-review` |
| Agent loop engineering / no prompts haz loops | `agent-loop-engineering` |
| Alta stakes verificar antes de commit | `doubt-driven-development` |
| Auditar open issues como maintainer | `backlog-triage-ops` |
| Auditoría módulo | `fan-out-synthesize-ops` |
| Buscar contexto previo mem_search mem_context | `engram-memory-protocol` |
| Cambio API CLI setup que afecta documentación | `docs-alignment-ops` |
| Cerrar sesión | `context-updater` |
| Cierre sesión con mem_session_summary | `engram-memory-protocol` |
| Clasificar PRs merge request-changes close | `backlog-triage-ops` |
| Code review | `code-review-playbook` |
| Code review GitHub | `github-code-review` |
| Code review antes de merge | `requesting-code-review` |
| Comando git destructivo | `git-guardrails-ops` |
| Compactar contexto | `strategic-compact-ops` |
| Compactar o traspasar sesion | `handoff` |
| Compactar o traspasar sesion | `strategic-compact-ops` |
| Condiciones de terminación bucle autónomo | `human-in-the-loop-ops` |
| Configurar NotebookLM MCP en Cursor | `notebooklm-router` |
| Configurar engram en Cursor | `engram-router` |
| Consultar NotebookLM / notebook con citas | `notebooklm-router` |
| Corpus grande de documentos para RAG | `notebooklm-router` |
| Crear commit | `git-commit` |
| Crear commit | `structured-commits-ops` |
| Crear commit | `verification-before-completion` |
| Crear commit | `work-unit-commits-ops` |
| Crear o preparar pull request | `branch-pr-ops` |
| Cualquier tarea no trivial | `fan-out-synthesize-ops` |
| Cualquier tarea no trivial | `jarvis-experts` |
| Decidir loop vs prompt simple | `agent-loop-engineering` |
| Decisión cross-rol | `jarvis-experts` |
| Decisión no trivial seguridad producción | `doubt-driven-development` |
| Definir alcance de un módulo | `jarvis-experts` |
| Diseñar UI o UX | `ui-router` |
| Diseñar UI o UX | `ui-ux-pro-max` |
| Diseñar loop de agente | `agent-loop-engineering` |
| Dividir diff grande en slices reviewables | `chained-pr-ops` |
| Dividir implementación en commits reviewables | `work-unit-commits-ops` |
| Doc largo, denso o difícil de escanear | `cognitive-doc-design-ops` |
| Día del juicio / jueces paralelos | `parallel-judge-ops` |
| Encontrar bug o test fallido | `systematic-debugging` |
| Escribir descripción de PR o notas para review | `cognitive-doc-design-ops` |
| Escribir feedback de code review para humano | `comment-writer-ops` |
| Estandarizar prácticas de review | `code-review-playbook` |
| Evitar PR monolítico desde SDD tasks | `work-unit-commits-ops` |
| Explorar codebase | `fan-out-synthesize-ops` |
| Gates humanos antes de acción irreversible | `human-in-the-loop-ops` |
| Guardar decisión o bugfix en Engram | `engram-memory-protocol` |
| HITL HOTL umbrales de confianza | `human-in-the-loop-ops` |
| Hacer git push o merge | `git-guardrails-ops` |
| Human-in-the-loop diseño de loop | `human-in-the-loop-ops` |
| Implementar feature multi-archivo | `fan-out-synthesize-ops` |
| Implementar feature o bugfix | `test-driven-development` |
| Iniciar módulo | `brainstorming-ops` |
| Iniciar módulo | `jarvis-core` |
| Iniciar módulo | `task-pipeline-ops` |
| Iniciar módulo | `writing-plans` |
| Iniciar sesión | `session-startup-ops` |
| Investigar bug | `fan-out-synthesize-ops` |
| Iterar hasta lograr un objetivo medible | `agent-loop-engineering` |
| Landing page o dashboard | `ui-router` |
| Landing page o dashboard | `ui-ux-pro-max` |
| Memoria persistente Engram MCP | `engram-router` |
| Modo produce | `context-packs-ops` |
| Modo research | `context-packs-ops` |
| Modo review | `context-packs-ops` |
| Naming de branch y checklist pre-PR | `branch-pr-ops` |
| PR supera 400 líneas o presupuesto de review | `chained-pr-ops` |
| Paleta de colores o tipografía | `ui-router` |
| Paleta de colores o tipografía | `ui-ux-pro-max` |
| Pantalla óptica | `zonix-glasses-ui-patterns` |
| Pedir code review | `requesting-code-review` |
| Planificar desarrollo | `brainstorming-ops` |
| Planificar desarrollo | `jarvis-core` |
| Planificar desarrollo | `writing-plans` |
| Preparar commits antes de abrir PR | `work-unit-commits-ops` |
| Recibir code review | `receiving-code-review` |
| Redactar comentario de PR o issue | `comment-writer-ops` |
| Redactar o mejorar README, RFC, onboarding o guía | `cognitive-doc-design-ops` |
| Requisitos ambiguos | `deep-interview-ops` |
| Respuesta de maintainer o mensaje async al equipo | `comment-writer-ops` |
| Retomar proyecto | `session-startup-ops` |
| Revisar accesibilidad o layout | `ui-router` |
| Revisar accesibilidad o layout | `ui-ux-pro-max` |
| Revisar pull request | `code-review-playbook` |
| Sesión larga sugerir compactación | `strategic-compact-ops` |
| Stacked PRs o chained PRs | `chained-pr-ops` |
| Terminar módulo | `finishing-a-development-branch` |
| Terminar módulo | `jarvis-core` |
| Terminar módulo | `session-learner-ops` |
| Terminar módulo | `verification-before-completion` |
| Triage backlog issues y PRs | `backlog-triage-ops` |
| UI Zonix Glasses | `zonix-glasses-ui-patterns` |
| Validar diff/PR con 2+ revisores independientes | `parallel-judge-ops` |
| Verificación adversarial paralela de un artefacto | `parallel-judge-ops` |
| Verificar que docs igualan comportamiento actual | `docs-alignment-ops` |
| doubt-driven revisión adversarial | `doubt-driven-development` |
| mem_save mem_search contexto entre sesiones | `engram-router` |
| nlm login nlm setup add cursor | `notebooklm-router` |
<!-- AUTO-INVOKE-END -->

---

## Repo hermano

Backend API: **`../zonix-glasses-back/AGENTS.md`**

Biblioteca global: **`/var/www/html/proyectos/AIPP/jarvis-skills-library/AGENTS.md`**
