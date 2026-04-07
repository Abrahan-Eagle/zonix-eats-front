# Stitch — Vista: Calificar pedido (`OrderRatingPage`)

**Código:** `lib/features/screens/orders/order_rating_page.dart`

## Lógica resumida

Estrellas + comentario para **restaurante**; si hubo repartidor, segunda tarjeta para **repartidor**. **"Enviar calificación"** (naranja), **"Ahora no"**.

---

## Prompt para Stitch

```text
Pantalla "Calificar pedido" Zonix Eats, cierre del flujo.

AppBar título "Calificar pedido".

Card 1: "Tu experiencia con el restaurante" — 5 estrellas, TextField comentario opcional.

Card 2 (si hubo repartidor): "Tu experiencia con el repartidor" — mismos controles.

Botón grande naranja #FF9800 "Enviar calificación"; TextButton "Ahora no" debajo.

LIGHT Y DARK; botón naranja con texto blanco siempre legible.
```

Genera dos artboards: tema claro y tema oscuro, misma estructura.
