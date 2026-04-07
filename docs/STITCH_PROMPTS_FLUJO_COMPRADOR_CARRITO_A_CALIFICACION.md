# Prompts Stitch — Flujo comprador (carrito → calificación) — edición forense

**Herramienta:** [Stitch — Design with AI](https://stitch.withgoogle.com)  
**App:** Zonix Eats — Flutter, Material 3, rol `users` (buyer).  
**Documento:** análisis tipo **forense** sobre el código en `zonix-eats-front` + **prompts independientes por vista** para generar o refinar diseños en **modo claro y oscuro**.

---

## 1. Encuadre: comité de expertos (cómo usar este documento)

Actúa como un **comité de expertos senior** en **producto marketplace de comida**, **UX móvil**, **Flutter/Material 3**, **modelo de datos de órdenes** y **consistencia visual** con lo ya implementado en el rol comprador.

**Objetivo del documento**

1. Fijar **qué pantallas** existen en el flujo real (no inventar pasos).  
2. Describir **datos y reglas de negocio** que cada vista consume o muestra.  
3. Entregar **un prompt por pantalla** listo para Stitch, **explícito** en layout, estados vacío/carga/error, y **light + dark**.  
4. Servir de **contrato de diseño** entre tú, Stitch y quien implemente en código.

**Limitaciones honestas**

- La app ya tiene implementación; Stitch propone **pixel-perfect** que luego se mapea a `AppColors` / `Theme`.  
- `OrderDetailPage` es **densa**: puedes pedir a Stitch **varias variaciones por estado** (`pending_payment`, `shipped`, `delivered`).  
- `CurrentOrderDetailPage` existe en archivo pero **no aparece enlazada** en navegación actual; el flujo canónico de detalle es **`OrderDetailPage`**.

---

## 2. Hallazgos forenses — flujo y datos

### 2.1 Secuencia de navegación (buyer)

```text
CartPage → CheckoutPage → OrderConfirmationPage → OrderDetailPage
                                                      ↓ (AppBar)
                                              BuyerOrderChatPage | BuyerDisputesPage

OrdersPage (tab Órdenes) → OrderDetailPage | OrderHistoryDetailPage → OrderRatingPage
```

- **Carrito → Checkout:** `Navigator.push` desde footer **"Ir a pagar"**.  
- **Checkout → Confirmación:** `pushReplacement` tras `createOrder` + **vaciado de carrito**.  
- **Confirmación → Detalle:** botón **"Seguir mi pedido"** → `OrderDetailPage`.  
- **Calificación:** `OrderRatingPage` como **bottom sheet** ~90% altura desde `OrderDetailPage` tras entrega; también accesible desde **historial** si aplica.

### 2.2 Modelo `Order` (campos relevantes para UI)

Referencia: `lib/models/order.dart`.

| Campo / concepto | Uso en UI |
|------------------|-----------|
| `orderNumber`, `id` | Títulos y referencias |
| `status` (canónico) | Badges, timeline, qué bloques mostrar |
| `items[]` | Líneas de producto, cantidades |
| `subtotal`, `deliveryFee`, `total` | Resúmenes |
| `deliveryType` | delivery vs pickup (`isPickup` en modelo) |
| `paymentProof`, `referenceNumber`, `paymentMethod` | Bloque comprobante |
| `deliveryAgentId` | Si hay repartidor → mapa, QR, **segunda tarjeta en calificación** |
| `estimatedDeliveryMinutes` | Textos tipo ETA en confirmación/detalle |
| `commerce` (map) | Nombre/logo comercio |

Estados frecuentes en UI: `pending_payment`, `paid`, `processing`, `shipped`, `delivered`, `cancelled`.

### 2.3 Reglas de negocio globales (no contradecir en diseño)

- **Un solo comercio** por carrito (`CartService`).  
- **Subtotal en carrito** = suma líneas; **envío** se calcula en checkout si `delivery`.  
- **Cupón** opcional; total = `subtotal + delivery - descuento` (mínimo 0).  
- **Sin pasarela embebida** en checkout típico: orden puede quedar `pending_payment` y comprobante en **detalle de orden**.

---

## 3. Paleta de referencia (alineada a `AppColors`)

| Token / uso | Light | Dark |
|-------------|-------|------|
| Scaffold | ~#F5F7F8 | ~#0F1923 |
| Primario / CTA azul | #3399FF | mismo acento con contraste |
| CTA naranja (carrito “Ir a pagar”, toggles) | #FF9800 | visible sobre oscuro |
| Éxito / pickup seleccionado | #43D675 | idem |
| Texto principal | #0F172A / stitchTextDark | blanco / gris claro |
| Texto secundario | #64748B / #9CA3AF | gris medio |
| Error / eliminar | rojo semántico | no solo color: icono + texto |

---

## 4. Prompts por vista (archivos separados)

Los textos listos para **copiar y pegar en Stitch** están en **`docs/stitch_prompts_buyer/`**: **un archivo `.md` por pantalla** (más contexto/paleta en `00_contexto_y_paleta.md`). La vista **detalle de orden** tiene **tres archivos** según estado (`pending_payment`, `shipped`, `delivered`).

**Índice con rutas:** [stitch_prompts_buyer/README.md](stitch_prompts_buyer/README.md)

Cada archivo incluye: ruta del `.dart`, resumen de lógica y bloque **Prompt para Stitch**. Añade en Stitch si quieres: *Genera dos artboards: tema claro y tema oscuro, misma estructura.*

---

## 5. Orden recomendado en Stitch

1 → 2 → 3 → 4 (A/B/C) → 7 → 8 → 5 → 6 → 9.

Así alineas lista de pedidos antes de chat/disputas si priorizas flujo “mis pedidos”.

---

## 6. Referencias en repo

| Recurso | Ruta |
|---------|------|
| Prompts Stitch por pantalla (carpeta) | `docs/stitch_prompts_buyer/` |
| Prompts maestro / verificación UI | `docs/PROMPT_MAESTRO_ZONIX_EATS.md`, `docs/PROMPT_VERIFICACION_SOLO_ESTETICA.md` |
| Colores | `lib/features/utils/app_colors.dart` |
| Router buyer | `lib/main.dart` (`BuyerShell`, índices bottom nav 0–3) |

---

## Historial

| Fecha | Cambio |
|-------|--------|
| 2026-04-02 | Creación inicial prompts por vista. |
| 2026-04-02 | **Edición forense:** comité, hallazgos, modelo Order, textos reales (Ir a pagar, Confirmar Pedido, Domicilio/Recoger), variantes OrderDetail, mermaid flujo. |
| 2026-04-02 | Prompts movidos a `docs/stitch_prompts_buyer/` (un `.md` por vista; detalle orden = 3 archivos). Este doc conserva análisis; sección 4 enlaza a la carpeta. |
