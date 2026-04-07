# Stitch — Vista: Chat con comercio (`BuyerOrderChatPage`)

**Código:** `lib/features/screens/orders/buyer_order_chat_page.dart`

## Lógica resumida

Mensajes comprador vs comercio por pedido; input enviar; estados vacío / carga / error.

---

## Prompt para Stitch

```text
Chat móvil entre comprador y comercio para un pedido Zonix Eats.

AppBar: "Chat" o nombre comercio, subtítulo "Pedido #123".

Cuerpo: burbujas comprador alineadas derecha (acento azul #3399FF), comercio izquierda gris/surface; timestamps pequeños.

Input inferior: campo redondeado + botón enviar; safe area.

Estados: vacío con hint amigable; loading lista; error con reintentar.

LIGHT Y DARK.
```

Genera dos artboards: tema claro y tema oscuro, misma estructura.
