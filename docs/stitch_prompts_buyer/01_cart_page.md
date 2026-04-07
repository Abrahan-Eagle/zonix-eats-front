# Stitch — Vista: Carrito (`CartPage`)

**Código:** `lib/features/screens/cart/cart_page.dart`

## Lógica resumida

Lista `CartItem` (nombre, precio, cantidad, notas, imagen). `CartService` ajusta cantidad y elimina. Footer: **Subtotal**, **Total** (= subtotal en carrito), CTA **"Ir a pagar"**. Vacío: **"El carrito está vacío"** / **"Explora restaurantes y agrega productos"**.

---

## Prompt para Stitch

```text
Diseño móvil vertical (375x812 aprox.) para la pantalla "Mi Carrito" de Zonix Eats, app de delivery de comida en Venezuela. Material 3, estilo limpio y actual.

CONTEXTO DE PRODUCTO:
- Un solo restaurante por carrito.
- Header: título "Mi Carrito" a la izquierda; a la derecha un pill/badge "N Items" con fondo azul muy suave (#3399FF al 10% opacidad) y texto azul #3399FF.
- Lista: cada ítem es una card con borde sutil, radio 12px, sombra muy leve solo en modo claro. Fila: imagen 96x96 redondeada (placeholder restaurante si no hay foto), columna con nombre producto en negrita 18px, notas opcionales en gris 14px una línea; precio unitario en azul acento; a la derecha stepper cantidad (- número +) y botón papelera para eliminar.
- Footer fijo elevado: card con borde superior, padding 24/16. Fila "Subtotal" y monto; divisor; fila "Total" en negrita y monto grande en verde éxito (#43D675). Botón primario ancho completo, forma píldora (radio 999), color naranja #FF9800, texto blanco "Ir a pagar" + icono flecha a la derecha.

VARIANTES:
A) Carrito vacío: icono carrito outline grande, título "El carrito está vacío", subtítulo "Explora restaurantes y agrega productos", sin footer de pago.
B) Carrito con 2 ítems de ejemplo.

MODO CLARO Y OSCURO:
- Light: fondo scaffold #F5F7F8, cards blancas o casi blancas.
- Dark: fondo #0F1923, cards #1A2733 o surface más clara que el fondo, bordes blancos al 5-10% opacidad; texto claro; mismo naranja en botón si el contraste WCAG lo permite.
```

Genera dos artboards: tema claro y tema oscuro, misma estructura.
