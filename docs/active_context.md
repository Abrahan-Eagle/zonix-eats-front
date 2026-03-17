# Contexto activo de sesión — Zonix Eats Frontend

> **Uso:** La IA debe leer este archivo al iniciar o retomar trabajo en el proyecto para recuperar el estado reciente sin depender de que el usuario lo pida.
> La skill **context-updater** indica cómo actualizar este archivo al cerrar una sesión relevante.

---

## Última actualización de contexto

*(La skill **context-updater** rellena esta sección al final de sesiones con cambios relevantes. Si está vacía, no hay resumen pendiente.)*

- **Fecha:** 9 Mar 2026
- **Resumen:** Además de cerrar el módulo Exportar datos y el Historial de órdenes (Buyer), se definió e implementó el flujo completo de órdenes lado Buyer: Carrito → `CheckoutPage` (“Finalizar pedido”) sin orden creada → `OrderService.createOrder` crea orden en `pending_payment` → `OrderConfirmationPage` muestra confirmación y botón “Seguir mi pedido” → `CurrentOrderDetailPage` muestra tracking en vivo (estados, mapa, repartidor, dirección y resumen) mientras el comercio valida pago y cocina → al marcarse `delivered` la orden pasa a historial y se abre `OrderHistoryDetailPage` desde `OrdersPage`, con opción “Calificar pedido” que lleva a `OrderRatingPage` (usa BuyerReviewService para comercio y delivery).
- **Áreas tocadas:** `lib/features/DomainProfiles/Profiles/api/profile_service.dart`, `lib/features/DomainProfiles/Profiles/screens/data_export_page.dart`, `lib/features/screens/orders/orders_page.dart`, `lib/features/screens/orders/order_history_detail_page.dart`, `lib/features/screens/orders/current_order_detail_page.dart`, `lib/features/screens/orders/order_confirmation_page.dart`, `lib/features/screens/orders/order_rating_page.dart`, `lib/features/screens/cart/cart_page.dart`, `lib/features/screens/cart/checkout_page.dart`, AGENTS.md, README, .cursorrules, docs/active_context.md.
- **Próximos pasos sugeridos:** Seguir refinando la UI de `CheckoutPage` para que iguale el template `resumen_de_checkout_dark` (card de productos con imagen real, tipografía/paddings idénticos, copy final “Al confirmar, aceptas…”), y después revisar vistas equivalentes en Commerce/Delivery para asegurar que el flujo de estados sea coherente en los tres roles. Commit/push cuando el usuario lo indique.

---

## Notas

- No borres este archivo; si no hay nada que resumir, deja las secciones con "—".
- Mantén una sola entrada "Última actualización" y reemplázala cada vez (no acumules infinitas entradas).
- Incluye solo lo que ayude a la siguiente sesión: decisiones de diseño, archivos clave modificados, tareas a medio hacer, bloqueos conocidos.
