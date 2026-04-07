# Stitch — Vista: Checkout (`CheckoutPage`)

**Código:** `lib/features/screens/cart/checkout_page.dart`

## Lógica resumida

AppBar **"Finalizar pedido"**. Card **"Resumen del pedido"** con marca **"Zonix Eats"** en naranja. Líneas de producto con +/- y total línea en ámbar. Pills **"Domicilio"** (naranja activo) vs **"Recoger"** (verde activo). Cupón: **"Código de cupón"**, **"Aplicar"**, banner **"Cupón aplicado: -$X.XX"**. Si delivery: **"Dirección de entrega"**, **"Editar"**, sheet **"Elige una dirección"** (GPS, direcciones guardadas). Botón **"Confirmar Pedido"**.

---

## Prompt para Stitch

```text
Pantalla móvil "Finalizar pedido" (Checkout) para Zonix Eats, Venezuela. Material 3, formulario en scroll vertical.

ESTRUCTURA:
- AppBar centrado, título "Finalizar pedido", fondo igual al scaffold, sin sombra fuerte.
- Primera card grande 16px radio: cabecera fila "Resumen del pedido" (bold 18) + texto marca "Zonix Eats" naranja #FF9800 tamaño 13. Debajo, 2 filas de producto ejemplo: thumbnail 64 redondeado, nombre 15 semibold, notas 12 itálica gris, fila cantidad con iconos add/remove círculo, línea de total línea en #FFC107/ámbar bold.
- Sección título "Tipo de entrega" (16 semibold). Control tipo segmented pill en contenedor con borde: opción izquierda "Domicilio" con icono delivery_dining — seleccionada relleno naranja #FF9800 texto blanco; opción derecha "Recoger" con icono storefront — seleccionada relleno verde #43D675 texto blanco.
- Sección "Cupón de descuento": TextField hint "Código de cupón", botón "Aplicar" al lado; debajo opcional banner verde claro con check "Cupón aplicado: -$2.00".
- Si domicilio: sección "Dirección de entrega" con "Editar" texto botón; card con icono pin naranja, título "Ubicación actual" o "Mi Casa", dirección en gris, texto pequeño "Estimado: 25-35 min" (ejemplo).
- Bloque totales: Subtotal, Tarifa de envío (si delivery), Descuento, Total grande.
- Botón inferior fijo o al final del scroll: "Confirmar Pedido", altura ~52, color primario azul #3399FF o naranja según tu sistema (en código es ElevatedButton destacado).

ESTADOS: muestra mini variante con spinner en botón y otra con banner de error rojo suave arriba.

LIGHT Y DARK: como en Vista 1; en dark inputs y cards con borde sutil.
```

Genera dos artboards: tema claro y tema oscuro, misma estructura.
