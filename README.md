# Zonix Eats - Sistema de Delivery Completo

## 📋 Descripción General

Zonix Eats es una aplicación de delivery completa que incluye:
- **Frontend**: Aplicación Flutter para clientes
- **Backend**: API REST con Laravel
- **Echo Server**: Servidor WebSocket para comunicación en tiempo real

## 🏗️ Arquitectura del Sistema

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │  Echo Server    │
│   (Flutter)     │◄──►│   (Laravel)     │◄──►│  (WebSocket)    │
│                 │    │                 │    │                 │
│ - Cliente App   │    │ - API REST      │    │ - Notificaciones│
│ - UI/UX         │    │ - Base de datos │    │ - Chat en tiempo│
│ - Geolocalización│   │ - Autenticación │    │   real          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Funcionalidades Implementadas (Nivel 0)

### Frontend (Flutter)
- ✅ **Autenticación**: Login/Registro de usuarios
- ✅ **Productos**: Catálogo de productos con imágenes
- ✅ **Restaurantes**: Lista de restaurantes con detalles
- ✅ **Carrito**: Gestión de carrito de compras
- ✅ **Órdenes**: Creación y seguimiento de pedidos
- ✅ **Reviews**: Sistema de calificaciones
- ✅ **Chat**: Comunicación en tiempo real
- ✅ **Pagos**: Integración con métodos de pago
- ✅ **Notificaciones**: Notificaciones push y en tiempo real
- ✅ **Geolocalización**: Ubicación y rutas
- ✅ **Favoritos**: Gestión de restaurantes favoritos

### Backend (Laravel)
- ✅ **API REST**: Endpoints para todas las funcionalidades
- ✅ **Autenticación**: JWT y Sanctum
- ✅ **Base de datos**: MySQL con migraciones
- ✅ **Modelos**: Productos, Órdenes, Usuarios, etc.
- ✅ **Controladores**: Lógica de negocio
- ✅ **Servicios**: Servicios de negocio
- ✅ **Eventos**: WebSocket events
- ✅ **Seeders**: Datos de prueba

### Echo Server (WebSocket)
- ✅ **Notificaciones**: En tiempo real
- ✅ **Chat**: Mensajería instantánea
- ✅ **Tracking**: Seguimiento de pedidos
- ✅ **Broadcasting**: Eventos en tiempo real

## 📁 Estructura del Proyecto

```
zonix-eats/
├── zonix-eats-front/          # Frontend Flutter
├── zonix-eats-back/           # Backend Laravel
└── zonix-eats-echo-server/    # Servidor WebSocket
```

## 🛠️ Tecnologías Utilizadas

### Frontend
- **Flutter**: Framework de UI
- **Dart**: Lenguaje de programación
- **HTTP**: Cliente para API REST
- **WebSocket**: Comunicación en tiempo real
- **SharedPreferences**: Almacenamiento local
- **Geolocator**: Geolocalización

### Backend
- **Laravel**: Framework PHP
- **MySQL**: Base de datos
- **JWT**: Autenticación
- **Sanctum**: API tokens
- **Eloquent**: ORM
- **Artisan**: CLI

### Echo Server
- **Laravel Echo Server**: Servidor WebSocket
- **Socket.io**: Protocolo WebSocket
- **Redis**: Cache y broadcasting

## 🚀 Instalación y Configuración

### Prerrequisitos
- Flutter SDK
- PHP 8.1+
- Composer
- MySQL
- Node.js
- npm/npx

### 1. Frontend (Flutter)

```bash
cd zonix-eats-front
flutter pub get
flutter run
```

### 2. Backend (Laravel)

```bash
cd zonix-eats-back
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed
php artisan serve --host=0.0.0.0 --port=8000
```

### 3. Echo Server

```bash
cd zonix-eats-echo-server
npm install
npx laravel-echo-server start
```

## 🔧 Configuración de URLs

### Frontend (lib/config/app_config.dart)
```dart
class AppConfig {
  static const String baseUrl = 'http://192.168.0.101:8000/api';
  static const String echoServerUrl = 'http://192.168.0.101:6001';
}
```

### Backend (.env)
```env
APP_URL=http://192.168.0.101:8000
DB_HOST=127.0.0.1
DB_DATABASE=zonix_eats
BROADCAST_DRIVER=redis
```

### Echo Server (laravel-echo-server.json)
```json
{
  "host": "0.0.0.0",
  "port": "6001",
  "authHost": "http://192.168.0.101:8000"
}
```

## 📊 Base de Datos

### Tablas Principales
- `users`: Usuarios del sistema
- `profiles`: Perfiles de usuario
- `commerces`: Restaurantes/comercios
- `products`: Productos
- `orders`: Órdenes/pedidos
- `order_items`: Items de órdenes
- `reviews`: Reseñas
- `notifications`: Notificaciones
- `favorites`: Favoritos

## 🔐 Autenticación

### JWT Token
```bash
# Obtener token
POST /api/auth/login
{
  "email": "user@example.com",
  "password": "password"
}

# Usar token
Authorization: Bearer {token}
```

## 📱 Funcionalidades por Rol

### Cliente (Nivel 0)
- Ver productos y restaurantes
- Agregar al carrito
- Realizar pedidos
- Ver historial de pedidos
- Calificar productos
- Chat con restaurante
- Notificaciones
- Geolocalización
- Favoritos

### Restaurante (Nivel 1)
- Gestionar productos
- Ver pedidos
- Actualizar estado
- Chat con clientes

### Delivery (Nivel 2)
- Ver pedidos asignados
- Actualizar ubicación
- Marcar como entregado

### Admin (Nivel 3)
- Gestión completa
- Reportes
- Configuración

## 🧪 Testing

### Frontend Tests
```bash
cd zonix-eats-front
flutter test
```

### Backend Tests
```bash
cd zonix-eats-back
php artisan test
```

## 📈 Estado del Proyecto

### ✅ Completado (Nivel 0)
- [x] Autenticación básica
- [x] CRUD de productos
- [x] Sistema de carrito
- [x] Gestión de órdenes
- [x] Chat en tiempo real
- [x] Notificaciones
- [x] Geolocalización
- [x] Favoritos
- [x] Reviews
- [x] Tests unitarios

### 🔄 En Desarrollo
- [ ] Nivel 1 (Restaurantes)
- [ ] Nivel 2 (Delivery)
- [ ] Nivel 3 (Admin)
- [ ] Pagos reales
- [ ] Push notifications
- [ ] Analytics

## 🐛 Troubleshooting

### Problemas Comunes

1. **Error de conexión WebSocket**
   - Verificar que Echo Server esté corriendo
   - Revisar configuración de URLs

2. **Error de API 400/401**
   - Verificar token de autenticación
   - Revisar configuración de CORS

3. **Error de base de datos**
   - Ejecutar migraciones: `php artisan migrate`
   - Verificar configuración de .env

## 📞 Soporte

Para soporte técnico o preguntas sobre el proyecto, contactar al equipo de desarrollo.

## 📄 Licencia

Este proyecto es privado y confidencial.

---

**Versión**: 1.0.0  
**Última actualización**: Julio 2024  
**Estado**: Nivel 0 Completado ✅
