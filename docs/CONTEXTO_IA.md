# Contexto para la IA — Cómo mantenerse sincronizado

Este doc explica cómo tener **siempre** el mismo contexto en las herramientas de IA (Cursor, Angravity, Copilot con VS Code) sin depender de que el usuario pida "lee .cursorrules / README".

## Orden de lectura recomendado

1. **.cursorrules** — Reglas de colaboración, stack, roles, recordatorios.
2. **AGENTS.md** — Overview, cambios recientes, skills, índice a documentación detallada.
3. **docs/active_context.md** — Estado de la última sesión (resumen, áreas tocadas, próximos pasos).

La IA debe considerar estos tres como parte del estado actual del proyecto al iniciar o retomar.

## Dónde lee cada herramienta

| Herramienta   | Dónde suele leer contexto                          |
| ------------- | -------------------------------------------------- |
| **Cursor**    | `.cursorrules`, `AGENTS.md` (raíz); opcional `.cursor/rules/` |
| **Angravity** | Depende de la configuración del workspace; usar la misma raíz del repo (AGENTS.md, .cursorrules). |
| **Copilot (VS Code)** | Suele usar el archivo abierto y el repo; para reglas globales, `.github/copilot/` o documentación en raíz. |

## Sincronización

- **Fuente de verdad:** Este repo. `AGENTS.md`, `.cursorrules` y `docs/active_context.md` están en la raíz o en `docs/`.
- Para que Cursor, Angravity y Copilot vean lo mismo: abrir el **mismo directorio del repo** en cada herramienta (recomendado).
- Si usás varias carpetas (back y front por separado), cada una tiene su propio `AGENTS.md` y `docs/active_context.md`; el script `scripts/sync-context-for-ia.sh` puede servir para refrescar fechas o comprobar que los archivos existan.
- Skills: están en `.agents/skills/`. Cursor las referencia desde AGENTS.md. Para Angravity/Copilot, si soportan un directorio de skills, apuntarlo a `.agents/skills/`.

## Actualización del contexto

- **Al cerrar una sesión con cambios relevantes:** usar la skill **context-updater** para actualizar `docs/active_context.md`.
- **Al terminar una tarea:** usar la skill **documentar-avances** para proponer el párrafo de "Cambios recientes" (el usuario aprueba antes de aplicar).
