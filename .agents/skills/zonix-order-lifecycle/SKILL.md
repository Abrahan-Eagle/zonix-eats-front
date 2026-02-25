---
name: zonix-order-lifecycle
description: Ciclo de vida completo de órdenes en Zonix Eats. Estados, transiciones válidas, reglas de cancelación, penalidades, y eventos.
trigger: Cuando se trabaje con órdenes, cambios de estado, cancelaciones, tracking de pedidos, o lógica de flujo de compra.
scope: app/Models/Order.php, app/Http/Controllers/Commerce/OrderController.php, app/Http/Controllers/Delivery/OrderController.php, app/Http/Controllers/Buyer/OrderController.php
author: Zonix Team
version: 2.0
---

# 🔄 Ciclo de Vida de Órdenes - Zonix Eats

## Roles (Terminología Estándar)

| Nivel | Código en BD | Nombre Estándar | Alias aceptados            |
| ----- | ------------ | --------------- | -------------------------- |
| 0     | `users`      | **Buyer**       | Comprador, Cliente         |
| 1     | `commerce`   | **Commerce**    | Comercio, Restaurante      |
| 2     | `delivery`   | **Delivery**    | Delivery Agent, Repartidor |
| 3     | `admin`      | **Admin**       | Administrador              |

## 1. Estados de una Orden

```
pending_payment → paid → processing → shipped → delivered
                                    ↘ cancelled (desde paid o processing)
```

| Estado            | Descripción                   | Quién lo activa          |
| ----------------- | ----------------------------- | ------------------------ |
| `pending_payment` | Orden creada, esperando pago  | Sistema (al crear orden) |
| `paid`            | Pago confirmado/validado      | Commerce o Webhook       |
| `processing`      | Comercio preparando el pedido | Commerce                 |
| `shipped`         | En camino con delivery        | Delivery Agent           |
| `delivered`       | Entregado al cliente          | Delivery Agent           |
| `cancelled`       | Cancelada                     | Commerce, Buyer o Admin  |

## 2. Transiciones Válidas

**REGLA CRÍTICA:** Solo se permiten estas transiciones. Cualquier otra DEBE retornar error 400.

```php
// app/Http/Controllers/Commerce/OrderController.php
$validTransitions = [
    'paid'       => ['processing', 'cancelled'],
    'processing' => ['shipped', 'cancelled'],
];

// Estados TERMINALES (no permiten cambios):
// 'pending_payment', 'delivered', 'cancelled'
```

### Validación de transiciones (patrón estándar):

```php
if (isset($validTransitions[$order->status])) {
    if (!in_array($request->status, $validTransitions[$order->status])) {
        return response()->json([
            'success' => false,
            'message' => "No se puede cambiar de '{$order->status}' a '{$request->status}'"
        ], 400);
    }
} else {
    if (in_array($order->status, ['pending_payment', 'delivered', 'cancelled'])) {
        return response()->json([
            'success' => false,
            'message' => "No se puede cambiar el estado de una orden en '{$order->status}'"
        ], 400);
    }
}
```

## 3. Eventos al Cambiar Estado

**SIEMPRE** emitir evento después de cambiar estado:

```php
$order->update(['status' => $request->status]);
event(new \App\Events\OrderStatusChanged($order));
```

El evento `OrderStatusChanged`:

- Implementa `ShouldBroadcast`
- Canales privados: `private-user.{userId}`, `private-commerce.{commerceId}` (ver `zonix-realtime-events`)
- Payload: `{ order_id, status, message }`

## 4. Validación de Pago

Para pagos manuales (Pago Móvil/Zelle), el comercio valida:

```php
// Validar pago → status cambia a 'paid'
$order->update([
    'status' => 'paid',
    'payment_validated_at' => now(),
    'cancellation_reason' => null
]);
event(new PaymentValidated($order, true, $profile->id));

// Rechazar pago → status cambia a 'cancelled'
$order->update([
    'status' => 'cancelled',
    'cancellation_reason' => $validated['rejection_reason'] ?? 'Pago rechazado',
    'payment_validated_at' => null
]);
event(new OrderStatusChanged($order));
```

