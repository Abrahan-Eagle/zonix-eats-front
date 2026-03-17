# Flujos con muchas vistas – Análisis y simplificaciones

Objetivo: **hacerlo fácil para el usuario en todos los roles**, reduciendo pasos y pantallas intermedias donde tenga sentido.

---

## 1. Comprador (Buyer)

### 1.1 Órdenes – Detalle activo vs detalle recibo

**Situación actual:**

- Lista de órdenes → al tocar:
  - Si **pendiente de pago** o se quiere “recibo completo” → **OrderDetailPage**
  - Si orden **activa** (pagada, en preparación, en camino) → **CurrentOrderDetailPage**
- Desde **CurrentOrderDetailPage**, “Subir comprobante” abre **OrderDetailPage** (otra pantalla).
- En **Historial** → **OrderHistoryDetailPage** (recibo tipo resumen). Desde ahí:
  - “Descargar recibo” → abre **OrderDetailPage** (solo para usar el botón Descargar PDF).
  - “Calificar pedido” → abre **OrderRatingPage** (pantalla completa).

**Problema:** El usuario puede no entender por qué a veces ve “seguimiento en vivo” y otras “recibo”; además, para descargar recibo o calificar debe pasar por una pantalla extra.

**Propuestas:**

| Qué | Cómo simplificar |
|-----|-------------------|
| **Unificar detalle de orden** | Una sola pantalla “Detalle del pedido” que según estado muestre: bloque de pago/comprobante (si aplica), barra de progreso (recibido → preparación → en camino → entregado) y mismo resumen. Evitar tener OrderDetailPage y CurrentOrderDetailPage como destinos distintos desde la lista. |
| **Descargar recibo desde historial** | En **OrderHistoryDetailPage**, “Descargar recibo” no debe abrir OrderDetailPage. Llamar directamente a `ReceiptPdfBuilder.build(order)` + `Printing.sharePdf()` (misma lógica que en OrderDetailPage) y mostrar loading/snackbar en la misma pantalla. Una acción = un paso. |
| **Calificar pedido** | Valorar mostrar **OrderRatingPage** como bottom sheet o modal desde OrderHistoryDetailPage en lugar de push a pantalla completa; al terminar se cierra y el usuario sigue en el historial. |

### 1.2 Checkout → pedido creado

**Estado:** Ya simplificado: tras crear la orden se hace `pushReplacement` a **OrderDetailPage** con `showCreatedDialog: true` (modal “¡Pedido creado!”). No se usa pantalla intermedia “¡Pedido realizado!”.

### 1.3 Onboarding comprador

**Situación:** `ClientOnboardingFlow` con **2 pasos** (Datos personales, Dirección). Está acotado; no se detectan pasos redundantes.

---

## 2. Comercio (Commerce)

### 2.1 Órdenes

**Situación actual:**

- Dashboard / Órdenes → lista → tocar orden → **CommerceOrderDetailPage**.
- Desde detalle se puede ir a chat, perfil, etc.

**Valoración:** Flujo corto (lista → detalle). No hay pasos intermedios innecesarios.

### 2.2 Productos

- Lista → “Crear” / “Editar” → **CommerceProductFormPage** (una sola pantalla con formulario).
- **Valoración:** Ya es un solo paso; no hay varias pantallas encadenadas.

### 2.3 Onboarding comercio

**Situación:** Mismo `ClientOnboardingFlow` con **4 pasos** (Datos personales, Dirección, Datos del comercio, Horario/foto). Es un flujo largo pero coherente con la cantidad de datos. Opción futura: agrupar en menos pasos (por ejemplo dirección + datos comercio en un paso más largo con scroll) si se prioriza reducir número de “pantallas” del wizard.

---

## 3. Delivery (repartidor)

- Onboarding y listados de pedidos no se han revisado en detalle en esta pasada. Si hay flujos tipo “lista → detalle → otra pantalla solo para una acción”, aplicar la misma idea: **acción directa o modal/sheet** en lugar de nueva pantalla cuando sea posible.

---

## 4. Configuración / Perfil (todos los roles)

### 4.1 Settings (SettingsPage2)

**Situación:** Muchos ítems que cada uno hace `Navigator.push` a una pantalla (Perfil, Teléfonos, Documentos, Direcciones, Ayuda, Exportar datos, etc.). Es el patrón estándar de “menú de ajustes”.

**Valoración:** Aceptable. Solo considerar para ítems muy simples (por ejemplo “Exportar datos” o “Ver actividad”) si en el futuro se puede hacer la acción en un sheet/dialog en lugar de una pantalla completa, cuando la acción sea única y no requiera navegación interna.

### 4.2 Perfil → Teléfonos / Documentos / Direcciones

- Lista → Crear/Editar → pantalla de formulario. Flujo claro; no se proponen cambios por defecto.

---

## 5. Resumen de prioridades

| Prioridad | Rol      | Cambio sugerido |
|----------|----------|------------------|
| Alta     | Comprador | **Descargar recibo** desde OrderHistoryDetailPage sin abrir OrderDetailPage: usar ReceiptPdfBuilder + share en la misma pantalla. |
| Alta     | Comprador | **Calificar**: valorar OrderRatingPage como bottom sheet/modal desde OrderHistoryDetailPage. |
| Media    | Comprador | **Unificar** OrderDetailPage y CurrentOrderDetailPage en una sola “Detalle de pedido” que adapte contenido por estado (pago, seguimiento, mismo resumen). |
| Media    | Comprador | Desde CurrentOrderDetailPage, “Subir comprobante” podría abrir el mismo diálogo/sheet de subida que en OrderDetailPage en lugar de navegar a otra pantalla (si se unifica detalle, esto se resuelve). |
| Baja     | Comercio  | Onboarding: opcional agrupar pasos en menos pantallas con más contenido por paso (scroll). |
| Baja     | Todos     | En ajustes, acciones puntuales (exportar, etc.) en modal/sheet cuando la acción sea única. |

---

## 6. Implementación técnica (resumen)

- **Descargar recibo sin OrderDetailPage:** Extraer la lógica de `_onDownloadPdf` de `OrderDetailPage` (cargar logo, `ReceiptPdfBuilder.build`, `Printing.sharePdf`) a un helper reutilizable (p. ej. en `receipt_pdf_builder.dart` o en un `ReceiptHelper`) y llamarla desde `OrderHistoryDetailPage` al pulsar “Descargar recibo”.
- **Calificar como sheet:** Navegar a `OrderRatingPage` con `showModalBottomSheet` o `showDialog` (o una ruta que la presente como modal) en lugar de `Navigator.push(MaterialPageRoute(...))`.
- **Unificar OrderDetailPage y CurrentOrderDetailPage:** Refactor en una sola pantalla con secciones condicionales según `order.status` y `order.approvedForPayment`; desde la lista de órdenes siempre abrir esa única pantalla.

---

*Documento generado a partir de revisión de rutas y flujos en el front (orders, onboarding, commerce, settings). Fecha: Marzo 2026.*

### Implementado (Marzo 2026)

- **Descargar recibo** desde historial: `ReceiptHelper` reutilizable; en OrderHistoryDetailPage se llama con `showLoadingDialog: true` (sin abrir OrderDetailPage).
- **Calificar** desde historial: se abre `OrderRatingPage` en `showModalBottomSheet` (90% altura).
- **Unificación detalle:** Desde lista de órdenes y desde OrderConfirmationPage siempre se abre `OrderDetailPage`. Se añadió barra de progreso (RECIBIDO → PREPARACIÓN → EN CAMINO → ENTREGADO) en OrderDetailPage cuando la orden es trackable (paid, processing, shipped).
