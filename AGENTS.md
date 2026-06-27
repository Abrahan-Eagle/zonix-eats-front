# AGENTS.md - Zonix Glasses Frontend (Flutter)

> Instrucciones para agentes de IA en el frontend móvil de Zonix Glasses.
> Mantenimiento de skills: [MAINTENANCE_SKILLS.md](MAINTENANCE_SKILLS.md).

> **Memoria viva:** [`docs/active_context.md`](docs/active_context.md) — leer al iniciar.

## Cambios recientes

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
| **Estado** | Bootstrap inicial — listo para desarrollo |
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
<!-- SKILLS-END -->

---

## Auto-invoke Skills

<!-- AUTO-INVOKE-START -->
<!-- AUTO-INVOKE-END -->

---

## Repo hermano

Backend API: **`../zonix-glasses-back/AGENTS.md`**

Biblioteca global: **`/var/www/html/proyectos/AIPP/jarvis-skills-library/AGENTS.md`**
