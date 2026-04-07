# Stitch — Vista: Detalle de orden — en camino (`OrderDetailPage`)

**Código:** `lib/features/screens/orders/order_detail_page.dart`  
**Estado:** `shipped` (en camino)

## Lógica resumida

Mapa / tracking, ETA, posible QR para entrega al repartidor.

---

## Prompt para Stitch

```text
Pantalla "Detalle del pedido / Recibo" Zonix Eats, comprador — variante pedido EN CAMINO.

Misma base de recibo pero estado "En camino" / morado o azul en badge.

- Sección mapa simplificado (rectángulo con ruta curva y dos pins: comercio y cliente o repartidor moto).
- Card tracking "Tu pedido va en camino".
- QR pequeño o sección "Muestra este QR al repartidor" si aplica entrega.

AppBar: back, título recibo/pedido, acciones chat y soporte.

Estilo Zonix, light/dark.
```

Genera dos artboards: tema claro y tema oscuro, misma estructura.
