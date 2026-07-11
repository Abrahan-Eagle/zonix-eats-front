---
name: docs-alignment-ops
description: >
  Alinear documentación con código: docs describen comportamiento actual, mismo PR que el cambio,
  ejemplos verificables. Trigger: cambio API/CLI/setup, actualizar docs, docs desactualizados.
license: Apache-2.0
metadata:
  author: JARVIS Global (patch)
  version: "1.0-jarvis"
  scope: [global]
  category: ops
  upstream: Gentleman-Programming/engram:docs-alignment
  auto_invoke:
    - "Actualizar docs tras cambio de código"
    - "Verificar que docs igualan comportamiento actual"
    - "Cambio API CLI setup que afecta documentación"
  triggers: docs alignment, documentación desactualizada, update docs with code, docs match code
  related-skills:
    - jarvis-core
    - speckit-converge
    - verification-before-completion
    - branch-pr-ops
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

## JARVIS / Cursor (mandatory)

- **Precedencia:** `jarvis-core` > esta skill. Brownfield spec gaps: `speckit-converge`.
- **Mismo PR:** docs del cambio van con el código que las afecta (`work-unit-commits-ops`).
- Doc: [docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md](../../../docs/GENTLEMAN_ECOSYSTEM_INTEGRATION.md).

# Docs Alignment Ops

## Cuándo usar

- Cambio de API, CLI, setup, plugins o flujos de usuario/contribuidor.
- Ejemplos en README/docs que ya no ejecutan.
- Referencias a archivos/endpoints/scripts deprecados.

## Reglas de alineación

1. **Comportamiento actual**, no intención futura.
2. **Mismo PR** (o mismo commit work-unit) que el cambio de código.
3. **Validar ejemplos** — comandos documentados deben ejecutarse como están escritos.
4. **Eliminar referencias** a paths, endpoints o scripts obsoletos.

## Checklist de verificación

- [ ] Nombres de endpoints/rutas coinciden con el código.
- [ ] Nombres de scripts coinciden con paths del repo.
- [ ] Comandos de ejemplo probados (evidencia fresca — `verification-before-completion`).
- [ ] Notas cross-agent (Cursor/Claude/OpenClaw) siguen siendo precisas.
- [ ] AGENTS.md del producto actualizado si cambia auto-invoke o convenciones.

## Procedimiento

1. Identificar superficie afectada (README, `docs/`, AGENTS.md, comentarios de API).
2. Actualizar docs en el mismo work unit que el código.
3. Ejecutar ejemplos documentados.
4. Buscar referencias rotas (`grep` paths/endpoints viejos).

## Anti-patrones

- "Docs en follow-up PR".
- Documentar feature no mergeada como si existiera.
- Copiar docs de otro producto sin adaptar paths.

## Skills relacionadas

- `speckit-converge` — gaps spec vs código post-implement.
- `branch-pr-ops` — incluir docs en checklist del PR.
