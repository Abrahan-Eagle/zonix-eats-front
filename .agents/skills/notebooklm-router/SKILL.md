---
name: notebooklm-router
description: >
  Orquesta consulta RAG a Google NotebookLM (corpus grande/duradero con citas)
  vía MCP `notebooklm-mcp` vs subida directa al contexto y vs Engram (memoria
  cross-session). Trigger: notebooklm, consultar notebook, RAG con citas,
  corpus grande, nlm setup, nlm login.
license: UNLICENSED
metadata:
  author: JARVIS Global
  version: "1.0"
  scope: [global]
  category: core
  auto_invoke:
    - "Consultar NotebookLM / notebook con citas"
    - "Configurar NotebookLM MCP en Cursor"
    - "Corpus grande de documentos para RAG"
    - "nlm login nlm setup add cursor"
  triggers: notebooklm, nlm, notebook_query, rag citations, knowledge base, nlm setup
  related-skills:
    - engram-router
    - context-updater
    - jarvis-core
    - sdd-router
    - ui-router
allowed-tools: [Read, Edit, Write, Glob, Grep, Bash]
---

# NotebookLM Router

Router para [NotebookLM](https://notebooklm.google.com/) vía MCP
[`notebooklm-mcp-cli`](https://github.com/jacob-bd/notebooklm-mcp-cli) (MIT).
**Opt-in** — complementa Engram (memoria cross-session) y la subida directa de
documentos al contexto del agente. No es API pública: automatiza Chrome y
reutiliza cookies tras un login único.

Guía: [docs/NOTEBOOKLM_INTEGRATION.md](../../../docs/NOTEBOOKLM_INTEGRATION.md).

## Gate MCP (obligatorio)

Antes de consultar notebooks:

1. **Config Cursor:** `nlm setup add cursor` (o `bash scripts/install-notebooklm-runtime.sh`).
2. **Auth:** `nlm login` una vez — cuenta Google **secundaria** (cookies en `~/.notebooklm-mcp-cli`).
3. **Diagnóstico:** `nlm doctor` → healthy + auth OK.
4. **Reiniciar** Cursor y comprobar Settings → Tools & MCP: `notebooklm-mcp` verde **con tools** (punto verde + 0 tools = NO operativo).
5. **Smoke:** tool `notebook_list` — devuelve notebooks sin error auth.

| Resultado | Acción |
|-----------|--------|
| Tools visibles + `notebook_list` OK | Continuar → `notebook_query` |
| Punto verde pero 0 tools | Reinstalar `uv tool install --force notebooklm-mcp-cli`; revisar PATH |
| Sin servidor MCP | **STOP** — guiar `install-notebooklm-runtime.sh` |
| Error auth / perfil no encontrado | **STOP** — `nlm login` de nuevo; verificar perfil |
| `nlm` no encontrado | `uv tool install notebooklm-mcp-cli` o `uvx --from notebooklm-mcp-cli nlm ...` |

## Detección runtime

```bash
command -v nlm >/dev/null 2>&1 && nlm --version 2>/dev/null && echo NLM_CLI
command -v notebooklm-mcp >/dev/null 2>&1 && echo NLM_MCP_BIN
test -d "${HOME}/.notebooklm-mcp-cli" && echo NLM_AUTH_DIR
test -f skills/core/notebooklm-router/SKILL.md && echo NLM_SKILL_LIBRARY
test -d "${HOME}/.cursor/skills/notebooklm-router" && echo NLM_SKILL_INSTALLED
```

Install runtime: `bash scripts/install-notebooklm-runtime.sh` (OK usuario).

## Árbol de decisión

| Pedido | Ruta | No usar |
|--------|------|---------|
| Corpus grande/duradero con citas | **esta skill** → `notebook_query` | subir todo al contexto |
| Pocos PDFs (<5) que caben en contexto | subida directa al agente | NotebookLM (overkill) |
| Decisión/bugfix cross-session | `engram-memory-protocol` | NotebookLM (no es memoria de agente) |
| Especificación de producto | `speckit-specify` / `sdd-router` | NotebookLM como SSOT de spec |
| Walkthrough sesión / active_context | `session-learner-ops`, `context-updater` | NotebookLM |
| Audio overview / podcast del notebook | `studio_create` (MCP) | agente directo sin router |
| Crear notebook desde spec/markdown | `notebook_create` + `source_add` | hand-rolling JSON |

## Flujo recomendado (Cursor)

1. Usuario quiere RAG sobre corpus → `bash scripts/install-notebooklm-runtime.sh`.
2. `nlm login` (cuenta secundaria) — una vez.
3. Reiniciar Cursor para cargar MCP.
4. Para queries: tool `notebook_query` con `notebook_id` y pregunta.
5. **Desactivar** el servidor MCP en Settings → Tools & MCP cuando no se use (39 tools = contexto).

## Cuándo NO usar NotebookLM

- Tareas Flutter rutinarias (CorralX, Zonix, ZonixGlasses) salvo spec/notebook dedicado.
- Backend/API sin corpus documental.
- Memoria cross-session del agente → Engram.
- Specs de producto → Spec Kit.

## Limitaciones

- Requiere `nlm`/`notebooklm-mcp` binario + MCP habilitado en Cursor + auth Google.
- APIs internas de Google (no documentadas, pueden romper sin aviso).
- Cookies de Google en `~/.notebooklm-mcp-cli` — cuenta secundaria recomendada.
- 39 tools MCP — gestionar contexto del agente; desactivar si no se usa.

## Skills relacionadas

- `engram-router` — memoria persistente (decisión/bugfix), no RAG documental.
- `sdd-router` — specs de producto (canon SDD), no NotebookLM como SSOT.
- `context-updater` — memoria file-based por sesión.
