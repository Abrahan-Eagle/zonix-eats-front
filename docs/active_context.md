# Contexto activo de sesión — Zonix Eats Frontend

> **Uso:** La IA debe leer este archivo al iniciar o retomar trabajo en el proyecto para recuperar el estado reciente sin depender de que el usuario lo pida.
> La skill **context-updater** indica cómo actualizar este archivo al cerrar una sesión relevante.

---

## Última actualización de contexto

*(La skill **context-updater** rellena esta sección al final de sesiones con cambios relevantes. Si está vacía, no hay resumen pendiente.)*

- **Fecha:** 1 Abril 2026
- **Resumen:** Módulo Tiempo Real y Notificaciones reforzado para cierre técnico 9.6/10 y ruta segura a 10/10. Se centralizó normalización de eventos y dedupe fuerte por `event_id` en capa realtime (`realtime_event_utils.dart` + integración en `PusherService`), con compatibilidad para payload legacy y descarte básico de eventos fuera de orden por `order_id`. Se alineó consumo de eventos en pantallas buyer (`orders_page`, tracking en `order_detail/current_order_detail`), se mitigó ruido de notificaciones foreground (`main.dart` + `NotificationService`) y se retiró expectativa inválida de `OrderPendingAssignment` en delivery-agent. Validación técnica: tests específicos de dedupe/normalización en verde y analyze sin issues.
- **Áreas tocadas:** `lib/features/services/pusher_service.dart`, `lib/features/services/realtime_event_utils.dart`, `lib/features/services/notification_service.dart`, `lib/main.dart`, `lib/features/screens/orders/orders_page.dart`, `lib/features/screens/orders/order_detail_page.dart`, `lib/features/screens/orders/current_order_detail_page.dart`, `lib/features/screens/delivery/delivery_orders_page.dart`, `test/features/services/realtime_event_utils_test.dart`, `AGENTS.md`.
- **Próximos pasos sugeridos:** completar E2E de resiliencia por rol (reconexión, background/terminated, red inestable) y conectar métricas backend a alertado operativo para cerrar 10/10 en operación real.

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
