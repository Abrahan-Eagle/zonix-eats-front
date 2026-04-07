# Stitch — Vista: Confirmación de pedido (`OrderConfirmationPage`)

**Código:** `lib/features/screens/orders/order_confirmation_page.dart`

## Lógica resumida

Título **"¡Pedido creado!"**; subtítulo según si queda `pending_payment`; lista de ítems; ETA; **"Seguir mi pedido"** → detalle; **"Volver al inicio"**.

---

## Prompt para Stitch

```text
Pantalla de éxito inmediatamente después de crear el pedido (Zonix Eats). Mobile vertical.

LAYOUT:
- SafeArea, fondo scaffold.
- Fila superior: botón cerrar X izquierda; centro texto marca "Zonix Eats" (title medium).
- Ilustración: círculo 96px con borde verde #43D675 y fill verde 20% opacidad, icono check verde grande centro.
- Título "¡Pedido creado!" headline.
- Subtítulo 2 líneas: si pago pendiente, texto que mencione orden # y pendiente de pago; si no, pedido en preparación.
- Card lista "Detalles del pedido" con filas producto x cantidad y precio.
- Zona inferior fija: botón primario "Seguir mi pedido" (azul o naranja acorde app); TextButton "Volver al inicio".

LIGHT Y DARK: celebración legible; dark sin fondos blancos puros en cards.
```

Genera dos artboards: tema claro y tema oscuro, misma estructura.
