# 🚀 Configuración Completa de WebSockets - ZONIX-EATS

## 📋 Índice
1. [Descripción General](#descripción-general)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Configuración del Backend](#configuración-del-backend)
4. [Configuración del Frontend](#configuración-del-frontend)
5. [Eventos Implementados](#eventos-implementados)
6. [Scripts de Automatización](#scripts-de-automatización)
7. [Pruebas y Debugging](#pruebas-y-debugging)
8. [Solución de Problemas](#solución-de-problemas)

## 🎯 Descripción General

ZONIX-EATS utiliza **Laravel Echo Server** para proporcionar comunicación en tiempo real entre el backend Laravel y el frontend Flutter. Este sistema permite:

- ✅ Notificaciones en tiempo real de cambios de estado de órdenes
- ✅ Actualización automática de ubicación de delivery
- ✅ Chat en tiempo real entre usuarios y comercios
- ✅ Notificaciones de pagos validados
- ✅ Tracking en tiempo real de pedidos

## 🏗️ Arquitectura del Sistema

```
┌─────────────────┐    WebSocket    ┌─────────────────┐
│   Flutter App   │ ←──────────────→ │ Laravel Echo    │
│   (Frontend)    │                 │ Server          │
└─────────────────┘                 └─────────────────┘
         │                                    │
         │ HTTP API                           │ Redis
         ▼                                    ▼
┌─────────────────┐                 ┌─────────────────┐
│   Laravel API   │                 │   Redis Cache   │
│   (Backend)     │                 │   (Pub/Sub)     │
└─────────────────┘                 └─────────────────┘
```

## ⚙️ Configuración del Backend

### 1. Variables de Entorno (.env)

```bash
# Broadcasting Configuration
BROADCAST_DRIVER=pusher
PUSHER_APP_ID=zonix-eats-app
PUSHER_APP_KEY=zonix-eats-key
PUSHER_APP_SECRET=zonix-eats-secret
PUSHER_HOST=localhost
PUSHER_PORT=6001
PUSHER_SCHEME=http
PUSHER_APP_CLUSTER=mt1

# Redis Configuration
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
```

### 2. Configuración de Broadcasting

El archivo `config/broadcasting.php` ya está configurado con:

- **Driver**: Pusher (compatible con Laravel Echo Server)
- **Host**: localhost:6001
- **App ID/Key/Secret**: Configurados para ZONIX-EATS

### 3. Eventos Implementados

#### OrderCreated
```php
// Emitido cuando se crea una nueva orden
Event::dispatch(new OrderCreated($order));
```

#### PaymentValidated
```php
// Emitido cuando se valida/rechaza un pago
Event::dispatch(new PaymentValidated($order, $isValidated, $validatedBy));
```

#### OrderStatusChanged
```php
// Emitido cuando cambia el estado de una orden
Event::dispatch(new OrderStatusChanged($order, $oldStatus, $newStatus));
```

#### DeliveryLocationUpdated
```php
// Emitido cuando se actualiza la ubicación del delivery
Event::dispatch(new DeliveryLocationUpdated($orderId, $deliveryAgentId, $lat, $lng));
```

### 4. Canales de Broadcast

- `orders.user.{userId}` - Órdenes específicas del usuario
- `orders.commerce.{commerceId}` - Órdenes del comercio
- `delivery.{orderId}` - Tracking de delivery
- `chat.{orderId}` - Chat de la orden

## 📱 Configuración del Frontend

### 1. Variables de Entorno (.env)

```bash
# WebSocket Configuration
WEBSOCKET_URL_LOCAL=ws://localhost:6001
WEBSOCKET_URL_PROD=wss://echo.zonix-eats.com
ECHO_APP_ID=zonix-eats-app
ECHO_KEY=zonix-eats-key
ENABLE_WEBSOCKETS=true
```

### 2. Servicio WebSocket

El `WebSocketService` maneja:

- ✅ Conexión automática/reconexión
- ✅ Suscripción a canales
- ✅ Manejo de mensajes
- ✅ Gestión de errores
- ✅ Logging detallado

### 3. Integración en Páginas

```dart
// En cualquier página que necesite actualizaciones en tiempo real
WebSocketService webSocketService = WebSocketService();
await webSocketService.connect();
await webSocketService.subscribeToChannel('orders.user.${userId}');

webSocketService.messageStream?.listen((message) {
  // Manejar mensajes recibidos
  _handleWebSocketMessage(message);
});
```

## 📡 Eventos Implementados

### 1. OrderCreated
**Propósito**: Notificar cuando se crea una nueva orden
**Canal**: `orders.user.{userId}`
**Datos**:
```json
{
  "type": "order_created",
  "order": {
    "id": 123,
    "status": "pendiente_pago",
    "total": 25.50,
    "commerce": {...}
  }
}
```

### 2. PaymentValidated
**Propósito**: Notificar validación/rechazo de pago
**Canal**: `orders.user.{userId}`
**Datos**:
```json
{
  "type": "payment_validated",
  "order_id": 123,
  "is_valid": true,
  "validated_by": "commerce_name",
  "rejection_reason": null
}
```

### 3. OrderStatusChanged
**Propósito**: Notificar cambios de estado
**Canal**: `orders.user.{userId}`
**Datos**:
```json
{
  "type": "order_status_changed",
  "order_id": 123,
  "old_status": "pendiente_pago",
  "new_status": "pagado",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### 4. DeliveryLocationUpdated
**Propósito**: Actualizar ubicación del delivery
**Canal**: `delivery.{orderId}`
**Datos**:
```json
{
  "type": "delivery_location_updated",
  "order_id": 123,
  "delivery_agent_id": 456,
  "latitude": -12.3456,
  "longitude": -78.9012,
  "estimated_arrival": "2024-01-15T11:00:00Z"
}
```

## 🤖 Scripts de Automatización

### 1. Iniciar Todo el Entorno
```bash
./start_development.sh
```

**Este script:**
- ✅ Verifica dependencias (Node.js, PHP, Flutter, Redis)
- ✅ Instala dependencias del backend
- ✅ Ejecuta migraciones y seeders
- ✅ Inicia Laravel Echo Server
- ✅ Inicia servidor Laravel
- ✅ Configura Flutter
- ✅ Inicia la aplicación

### 2. Detener Servicios
```bash
./stop_development.sh
```

### 3. Solo WebSocket
```bash
./start_websocket.sh
```

## 🧪 Pruebas y Debugging

### 1. Verificar Conexión WebSocket
```bash
# Verificar que el servidor está corriendo
curl http://localhost:6001/app/zonix-eats-app

# Ver logs del Echo Server
tail -f ../zonix-eats-back/echo-server.log
```

### 2. Verificar Eventos
```bash
# Ver logs de Laravel
tail -f ../zonix-eats-back/storage/logs/laravel.log

# Ver eventos broadcast
php artisan tinker
>>> event(new App\Events\OrderCreated(App\Models\Order::first()));
```

### 3. Debugging en Flutter
```dart
// Habilitar logs detallados
WebSocketService webSocketService = WebSocketService();
webSocketService.enableDebugLogs = true;
```

## 🔧 Solución de Problemas

### Problema: WebSocket no se conecta
**Solución**:
1. Verificar que Redis esté corriendo: `sudo systemctl status redis-server`
2. Verificar que Laravel Echo Server esté corriendo: `ps aux | grep laravel-echo-server`
3. Verificar puertos: `netstat -tulpn | grep :6001`

### Problema: Eventos no llegan al frontend
**Solución**:
1. Verificar configuración de broadcasting en Laravel
2. Verificar que el BroadcastServiceProvider esté activado
3. Verificar logs del Echo Server
4. Verificar suscripción a canales correctos

### Problema: Reconexión automática no funciona
**Solución**:
1. Verificar configuración de timeouts
2. Verificar manejo de errores en WebSocketService
3. Verificar logs de reconexión

## 📊 Monitoreo

### 1. Métricas de WebSocket
- Conexiones activas
- Mensajes enviados/recibidos
- Tasa de reconexión
- Latencia

### 2. Logs Importantes
- `../zonix-eats-back/echo-server.log` - Logs del Echo Server
- `../zonix-eats-back/storage/logs/laravel.log` - Logs de Laravel
- Logs de Flutter en consola

## 🚀 Próximos Pasos

1. **Implementar notificaciones push** con Firebase
2. **Agregar métricas de rendimiento** del WebSocket
3. **Implementar chat en tiempo real** entre usuarios
4. **Agregar tracking de delivery** en mapa
5. **Implementar notificaciones de stock** de productos

---

## 📞 Soporte

Para problemas o preguntas sobre la configuración de WebSockets:

1. Revisar logs detallados
2. Verificar configuración de red
3. Probar con herramientas como Postman WebSocket
4. Consultar documentación de Laravel Echo Server

**¡El sistema de WebSockets está completamente configurado y listo para usar!** 🎉 