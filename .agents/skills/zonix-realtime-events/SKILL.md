---
name: zonix-realtime-events
description: Sistema de eventos en tiempo real de Zonix Eats. Pusher broadcasting, FCM push notifications, canales, payloads.
trigger: Cuando se trabaje con Pusher, broadcasting, notificaciones push (FCM), eventos en tiempo real, o tracking de órdenes.
scope: app/Events/, app/Http/Controllers/Notification/, config/broadcasting.php, routes/channels.php
author: Zonix Team
version: 2.0
---

# 📡 Eventos en Tiempo Real - Zonix Eats

> **⚠️ NO se usa WebSocket directo.** Se usa Pusher Channels (broadcasting) + FCM (push).

## 1. Arquitectura de Broadcasting

```
Cliente (Flutter) ←→ Pusher Channels ←→ Laravel Broadcasting
                                        ↓
                  Firebase Cloud Messaging (FCM) → Push Notifications
```

**Stack:**

- **Broadcasting:** Pusher Channels (NO WebSocket directo)
- **Push Notifications:** Firebase Cloud Messaging (FCM)
- **Driver Laravel:** `pusher` (config/broadcasting.php)

## 2. Roles (Terminología Estándar)

| Nivel | Código en BD | Nombre Estándar | Alias aceptados            |
| ----- | ------------ | --------------- | -------------------------- |
| 0     | `users`      | **Buyer**       | Comprador, Cliente         |
| 1     | `commerce`   | **Commerce**    | Comercio, Restaurante      |
| 2     | `delivery`   | **Delivery**    | Delivery Agent, Repartidor |
| 3     | `admin`      | **Admin**       | Administrador              |

## 3. Eventos Broadcast

### OrderStatusChanged (Principal)

```php
// app/Events/OrderStatusChanged.php
class OrderStatusChanged implements ShouldBroadcast
{
    public $order;

    public function __construct(Order $order)
    {
        $this->order = $order;
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("user.{$this->order->user_id}"),
            new PrivateChannel("commerce.{$this->order->commerce_id}"),
        ];
    }

    public function broadcastWith(): array
    {
        return [
            'order_id' => $this->order->id,
            'status'   => $this->order->status,
            'message'  => "Order {$this->order->id} status changed to {$this->order->status}"
        ];
    }
}
```

**Cuándo se dispara:**

- Cada vez que un Commerce cambia estado de orden
- Cuando un Delivery cambia estado (`shipped → delivered`)
- Cuando un pago es rechazado (cancelación)
- **Ver `zonix-order-lifecycle` para la lista completa de transiciones**

### PaymentValidated

```php
// app/Events/PaymentValidated.php
class PaymentValidated implements ShouldBroadcast
{
    public function __construct(
        public Order $order,
        public bool $isValid,
        public int $profileId,
    ) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("user.{$this->order->user_id}"),
        ];
    }

    public function broadcastWith(): array
    {
        return [
            'order_id'  => $this->order->id,
            'is_valid'  => $this->isValid,
            'status'    => $this->isValid ? 'paid' : 'cancelled',
            'message'   => $this->isValid
                ? "Pago validado para orden {$this->order->id}"
                : "Pago rechazado para orden {$this->order->id}",
        ];
    }
}
```

Se dispara cuando el Commerce valida el comprobante de pago.

- **Si válido:** `pending_payment → paid` (ver `zonix-order-lifecycle`)
- **Si inválido:** `pending_payment → cancelled`

## 4. Canales Pusher

| Canal                           | Tipo    | Descripción                  | Suscriptores              |
| ------------------------------- | ------- | ---------------------------- | ------------------------- |
| `private-user.{userId}`         | Privado | Notificaciones al Buyer      | Buyer                     |
| `private-order.{orderId}`       | Privado | Actualizaciones de una orden | Buyer, Commerce, Delivery |
| `private-chat.{orderId}`        | Privado | Chat de una orden            | Buyer, Commerce, Delivery |
| `private-commerce.{commerceId}` | Privado | Notificaciones al Commerce   | Commerce                  |

### Broadcasting Auth (canales privados):

```
POST /api/broadcasting/auth     → Middleware: auth:sanctum
```

## 5. Configuración Pusher

### Backend (.env):

```
BROADCAST_DRIVER=pusher
PUSHER_APP_ID=...
PUSHER_APP_KEY=...
PUSHER_APP_SECRET=...
PUSHER_HOST=
PUSHER_PORT=443
PUSHER_SCHEME=https
PUSHER_APP_CLUSTER=us2
```

### Frontend Flutter:

```dart
final pusher = PusherChannelsFlutter.getInstance();
await pusher.init(
    apiKey: 'TU_PUSHER_KEY',
    cluster: 'us2',
);
// Canal privado — requiere auth
await pusher.subscribe(channelName: 'private-user.$userId');
```

## 6. Firebase Cloud Messaging (FCM)

### Registro de token:

```
POST /api/chat/fcm/register     → { "token": "fcm_device_token" }
POST /api/chat/fcm/unregister   → { "token": "fcm_device_token" }
```

### Enviar Push Notification:

```
POST /api/notifications/push    → { "title", "body", "data" }
```

## 7. Sistema de Notificaciones

### API Endpoints:

```
GET    /api/notifications           → Listar notificaciones
GET    /api/notifications/stats     → Estadísticas (unread count)
POST   /api/notifications/mark-all-read → Marcar todas como leídas
POST   /api/notifications/{id}/read → Marcar como leída
POST   /api/notifications           → Crear notificación
DELETE /api/notifications/{id}      → Eliminar
```

### Settings de notificaciones:

```
GET /api/notifications/settings     → Obtener preferencias
PUT /api/notifications/settings     → Actualizar preferencias
```

### Campo en profiles:

- `fcm_device_token` — token del dispositivo (se registra al abrir la app)
- `notification_preferences` — JSON con preferencias (ver `zonix-onboarding` § 5.7)

## 8. Patrón de Uso desde Flutter

```dart
// 1. Suscribirse a canal privado del usuario
pusher.subscribe(channelName: 'private-user.$userId');

// 2. Escuchar eventos
pusher.onEvent = (event) {
    if (event.eventName == 'App\\Events\\OrderStatusChanged') {
        final data = jsonDecode(event.data);
        // data['order_id'], data['status'], data['message']
        updateOrderUI(data);
    }
    if (event.eventName == 'App\\Events\\PaymentValidated') {
        final data = jsonDecode(event.data);
        // data['order_id'], data['is_valid'], data['status']
        handlePaymentResult(data);
    }
};

// 3. FCM para notificaciones cuando la app está en background
FirebaseMessaging.onMessage.listen((message) {
    showLocalNotification(message);
});
```

## 9. Reglas Importantes

1. **SIEMPRE** emitir `OrderStatusChanged` después de cambiar estado de orden
2. **Canales PRIVADOS** — requieren `POST /api/broadcasting/auth` con token Sanctum
3. **FCM** es para notificaciones cuando la app está cerrada/background
4. **Pusher** es para actualizaciones en tiempo real cuando la app está abierta
5. **Los payloads deben ser ligeros** — solo IDs y estado, no el objeto Order completo
6. **NO usar WebSocket directo** — solo Pusher Channels + FCM

## 10. Cross-references

- **Estados de orden:** `zonix-order-lifecycle` § 1-2
- **Validación de pago:** `zonix-payments` § 4
- **Campo `profiles.phone` deprecado** — usa accessor vía `phones` tabla (ver `zonix-onboarding` § 5.7)
