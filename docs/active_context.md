# Contexto activo de sesión — Zonix Eats Frontend

> **Uso:** La IA debe leer este archivo al iniciar o retomar trabajo en el proyecto para recuperar el estado reciente sin depender de que el usuario lo pida.
> La skill **context-updater** indica cómo actualizar este archivo al cerrar una sesión relevante.

---

## Última actualización de contexto

*(La skill **context-updater** rellena esta sección al final de sesiones con cambios relevantes. Si está vacía, no hay resumen pendiente.)*

- **Fecha:** 11 Abril 2026
- **Resumen:** PDF recibo — `ReceiptPdfBuilder` con doble estrategia de layout: ≤7 ítems sin notas (`Spacer` + `Inseparable`, totales en la misma hoja al pie); más ítems o con notas (`Flexible` + `LimitedBox` + `Stack`, totales anclados al pie en la última hoja de la tabla). Tests de regresión en `receipt_pdf_builder_test.dart`.
- **Áreas tocadas:** `lib/features/screens/orders/receipt_pdf_builder.dart`, `test/features/screens/orders/receipt_pdf_builder_test.dart`, `AGENTS.md`, `docs/active_context.md`.
- **Próximos pasos sugeridos:** si un pedido corto con notas largas mostrara un edge case de paginación, valorar subir umbral o unificar criterios; commit/push cuando el usuario lo indique.

- **Fecha (histórico):** 11 Abril 2026
- **Resumen (histórico):** Cierre módulo **Mis pedidos (activas)**: `orders_page` — lista de pedidos activos múltiples, layout nombre comercio + chip estado debajo, copy en español, sin barra/ETA ficticia en `pending_payment`, CTA contextual; `order_service` — error `ORDER_MAX_CONCURRENT_OPEN`. Coordinado con backend (expiración `pending_payment`, push previo en `dev`).
- **Áreas tocadas (histórico):** `lib/features/screens/orders/orders_page.dart`, `lib/features/services/order_service.dart`.

- **Fecha (histórico):** 7 Abril 2026
- **Resumen:** Remediación plan forense: `main.dart` dividido en `lib/app/main_router.dart`, `fcm_bootstrap.dart`, `fcm_hooks.dart`, `notification_navigation.dart`; accesibilidad básica con `Semantics` en login, órdenes, carrito y checkout.
- **Áreas tocadas:** `lib/main.dart`, `lib/app/*.dart`, `lib/features/screens/auth/sign_in_screen.dart`, `orders/orders_page.dart`, `cart/cart_page.dart`, `cart/checkout_page.dart`, `AGENTS.md`.

- **Fecha (histórico):** 2 Abril 2026
- **Resumen:** Cierre formal del módulo UI/tema (Bloque B): pantallas admin, commerce, delivery y delivery_company alineadas a tema claro/oscuro con `AppColors` y `colorScheme`; tokens `adminHealth*` para el banner de salud en admin dashboard; documentación de prompts maestros y verificación solo estética en `docs/`.
- **Áreas tocadas:** `lib/features/screens/admin/*`, `commerce/*`, `delivery/*`, `delivery_company/*`, `lib/features/utils/app_colors.dart`, `AGENTS.md`, `docs/PROMPT_MAESTRO_*.md`, `docs/PROMPT_VERIFICACION_SOLO_ESTETICA.md`.

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
