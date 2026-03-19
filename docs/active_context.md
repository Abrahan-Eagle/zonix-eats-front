# Contexto activo de sesión — Zonix Eats Frontend

> **Uso:** La IA debe leer este archivo al iniciar o retomar trabajo en el proyecto para recuperar el estado reciente sin depender de que el usuario lo pida.
> La skill **context-updater** indica cómo actualizar este archivo al cerrar una sesión relevante.

---

## Última actualización de contexto

*(La skill **context-updater** rellena esta sección al final de sesiones con cambios relevantes. Si está vacía, no hay resumen pendiente.)*

- **Fecha:** 19 Mar 2026
- **Resumen:** Cierre del módulo de comprobante de pago (vista Commerce). En `commerce_order_detail_page.dart`: eliminados los enlaces "Ver comprobante" y "Ver comprobante (PDF)"; botones Validar/Rechazar solo visibles cuando la orden está en `pending_payment`; al rechazar pago se hace `Navigator.pop(context)` para volver al dashboard; si la API devuelve 400 (orden ya cancelada) se recarga y también pop. Sin cambios en backend.
- **Áreas tocadas:** `lib/features/screens/commerce/commerce_order_detail_page.dart`, AGENTS.md, docs/active_context.md.
- **Próximos pasos sugeridos:** Probar flujo completo Buyer→Commerce con Pusher en dispositivo. Verificar badge de notificaciones. Valorar si eventos Review/Dispute migran al patrón Streams. Monitorear Pusher en redes inestables.

---

## Notas

- No borres este archivo; si no hay nada que resumir, deja las secciones con "—".
- Mantén una sola entrada "Última actualización" y reemplázala cada vez (no acumules infinitas entradas).
- Incluye solo lo que ayude a la siguiente sesión: decisiones de diseño, archivos clave modificados, tareas a medio hacer, bloqueos conocidos.
