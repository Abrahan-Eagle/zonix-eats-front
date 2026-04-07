# Prompts Stitch — flujo comprador (un archivo por pantalla)

**Herramienta:** [Stitch](https://stitch.withgoogle.com) — pega el bloque **Prompt para Stitch** de cada `.md` en el generador.

| # | Archivo | Pantalla / widget Flutter |
|---|---------|---------------------------|
| Contexto | [00_contexto_y_paleta.md](00_contexto_y_paleta.md) | Paleta, flujo, modelo Order (léelo primero o adjunta un resumen en Stitch) |
| 1 | [01_cart_page.md](01_cart_page.md) | `CartPage` |
| 2 | [02_checkout_page.md](02_checkout_page.md) | `CheckoutPage` |
| 3 | [03_order_confirmation_page.md](03_order_confirmation_page.md) | `OrderConfirmationPage` |
| 4a | [04_order_detail_pending_payment.md](04_order_detail_pending_payment.md) | `OrderDetailPage` — pendiente de pago |
| 4b | [04_order_detail_shipped.md](04_order_detail_shipped.md) | `OrderDetailPage` — en camino |
| 4c | [04_order_detail_delivered.md](04_order_detail_delivered.md) | `OrderDetailPage` — entregado |
| 5 | [05_buyer_order_chat_page.md](05_buyer_order_chat_page.md) | `BuyerOrderChatPage` |
| 6 | [06_buyer_disputes_page.md](06_buyer_disputes_page.md) | `BuyerDisputesPage` |
| 7 | [07_orders_page.md](07_orders_page.md) | `OrdersPage` |
| 8 | [08_order_history_detail_page.md](08_order_history_detail_page.md) | `OrderHistoryDetailPage` |
| 9 | [09_order_rating_page.md](09_order_rating_page.md) | `OrderRatingPage` |

**Orden sugerido en Stitch:** 1 → 2 → 3 → 4a/4b/4c → 7 → 8 → 5 → 6 → 9.

**Documento maestro (forense completo):** [../STITCH_PROMPTS_FLUJO_COMPRADOR_CARRITO_A_CALIFICACION.md](../STITCH_PROMPTS_FLUJO_COMPRADOR_CARRITO_A_CALIFICACION.md)
