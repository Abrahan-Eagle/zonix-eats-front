# Stitch — Vista: Detalle de orden — pendiente de pago (`OrderDetailPage`)

**Código:** `lib/features/screens/orders/order_detail_page.dart`  
**Estado:** `pending_payment`

## Lógica resumida

Recibo con bloque de pago: método, referencia, **subir comprobante**. Sin mapa de repartidor activo o desactivado. AppBar: chat e incidencias.

---

## Prompt para Stitch

```text
Pantalla "Detalle del pedido / Recibo" Zonix Eats, comprador. Mobile, scroll largo.

AppBar: back, título centrado estilo "Recibo" o "Pedido", acciones icono chat outline y icono soporte outline.

Bloque 1: nombre comercio, badge estado "Pendiente de pago" en naranja/ámbar.
Bloque 2: sección "Datos para pagar" o timeline de pago: método, referencia si existe, área punteada "Subir comprobante" con icono imagen, texto ayuda.
Bloque 3: lista productos y totales (subtotal, envío, total).
Sin mapa de repartidor aún o mapa desactivado.

Footer opcional: botones según reglas (cancelar si aplica).

LIGHT Y DARK con buen contraste en badges.
```

Genera dos artboards: tema claro y tema oscuro, misma estructura.