## 5. Cancelación

### Reglas de cancelación:

- **Buyer:** Solo puede cancelar en `pending_payment` o `paid` (antes de que el commerce empiece a preparar)
- **Commerce:** Puede cancelar en `paid` y `processing`
- **Admin:** Puede cancelar en cualquier estado (excepto delivered)
- **NUNCA** cancelar una orden `delivered`

### Campos de cancelación:

```php
$order->update([
    'status' => 'cancelled',
    'cancelled_by' => 'buyer|commerce|admin',
    'cancellation_reason' => 'Razón de la cancelación',
    'cancellation_penalty' => 0.00 // Penalidad si aplica
]);
```

## 6. Modelo Order - Campos Clave

```php
protected $fillable = [
    'profile_id', 'commerce_id', 'delivery_type', 'status',
    'total', 'delivery_fee', 'delivery_payment_amount',
    'commission_amount', 'cancellation_penalty', 'cancelled_by',
    'estimated_delivery_time', 'receipt_url', 'payment_proof',
    'payment_method', 'reference_number', 'payment_validated_at',
    'payment_proof_uploaded_at', 'cancellation_reason',
    'delivery_address', 'notes'
];
```

### Relaciones del modelo:

- `profile()` → belongsTo(Profile) — el comprador
- `commerce()` → belongsTo(Commerce) — el restaurante
- `products()` → belongsToMany(Product) via order_items (con pivot: quantity, unit_price)
- `orderItems()` → hasMany(OrderItem)
- `orderDelivery()` / `delivery()` → hasOne(OrderDelivery)
- `chatMessages()` → hasMany(ChatMessage)
- `disputes()` → hasMany(Dispute)
- `deliveryPayments()` → hasMany(DeliveryPayment)
- `reviews()` → hasMany(Review)

## 7. API Endpoints de Órdenes

| Rol      | Método | Ruta                                     | Acción                      |
| -------- | ------ | ---------------------------------------- | --------------------------- |
| Buyer    | POST   | `/buyer/orders`                          | Crear orden                 |
| Buyer    | GET    | `/buyer/orders`                          | Listar mis órdenes          |
| Buyer    | POST   | `/buyer/orders/{id}/payment-proof`       | Subir comprobante           |
| Buyer    | POST   | `/buyer/orders/{id}/cancel`              | Cancelar orden              |
| Commerce | GET    | `/commerce/orders`                       | Listar órdenes del comercio |
| Commerce | PUT    | `/commerce/orders/{id}/status`           | Cambiar estado              |
| Commerce | POST   | `/commerce/orders/{id}/validate-payment` | Validar pago                |
| Delivery | GET    | `/delivery/orders`                       | Listar órdenes asignadas    |
| Delivery | PUT    | `/delivery/orders/{id}/accept`           | Aceptar orden               |
| Delivery | PATCH  | `/delivery/orders/{id}/status`           | Actualizar estado           |
| Admin    | GET    | `/admin/orders`                          | Listar todas las órdenes    |
| Admin    | PATCH  | `/admin/orders/{id}/status`              | Cambiar estado (override)   |

## 8. Cross-references

- **Eventos broadcast:** `zonix-realtime-events` § 3 (OrderStatusChanged, PaymentValidated)
- **Comisiones en orden:** `zonix-payments` § 5 (commission_amount, delivery_fee)
- **Rutas compartidas** (`/api/profiles`, `/api/phones`): No llevan prefijo de rol porque son multi-rol (ver `zonix-api-patterns` § 3)
- **Campo `profiles.phone` deprecado** — se lee vía accessor desde tabla `phones` (ver `zonix-onboarding` § 5.7)
