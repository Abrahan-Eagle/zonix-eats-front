# Guía de mantenimiento de skills — Zonix Glasses Frontend

Reglas para mantener coherencia del ecosistema IA (skills globales + `.agents/skills/` locales, `AGENTS.md`, `.cursorrules`).

## Skills globales JARVIS

- Canon: `/var/www/html/proyectos/AIPP/jarvis-skills-library`
- Instalación: `bash scripts/install.sh --all` → symlinks en `~/.cursor/skills/`
- Nueva skill **genérica** → `jarvis-skills-library`, **nunca** este repo
- Nueva skill **dominio** → `.agents/skills/zonix-glasses-*`
- **No duplicar** skills globales en `.agents/skills/` — referenciar por nombre en `AGENTS.md`

Actualizar tras pull de la biblioteca global:

```bash
cd /var/www/html/proyectos/AIPP/jarvis-skills-library
bash scripts/validate-all.sh
bash scripts/install.sh --all
```

## Repos hermanos

- **zonix-glasses-front** (Flutter, paquete `zonix_glasses`) — este repo
- **zonix-glasses-back** (Laravel API)

Skills locales opcionales con tooling empaquetado: `playwright-skill`, `enhance-prompt`, `react-components`, etc.

## Reglas al editar skills

1. **Globales:** editar en `jarvis-skills-library` + `install.sh`.
2. **Dominio:** editar en `.agents/skills/zonix-glasses-*/SKILL.md`.
3. Actualizar tabla en `AGENTS.md` si se añade o elimina una skill de dominio.
4. Cross-repo: alinear contratos con el back.

## Infraestructura

- HTTP: `AppConfig.apiUrl` — sin URLs hardcodeadas
- Tiempo real: Pusher + FCM (opcional)
- Estado: Provider + servicios por feature

## Flujo recomendado (IA)

1. Leer `AGENTS.md` y `docs/active_context.md`
2. Skills globales: Cursor las carga desde `~/.cursor/skills/`
3. Skills dominio: leer `.agents/skills/zonix-glasses-*/SKILL.md` bajo demanda
4. Verificar: `flutter analyze` + `flutter test`

**Última actualización:** Junio 2026
