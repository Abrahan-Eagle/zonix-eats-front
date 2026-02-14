# Análisis: ¿El flujo tiene lógica y está alineado con el modelo de negocio?

**Fecha:** Febrero 2025  
**Objetivo:** Comparar el flujo documentado con las reglas de negocio (README) y la implementación real para detectar errores o desviaciones.

---

## 1. ¿El diagrama de flujo es correcto en cuanto a LÓGICA?

### ✅ SÍ – La secuencia de estados y roles es coherente

| Aspecto | Estado | Comentario |
|---------|--------|------------|
| Estados de la orden | ✅ Correcto | `pending_payment` → `paid` → `processing` → `shipped` → `delivered` coincide con README |
| Rol del Comercio | ✅ Correcto | Valida pago, prepara, envía |
| Rol del Delivery | ✅ Correcto | Acepta órdenes en `shipped`, marca `delivered` |
| Rol del Admin | ✅ Correcto | Supervisión, sin flujo obligatorio en compra |
| Asignación autónoma | ✅ Correcto | Backend asigna delivery por cercanía cuando comercio marca `shipped` |

**Conclusión:** La lógica del diagrama es correcta y refleja el flujo esperado según el modelo de negocio.

---

## 2. ERRORES entre el modelo de negocio y la implementación

### 🔴 CRÍTICO 1: Cliente no puede subir comprobante de pago

**Modelo de negocio (README):**
1. Cliente crea orden → `pending_payment`
2. Cliente sube comprobante (paso separado)
3. Comercio valida → `paid` o `cancelled`

**Implementación actual:**
- CheckoutPage crea la orden y muestra “Orden creada exitosamente”.
- No hay ninguna pantalla para subir el comprobante.
- `OrderService.uploadPaymentProof()` existe y el backend tiene `POST /api/buyer/orders/{id}/payment-proof`, pero ninguna vista lo usa.
- El comprador no tiene forma de subir el comprobante desde la app.

**Impacto:** Órdenes en `pending_payment` sin comprobante; el comercio no puede validar. El flujo de pago manual queda roto.

---

### 🔴 CRÍTICO 2: Cliente no puede ver el detalle de su orden

**Modelo de negocio:**
- El cliente debe poder ver detalle de la orden, subir comprobante, cancelar en `pending_payment`.

**Implementación actual:**
- OrdersPage lista órdenes, pero el `onTap` del ítem no hace nada.
- No existe OrderDetailPage para el comprador.
- No hay navegación a detalle, ni botón de subir comprobante, ni botón de cancelar.

**Impacto:** El comprador no puede completar el flujo (subir comprobante) ni cancelar órdenes pendientes.

---

### 🔴 CRÍTICO 3: Tarifa de envío no se calcula ni cobra

**Modelo de negocio (README):**
- El cliente paga el delivery (base fija + por km).
- Ejemplo: Base $2.00 + $0.50/km después de 2 km.

**Implementación actual:**
- **CheckoutPage:** `delivery = 0.0` (hardcodeado). Total = subtotal + tax + delivery (0).
- **Backend OrderController::store:** No calcula ni guarda `delivery_fee`. La orden se crea solo con `total` = subtotal de productos.
- **CartPage:** Muestra $2.50 como envío, pero CheckoutPage ignora ese valor y usa 0.
- El frontend envía `total` = subtotal; el backend no añade delivery_fee.

**Impacto:** No se cobra el envío. No se cumple el modelo de negocio.

---

### 🟡 MEDIO 4: Método de pago y referencia en comprobante

**Backend uploadPaymentProof** exige:
- `payment_proof` (archivo)
- `payment_method` (string)
- `reference_number` (string)

**Frontend OrderService.uploadPaymentProof** solo envía el archivo. No se envían `payment_method` ni `reference_number`. Aunque exista la UI, la llamada actual no cumple la API.

---

### 🟡 MEDIO 5: Pickup vs Delivery

**Modelo:** Para `pickup`, el cliente recoge en tienda; no hay delivery asignado.

**Implementación:** El flujo comercial (processing → shipped → delivered) está pensado para delivery. Para pickup, “shipped” podría entenderse como “listo para recoger”, pero no está explicitado ni diferenciado en la UI.

---

## 3. Resumen: ¿Es como debería ser?

| Pregunta | Respuesta |
|----------|-----------|
| ¿El diagrama de flujo es lógico? | **Sí** – Estados y roles son coherentes |
| ¿El modelo de negocio es coherente? | **Sí** – El README define un flujo razonable |
| ¿La implementación cumple el modelo? | **No** – Hay desvíos críticos |

### Brechas principales

| Brecha | Tipo | Dónde corregir |
|--------|------|----------------|
| Sin pantalla para subir comprobante | UI | Crear OrderDetailPage (comprador) con botón “Subir comprobante” |
| Tap en orden no hace nada | UI | Conectar OrdersPage → OrderDetailPage |
| Tarifa de envío = 0 | Frontend + Backend | Calcular delivery_fee (dirección, zona, etc.) y enviarlo al crear orden |
| `uploadPaymentProof` sin payment_method/reference | Frontend | Añadir campos en la UI y enviarlos al backend |

---

## 4. Flujo IDEAL según modelo de negocio

```
1. Comprador: CartPage → CheckoutPage
   - Selecciona tipo (pickup/delivery)
   - Si delivery: selecciona dirección, ve costo de envío calculado
   - Total = subtotal + tax + delivery_fee
   - "Confirmar compra" → crea orden (pending_payment)

2. Comprador: OrdersPage → OrderDetailPage (NUEVA)
   - Ve orden en pending_payment
   - Botón "Subir comprobante" → abre formulario (imagen, método de pago, referencia)
   - Botón "Cancelar orden" (dentro de 5 min)
   - Timer visible: "Tienes 5 min para subir comprobante"

3. Comercio: CommerceOrderDetailPage
   - Ve comprobante, valida o rechaza → paid / cancelled

4. Comercio: paid → "En preparación" → processing
   Comercio: processing → "Enviar" → shipped

5. Sistema: busca delivery disponible, asigna

6. Delivery: ve orden, acepta, entrega → delivered

7. Comprador: recibe notificación, puede calificar
```

---

## 5. Priorización de correcciones

| Prioridad | Tarea | Esfuerzo estimado |
|-----------|-------|-------------------|
| 1 | Crear OrderDetailPage para comprador con subida de comprobante | 1–2 días |
| 2 | Conectar OrdersPage tap → OrderDetailPage | 0.5 día |
| 3 | Implementar cálculo de delivery_fee (Backend + Frontend) | 1–2 días |
| 4 | Añadir payment_method y reference_number en uploadPaymentProof | 0.5 día |
| 5 | Mostrar timer 5 min para subir comprobante (opcional) | 0.5 día |

---

**Conclusión:** La lógica del flujo y del modelo de negocio es correcta. Los problemas están en la implementación: faltan pantallas (OrderDetail para comprador, subida de comprobante) y el cálculo de envío no está integrado en el checkout ni en la creación de órdenes.
