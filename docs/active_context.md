# Contexto activo de sesión — Zonix Eats Frontend

> **Uso:** La IA debe leer este archivo al iniciar o retomar trabajo en el proyecto para recuperar el estado reciente sin depender de que el usuario lo pida.
> La skill **context-updater** indica cómo actualizar este archivo al cerrar una sesión relevante.

---

## Última actualización de contexto

*(La skill **context-updater** rellena esta sección al final de sesiones con cambios relevantes. Si está vacía, no hay resumen pendiente.)*

- **Fecha:** 1 Abril 2026
- **Resumen:** Cierre transversal de hardening frontend aplicado: consumo realtime homogeneizado con `canonicalEventName` en pantallas críticas de órdenes/chat, deduplicación de notificaciones por `eventId` en `NotificationService`, consistencia de URLs de media en detalle de órdenes y eliminación de catches silenciosos críticos en tracking/pagos/onboarding con trazas de diagnóstico. La app queda alineada con el endurecimiento backend de auth/eventos para release estable.
- **Áreas tocadas:** `lib/features/services/notification_service.dart`, `lib/features/screens/orders/order_detail_page.dart`, `lib/features/screens/orders/current_order_detail_page.dart`, `lib/features/screens/orders/buyer_order_chat_page.dart`, `lib/features/screens/onboarding/client_onboarding_flow.dart`, `AGENTS.md`.
- **Próximos pasos sugeridos:** mantener monitoreo de ruido realtime en producción y, tras una ventana estable, simplificar rutas/alias legacy de contratos en conjunto con backend.

---

## Línea base reciente (no es backlog)

- Flujo multi-rol con QR pickup/delivery, auto-asignación, calificaciones; Pusher Streams en órdenes según sesiones previas.

---

## Backlog candidato (no implementado)

Inventario para decidir qué implementar después. **No** implica compromiso hasta aprobación explícita del líder del proyecto.

### Negocio / producto

| Área | Idea | Notas |
|------|------|--------|
| Tiempo | ETA de entrega / preparación | Mejora percepción y soporte al cliente. |
| Operación | Cancelaciones automáticas o reglas más claras | Alinear con políticas ya documentadas. |
| Incentivos | Modelo claro para delivery company / agentes | Comisiones, prioridad, penalizaciones. |
| Cobertura | Zonas / módulo tarifa delivery | Ver plan en repo backend: `docs/PLAN_MODULO_TARIFA_DELIVERY.md`. |
| Monetización | Membresía / comisiones si aplica MVP+ | Revisar `docs/logica-pagos-por-rol.md` en backend. |
| Admin | Panel operativo (zonas, disputas, métricas) | Si el MVP lo requiere. |
| Propinas | Permitir o no | Decisión de negocio. |

### Técnico / mantenibilidad

| Área | Idea | Archivos / notas |
|------|------|------------------|
| Rutas API | Partir `routes/api.php` en backend por dominio | Coordenar con backend. |
| Entrada app | Reducir peso de `lib/main.dart` | Extraer providers / rutas. |
| Datos demo | Acotar seeder demo en backend | — |
| Tests | Ampliar cobertura en flujos críticos | Servicios Flutter + feature tests API. |
| Errores | Manejo centralizado en app | Mejora UX ante fallos de red. |

---

## Prioridad sugerida (siguiente iteración, no comprometida)

1. **Producto:** ETA visible (preparación / entrega aproximada) — pantallas buyer/commerce cuando exista API.
2. **Técnico:** Refactor de rutas en backend + aligerar `main.dart` en front si aplica.

Alternativa: módulo tarifa de delivery (plan en backend `docs/PLAN_MODULO_TARIFA_DELIVERY.md`).

---

## Notas

- No borres este archivo; si no hay nada que resumir, deja las secciones con "—".
- Mantén una sola entrada "Última actualización" y reemplázala cada vez (no acumules infinitas entradas).
- Incluye solo lo que ayude a la siguiente sesión: decisiones de diseño, archivos clave modificados, tareas a medio hacer, bloqueos conocidos.
