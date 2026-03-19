# Contexto activo de sesión — Zonix Eats Frontend

> **Uso:** La IA debe leer este archivo al iniciar o retomar trabajo en el proyecto para recuperar el estado reciente sin depender de que el usuario lo pida.
> La skill **context-updater** indica cómo actualizar este archivo al cerrar una sesión relevante.

---

## Última actualización de contexto

*(La skill **context-updater** rellena esta sección al final de sesiones con cambios relevantes. Si está vacía, no hay resumen pendiente.)*

- **Fecha:** 19 Mar 2026
- **Resumen:** Subida a dev completada (frontend y backend). Frontend: commits de cierre comprobante (Commerce) y feat Pusher Streams, notificaciones, auth, Android/iOS. Backend: seeders reorg, NotificationService, Listeners, .gitignore (venv_scraper, pendrive_badblocks). Documentación: "Cambios recientes" y active_context actualizados en ambos AGENTS.md.
- **Áreas tocadas:** `commerce_order_detail_page.dart`, AGENTS.md, docs/active_context.md (front); backend seeders, Listeners, NotificationService, .gitignore, docs (back).
- **Próximos pasos sugeridos:** Probar flujo completo en dev (Buyer→Commerce, Pusher, notificaciones). Valorar merge a main cuando esté estable. Revisar si .env quedó en historial y, si incluye datos sensibles, sacarlo del repo.

---

## Notas

- No borres este archivo; si no hay nada que resumir, deja las secciones con "—".
- Mantén una sola entrada "Última actualización" y reemplázala cada vez (no acumules infinitas entradas).
- Incluye solo lo que ayude a la siguiente sesión: decisiones de diseño, archivos clave modificados, tareas a medio hacer, bloqueos conocidos.
