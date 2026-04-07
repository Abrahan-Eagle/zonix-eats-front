# Contexto compartido — Zonix Eats (buyer)

Úsalo como **prefijo opcional** en Stitch (“misma app que…” + pegar resumen) o léelo antes de generar pantallas.

## Producto

- App de delivery de comida (Venezuela), rol **comprador** (`users`).
- **Un solo comercio** por carrito.
- Material 3, móvil vertical ~375×812.

## Flujo de pantallas (referencia)

```text
CartPage → CheckoutPage → OrderConfirmationPage → OrderDetailPage
                                                      ↓
                              Chat | Incidencias (AppBar)

OrdersPage → OrderDetailPage | OrderHistoryDetailPage → OrderRatingPage
```

## Paleta (alineada a `AppColors`)

| Uso | Light | Dark |
|-----|-------|------|
| Scaffold | ~#F5F7F8 | ~#0F1923 |
| CTA azul | #3399FF | acento con contraste |
| CTA naranja | #FF9800 | visible sobre oscuro |
| Éxito / pickup | #43D675 | idem |
| Texto principal | #0F172A | blanco / gris claro |
| Texto secundario | #64748B | gris medio |

## Regla para todos los prompts

Al inicio del prompt en Stitch puedes añadir: *Genera dos artboards: tema claro y tema oscuro, misma estructura.*
