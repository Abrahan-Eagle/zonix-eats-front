# Zonix Eats Frontend - Aplicación Flutter

## 📋 Descripción General

Frontend de la aplicación Zonix Eats desarrollado en Flutter. Aplicación móvil multi-plataforma para sistema de delivery de comida con soporte para múltiples roles de usuario.

## 📊 Estado del Proyecto (Actualizado: 12 Feb 2026)

| Métrica           | Valor                                          |
| ----------------- | ---------------------------------------------- |
| **Versión**       | 1.0.0                                          |
| **Flutter SDK**   | >=3.5.0 <4.0.0                                 |
| **Archivos Dart** | 173                                            |
| **Pantallas**     | 69                                             |
| **Servicios**     | 49 (2 legacy eliminados)                       |
| **Tests**         | 214 pasaron ✅, 0 fallaron                     |
| **Roles**         | 4 (Standard: Buyer, Commerce, Delivery, Admin) |

### Terminología Estándar de Roles

| Nivel | Código en BD | Nombre Estándar | Alias aceptados            |
| ----- | ------------ | --------------- | -------------------------- |
| 0     | `users`      | **Buyer**       | Comprador, Cliente         |
| 1     | `commerce`   | **Commerce**    | Comercio, Restaurante      |
| 2     | `delivery`   | **Delivery**    | Delivery Agent, Repartidor |
| 3     | `admin`      | **Admin**       | Administrador              |

### Cambios Recientes (Feb 2026)

- ✅ Eliminada mock data de 11 servicios (~700 líneas) - errores de API ahora se muestran correctamente
- ✅ Subida de imágenes para commerce implementada (ImagePicker + MultipartRequest)
- ✅ Navegación admin dashboard corregida (4 botones funcionales)
- ✅ Admin security page ahora consume API real
- ✅ URL `localhost` → `AppConfig` en account_deletion_service
- ✅ Profile ID hardcodeado `56` → parámetro dinámico en phone_service
- ✅ URL duplicada eliminada de cart_service
- ✅ Archivos legacy eliminados: `websocket_service.dart`, `order_ws_service.dart`
- ✅ ~118 líneas de código comentado eliminadas de google_sign_in_service

## 🏗️ Arquitectura

```
lib/
├── config/
│   └── app_config.dart          # Configuración central (URLs, timeouts)
├── features/
│   ├── screens/                 # 30+ pantallas organizadas por feature
│   │   ├── auth/                # Autenticación
│   │   ├── products/            # Productos
│   │   ├── cart/                # Carrito
│   │   ├── orders/              # Órdenes
│   │   ├── restaurants/         # Restaurantes
│   │   ├── commerce/            # Panel de comercio
│   │   ├── delivery/            # Panel de delivery
│   │   └── settings/            # Configuración
│   ├── services/                # 50+ servicios de comunicación con API
│   │   ├── auth/                # Servicios de autenticación
│   │   ├── cart_service.dart
│   │   ├── order_service.dart
│   │   ├── commerce_service.dart
│   │   ├── (Pusher/FCM para tiempo real)
│   │   └── ...
│   └── DomainProfiles/          # Módulos de perfiles
│       ├── Profiles/
│       ├── Addresses/
│       ├── Documents/
│       └── Phones/
├── models/                      # Modelos de datos
│   ├── order.dart
│   ├── product.dart
│   ├── commerce.dart
│   └── ...
├── helpers/
│   └── auth_helper.dart         # Helpers de autenticación
└── main.dart                    # Punto de entrada
```

## 🛠️ Stack Tecnológico

### Framework y Lenguaje

- **Flutter SDK:** >=3.5.0 <4.0.0
- **Dart:** 3.5.0+

### Dependencias Principales

**State Management:**

- `provider: ^6.1.2` - Gestión de estado

**Networking:**

- `http: ^1.2.2` - Cliente HTTP para API REST
- `pusher_channels_flutter` - Broadcasting en tiempo real (Pusher). No se usan WebSockets directos.

**Storage:**

- `flutter_secure_storage: ^9.2.2` - Almacenamiento seguro (tokens)
- `shared_preferences: ^2.3.2` - Preferencias locales

**Autenticación:**

- `google_sign_in: ^6.2.1` - Autenticación con Google
- `flutter_web_auth_2: ^3.1.2` - Autenticación web

**UI/UX:**

- `flutter_svg: ^2.0.10+1` - Soporte SVG
- `google_fonts: ^6.2.1` - Fuentes de Google
- `shimmer: ^2.0.0` - Efectos de carga
- `smooth_page_indicator: ^1.2.0+3` - Indicadores de página

**Utilidades:**

- `geolocator: ^13.0.1` - Geolocalización
- `image_picker: ^1.1.2` - Selección de imágenes
- `logger: ^2.4.0` - Sistema de logging
- `intl: ^0.19.0` - Internacionalización
- `flutter_dotenv: ^5.2.1` - Variables de entorno

## 🚀 Instalación y Configuración

### Prerrequisitos

- Flutter SDK >=3.5.0
- Dart SDK 3.5.0+
- Android Studio / Xcode (para desarrollo móvil)
- Backend Laravel corriendo (puerto 8000)
- Pusher configurado para broadcasting en tiempo real
- Firebase Cloud Messaging (FCM) configurado para push notifications

### Instalación

```bash
# 1. Clonar repositorio
cd zonix-eats-front

# 2. Instalar dependencias
flutter pub get

# 3. Configurar variables de entorno
# Crear archivo .env en la raíz del proyecto
cp .env.example .env
# Editar .env con tus configuraciones

# 4. Ejecutar aplicación
flutter run
```

### Configuración de Variables de Entorno

Crear archivo `.env` en la raíz del proyecto:

```env
API_URL_LOCAL=http://192.168.27.12:8000
API_URL_PROD=https://eats.aiblockweb.com
```

**Nota:** Reemplazar `192.168.0.101` con la IP de tu servidor backend.

### Configuración de URLs

Las URLs se configuran en `lib/config/app_config.dart`:

```dart
class AppConfig {
  // API URLs
  static const String apiUrlLocal = 'http://192.168.27.12:8000';
  static const String apiUrlProd = 'https://eats.aiblockweb.com';

  // Pusher configuration (si se usa directamente)
  // Nota: La mayoría de notificaciones en tiempo real usan Firebase + Pusher
  // a través de los eventos del backend, no conexiones WebSocket directas
}
```

**IMPORTANTE:** Siempre usar `AppConfig.apiUrl` en lugar de URLs hardcodeadas.

## 📱 Funcionalidades Implementadas

### Autenticación

- ✅ Login con email/password
- ✅ Registro de usuarios
- ✅ Autenticación con Google OAuth
- ✅ Gestión de sesión con tokens Sanctum
- ✅ Logout y refresh de tokens

### Productos y Restaurantes

- ✅ Catálogo de productos
- ✅ Búsqueda y filtros
- ✅ Detalles de producto
- ✅ Lista de restaurantes/comercios
- ✅ Detalles de restaurante
- ✅ Productos por restaurante

### Carrito de Compras

- ✅ Agregar productos al carrito
- ✅ Actualizar cantidades
- ✅ Remover productos
- ✅ Sincronización con backend (base de datos)
- ✅ Notas especiales

**REGLAS DE NEGOCIO:**

- **NO puede haber productos de diferentes comercios en el mismo carrito**
- Si el usuario intenta agregar un producto de otro comercio, el sistema limpia el carrito automáticamente
- Validación de cantidad: min:1, max:100
- Validación de disponibilidad: Solo productos `available = true`
- Validación de stock: Si tiene `stock_quantity`, verificar que haya suficiente

### Órdenes

- ✅ Crear órdenes
- ✅ Listar órdenes del usuario
- ✅ Detalles de orden
- ✅ Seguimiento de estado
- ✅ Cancelar órdenes
- ✅ Subir comprobante de pago

### Chat y notificaciones en tiempo real

- ✅ Firebase Cloud Messaging (FCM) + Pusher (no WebSocket directo)
- ✅ Mensajería por orden vía canales Pusher
- ✅ Notificaciones en tiempo real
- ✅ Reconexión automática (Pusher)

### Sistema Multi-Rol

**Roles implementados y funcionales (MVP):**

- ✅ **Level 0 (users):** Cliente/Comprador
  - Ver productos y restaurantes
  - Carrito y órdenes
  - Chat y notificaciones
- ✅ **Level 1 (commerce):** Comercio/Restaurante
  - Dashboard de comercio
  - Gestión de productos
  - Gestión de órdenes
  - Reportes
- ✅ **Level 2 (delivery):** Repartidor
  - **Jerarquía:** Delivery Company → Delivery Agents
  - Órdenes asignadas
  - Actualización de ubicación
  - Historial de entregas
- ✅ **Level 3 (admin):** Administrador
  - Gestión completa del sistema
  - Usuarios y roles
  - Reportes globales

**IMPORTANTE:** Solo existen estos 4 roles. Los roles `transport` y `affiliate` fueron eliminados del código y del dashboard.

### 📋 LÓGICA DE NEGOCIO Y DATOS REQUERIDOS POR ROL - MVP

**Decisiones Clave del MVP:**

1. **Carrito:** NO puede haber productos de diferentes comercios (uni-commerce)
2. **Validación de Precio:** Recalcular y validar contra total enviado
3. **Stock:** AMBAS opciones (`available` Y `stock_quantity`) - Validar siempre available, si tiene stock_quantity validar cantidad
4. **Delivery:** Sistema completo (propio, empresas, independientes) + Asignación autónoma con expansión de área
5. **Eventos:** Firebase + Pusher (NO WebSocket)
6. **Perfiles:** Datos mínimos (USERS) vs completos (COMMERCE, DELIVERY)
7. **photo_users:** Required estricto (bloquea creación de orden)
8. **Geolocalización Comercios:** Búsqueda inicial 1-1.5km, expansión automática a 4-5km
9. **Asignación Delivery:** Autónoma con expansión automática de área (1-1.5km → 4-5km → continua)
10. **Cancelación:** Límite 5 minutos O hasta validación de pago
11. **Reembolsos:** Manual (no automático)

### 💰 MODELO DE NEGOCIO - RESUMEN

**Costos y Precios:**

- **Costo Delivery:** Híbrido (Base fija $2.00 + $0.50/km después de 2 km) - Configurable por admin
- **Quién paga delivery:** Cliente (se agrega al total de la orden)
- **Membresía/Comisión:** Membresía mensual obligatoria (base) + Comisión % sobre ventas del mes (extra)
  - Ejemplo: $100/mes + 10% de ventas = $100 + $500 (si vendió $5,000) = $600 total
- **Mínimo pedido:** No hay mínimo
- **Tarifa servicio:** No hay (solo subtotal + delivery)
- **Propinas:** No permitidas

**Pagos:**

- **Métodos:** Todos (efectivo, transferencia, tarjeta, pago móvil, digitales)
- **Quién recibe:** Comercio directamente (con sus datos bancarios)
- **Manejo:** Tiempo real (validación manual de comprobante)
- **Pago a delivery:** Del comercio (después de recibir pago del cliente) → **Delivery recibe 100% del delivery_fee** (Opción A confirmada)

**Límites:**

- **Distancia máxima:** 60 minutos de tiempo estimado de viaje
- **Quejas/Disputas:** Sistema de tickets con admin (tabla `disputes`)

**Horarios:**

- **Comercios:** Definen horarios + campo `open` manual
- **Delivery:** 24/7 según disponibilidad (campo `working`)

**Ver backend README.md sección completa "💰 MODELO DE NEGOCIO" para detalles detallados.**

### Penalizaciones y Tiempos Límite

**Cancelaciones:**

- **Comercio:** Puede cancelar con justificación. Penalización si excede límite
- **Cliente:** Límite 5 minutos. Penalización si crea múltiples órdenes sin pagar
- **Comisión en cancelación:** Penalización adicional si comercio cancela después de `paid`

**Delivery rechaza:**

- Debe justificar. Penalización si rechaza 3-5 órdenes seguidas
- Ideal: Bajar switch `working = false` si no está disponible

**Tiempos límite:**

- Cliente sube comprobante: 5 minutos (cancelación automática)
- Comercio valida pago: 5 minutos (cancelación automática)

**Rating/Reviews:**

- Obligatorio después de orden entregada
- Comercio y delivery separados, no editables

**Promociones:**

- Manual (comercio y admin)
- Código promocional O automático

**Métodos de pago:**

- Solo UN método de pago por orden (no se puede pagar mitad y mitad)

**Delivery no encontrado:**

- Continúa buscando hasta encontrar delivery disponible
- NO cancela la orden, espera hasta que haya delivery disponible
- Notificaciones al cliente y comercio del estado de búsqueda

#### 👤 ROL: USERS (Comprador/Cliente)

**Datos Mínimos para Crear Orden:**

- **firstName** (required)
- **lastName** (required)
- **phone** (required)
- **photo_users** (required) - Necesaria para que delivery pueda hacer la entrega

**Direcciones - Sistema de 2 Direcciones:**

1. **Dirección Predeterminada (Casa):** `is_default = true` en tabla `addresses`
   - **Uso:** Base para búsqueda de comercios por geolocalización
   - **Ubicación:** GPS + inputs y selects para mayor precisión
2. **Dirección de Entrega (Pedido):** Puede ser diferente, se guarda temporalmente o como nueva dirección
   - **Ubicación:** GPS + inputs y selects para mayor precisión

**Búsqueda de Comercios por Geolocalización:**

- **Ubicación base:** Dirección predeterminada del usuario (casa) con `is_default = true`
- **Rango inicial:** 1-1.5 km desde la ubicación del usuario
- **Expansión automática:** Si no hay comercios abiertos, expande automáticamente a 4-5 km
- **Expansión manual:** Usuario puede ampliar el rango manualmente si desea buscar más lejos
- **Cálculo:** Haversine para calcular distancia entre coordenadas GPS

**Campos de dirección:** `street`, `house_number`, `postal_code`, `latitude`, `longitude`, `city_id`, `is_default`

**Ver backend README.md sección completa para detalles de todos los campos opcionales.**

#### 🏪 ROL: COMMERCE (Vendedor/Tienda)

**Datos Requeridos:** 7 campos (firstName, lastName, phone, address, business_name, business_type, tax_id)

**Datos Opcionales:** 16 campos (6 del perfil, 5 del comercio, 3 relaciones, 2 del sistema)

**Comercio:** `image` (logo), `phone`, `address`, `open`, `schedule`

**Ver backend README.md para lista completa de campos opcionales.**

#### 🚚 ROL: DELIVERY

**Delivery Company:**

- **Requeridos:** 9 campos + photo_users (required)
- **Opcionales:** image (logo), phone, address, open, schedule (igual estructura que COMMERCE)

**Delivery Agent:**

- **Requeridos:** firstName, lastName, phone, address, photo_users (required), vehicle_type, license_number
- **Puede ser independiente:** `company_id = null`

**Ver backend README.md sección completa para detalles detallados.**

### Onboarding comercio (paso 4)

- ✅ Crear comercio con perfil existente: `POST /api/profiles/add-commerce` (createCommerceForExistingProfile)
- ✅ Envío de `schedule` como **string** (jsonEncode del Map) para cumplir validación del backend
- ✅ Dirección del establecimiento con `commerce_id` (AddressService.createAddress con commerceId, sin profile_id en body)

### Otras Funcionalidades

- ✅ Sistema de reseñas/calificaciones
- ✅ Favoritos
- ✅ Notificaciones push
- ✅ Geolocalización
- ✅ Perfiles de usuario
- ✅ Gestión de direcciones
- ✅ Gestión de teléfonos
- ✅ Gestión de documentos

## 🔧 Configuración y Desarrollo

### Estructura de Servicios

Los servicios se organizan por dominio y siguen el patrón Provider:

```dart
class OrderService extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Llamada a API
      final orders = await _fetchOrders();
      _orders = orders;
    } catch (e) {
      // Manejo de errores
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Comunicación con API

**SIEMPRE usar AppConfig y AuthHelper:**

```dart
import '../../config/app_config.dart';
import '../../helpers/auth_helper.dart';

final url = Uri.parse('${AppConfig.apiUrl}/api/buyer/orders');
final headers = await AuthHelper.getAuthHeaders();
final response = await http.get(url, headers: headers);
```

### Manejo de Errores

```dart
try {
  final response = await http.get(url, headers: headers);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return processData(data['data']);
    }
  } else if (response.statusCode == 401) {
    // Token expirado - manejar logout
    await _handleUnauthorized();
  }
} catch (e) {
  logger.e('Error: $e');
  rethrow;
}
```

### Firebase + Pusher (Eventos en Tiempo Real)

**✅ IMPLEMENTADO:** Firebase Cloud Messaging (FCM) + Pusher para notificaciones en tiempo real

**Eventos disponibles:**

- `OrderCreated` - Nueva orden creada
- `OrderStatusChanged` - Estado de orden cambiado
- `PaymentValidated` - Pago validado
- `NewMessage` - Nuevo mensaje de chat
- `DeliveryLocationUpdated` - Ubicación de delivery actualizada
- `NotificationCreated` - Nueva notificación

**Canales (Pusher):**

- `private-user.{userId}` - Notificaciones de usuario
- `private-order.{orderId}` - Actualizaciones de orden
- `private-chat.{orderId}` - Chat de orden
- `private-commerce.{commerceId}` - Notificaciones de comercio

**IMPORTANTE:** El sistema de notificaciones en tiempo real usa exclusivamente Firebase + Pusher. NO usar WebSocket directo; los canales y eventos se gestionan desde el backend con Pusher.

## 🧪 Testing

### Ejecutar Tests

```bash
# Todos los tests
flutter test

# Tests específicos
flutter test test/services/cart_service_test.dart

# Con coverage
flutter test --coverage
```

### Estructura de Tests

```
test/
├── services/           # Tests de servicios
├── models/             # Tests de modelos
├── widgets/            # Tests de widgets
└── integration/        # Tests de integración
```

## 📊 Estado del Proyecto

### ✅ Completado

- [x] Autenticación completa (login, registro, Google)
- [x] Sistema multi-rol funcional
- [x] Catálogo de productos
- [x] Sistema de carrito
- [x] Gestión de órdenes
- [x] Chat en tiempo real (Firebase + Pusher)
- [x] Notificaciones
- [x] Geolocalización
- [x] Sistema de reseñas
- [x] Favoritos
- [x] Perfiles de usuario
- [x] Gestión de direcciones y teléfonos

### 🔄 En Desarrollo / Pendiente

- [x] ~~**CRÍTICO:** Implementar TODOs en múltiples servicios~~ ✅ **COMPLETADO** (commerce, payment, delivery, chat, admin, analytics, location, notification)
- [x] ~~**CRÍTICO:** Eliminar código comentado extenso en `main.dart`~~ ✅ **COMPLETADO**
- [ ] **ALTO:** Implementar internacionalización (i18n)
- [ ] **ALTO:** Implementar subida de imágenes completa
- [ ] Pagos reales (MercadoPago, PayPal)
- [ ] Push notifications nativas
- [x] ~~Analytics y métricas~~ ✅ **COMPLETADO** (CommerceReportsPage + CommerceAnalyticsService con API real)
- [ ] Optimizaciones de performance

## 🐛 Problemas Conocidos

### Críticos (RESUELTOS ✅)

1. ~~**TODOs Sin Implementar (CRÍTICO)**~~ ✅ **COMPLETADO**
   - **Ubicación:** Múltiples servicios en `lib/features/services/`
   - **Estado actual:** Todos los servicios MVP con llamadas reales a API:
     - ~~`commerce_service.dart`: 12 TODOs~~ ✅ COMPLETADO
     - ~~`payment_service.dart`: 11 TODOs~~ ✅ COMPLETADO
     - ~~`admin_service.dart`: 13 TODOs~~ ✅ COMPLETADO
     - ~~`analytics_service.dart`: 11 TODOs~~ ✅ COMPLETADO
     - ~~`delivery_service.dart`: 11 TODOs~~ ✅ COMPLETADO
     - ~~`chat_service.dart`: 9 TODOs~~ ✅ COMPLETADO
     - ~~`location_service.dart`: 1 TODO~~ ✅ COMPLETADO
     - ~~`notification_service.dart`: 3 TODOs~~ ✅ COMPLETADO
     - ~~`affiliate_service.dart`~~ (EXCLUIDO DEL MVP)
     - ~~`transport_service.dart`~~ (EXCLUIDO DEL MVP)

2. ~~**Código Comentado Extenso**~~ ✅ **COMPLETADO**
   - **Archivo:** `lib/main.dart`
   - **Solución aplicada:** ~330 líneas de código comentado eliminadas

### Altos

3. **Falta Internacionalización**
   - **Archivos:** Múltiples (especialmente `settings_page_2.dart`)
   - **Problema:** Strings hardcodeados en español
   - **Solución:** Implementar i18n con `flutter_localizations`

4. **Subida de Imágenes Incompleta**
   - **Archivos:** `commerce_data_service.dart`, `commerce_data_page.dart`
   - **Problema:** TODOs sin implementar
   - **Solución:** Completar implementación

## 🔒 Seguridad

### Buenas Prácticas Implementadas

- ✅ Tokens almacenados en `flutter_secure_storage`
- ✅ Headers de autenticación centralizados en `AuthHelper`
- ✅ Validación de respuestas de API
- ✅ Manejo de tokens expirados
- ✅ URLs centralizadas en `AppConfig`

### Recomendaciones

- ⚠️ No hardcodear secrets en código
- ⚠️ Validar input del usuario antes de enviar
- ⚠️ Sanitizar datos antes de mostrar en UI

## 📈 Performance

### Optimizaciones Implementadas

- ✅ Provider para state management eficiente
- ✅ Lazy loading de imágenes (donde aplica)
- ✅ Caching básico de datos

### Mejoras Pendientes

- [ ] Implementar lazy loading de rutas
- [ ] Optimizar bundle size
- [ ] Implementar code splitting
- [ ] Cachear respuestas de API
- [ ] Optimizar re-renders

## 🔄 Integración con Backend

### Endpoints Principales

**Autenticación:**

- `POST /api/auth/login`
- `POST /api/auth/register`
- `POST /api/auth/google`
- `POST /api/auth/logout`

**Productos:**

- `GET /api/buyer/products`
- `GET /api/buyer/products/{id}`

**Carrito:**

- `GET /api/buyer/cart`
- `POST /api/buyer/cart/add`
- `PUT /api/buyer/cart/update-quantity`
- `DELETE /api/buyer/cart/{productId}`

**Órdenes:**

- `GET /api/buyer/orders`
- `POST /api/buyer/orders`
- `GET /api/buyer/orders/{id}`

**Onboarding comercio:**

- `POST /api/profiles/add-commerce` — Añadir comercio a perfil existente (body: profile_id, business_name, business_type, tax_id, address, open, **schedule** como string, owner_ci)

**Firebase + Pusher:**

- Firebase Cloud Messaging (FCM) - Push notifications a dispositivos móviles
- Pusher - Broadcasting en tiempo real (web)
- Autenticación: Token Sanctum
- Canales Pusher: `private-user.{userId}`, `private-order.{orderId}`, etc.

### Formato de Respuestas

El backend responde con el siguiente formato:

```json
{
  "success": true,
  "data": { ... },
  "message": "Operación exitosa"
}
```

## 🛠️ Comandos Útiles

```bash
# Instalar dependencias
flutter pub get

# Actualizar dependencias
flutter pub upgrade

# Ejecutar aplicación
flutter run

# Ejecutar en dispositivo específico
flutter run -d <device_id>

# Build para Android
flutter build apk

# Build para iOS
flutter build ios

# Limpiar proyecto
flutter clean

# Analizar código
flutter analyze

# Formatear código
flutter format lib/
```

## 📚 Convenciones de Código

### Nomenclatura

- **Archivos:** snake_case (ej: `cart_service.dart`)
- **Clases:** PascalCase (ej: `CartService`)
- **Variables:** lowerCamelCase (ej: `orderId`)
- **Constantes:** UPPER_SNAKE_CASE (ej: `API_BASE_URL`)

### Estructura

- Una pantalla por archivo
- Servicios separados por dominio
- Modelos con `fromJson`, `toJson`, `copyWith`
- Widgets reutilizables en carpetas separadas

### Documentación

- Usar `///` para documentar clases y métodos públicos
- Comentar lógica compleja
- Mantener README actualizado

## 📊 Análisis Exhaustivo del Proyecto

### Documento de Análisis Completo

**Ubicación:** `ANALISIS_EXHAUSTIVO.md` (raíz del proyecto WorksPageZonixEats)  
**Versión de Prompts:** 2.0 - Basada en Experiencia Real

Este documento contiene un análisis exhaustivo completo del proyecto realizado en Diciembre 2024, cubriendo todas las áreas del sistema:

1. **Arquitectura y Estructura** - Patrones, stack tecnológico, organización
2. **Código y Calidad** - Code smells, patrones, complejidad
3. **Lógica de Negocio** - Entidades, flujos, servicios
4. **Base de Datos** - Modelos, estructura de datos
5. **Seguridad** - Autenticación, vulnerabilidades, OWASP Top 10 completo
6. **Performance** - Bottlenecks, optimizaciones, escalabilidad, métricas
7. **Testing** - Cobertura, estrategia, calidad, plan de mejora
8. **Frontend** - UI/UX, componentes, state management, routing
9. **Integración con Backend** - APIs, Firebase + Pusher, manejo de errores
10. **DevOps e Infraestructura** - Build, deployment, CI/CD
11. **Documentación** - Estado, calidad, mejoras
12. **Verificación de Coherencia** ⭐ **NUEVO** - Coherencia entre archivos de documentación
13. **Estado y Mantenibilidad** - Deuda técnica, métricas, score
14. **Oportunidades y Mejoras** - Roadmap técnico priorizado, quick wins

### Realizar Nuevo Análisis Exhaustivo

Cuando se solicite un análisis exhaustivo del proyecto, usar los **prompts completos v2.0** disponibles. El análisis debe seguir esta metodología:

**FASE 1: EXPLORACIÓN INICIAL**

- Mapear estructura completa de directorios y archivos
- Identificar archivos de configuración clave
- Leer archivos de documentación principales
- Identificar stack tecnológico completo y versiones

**FASE 2: ANÁLISIS PROFUNDO POR ÁREA**

- Explorar TODA la estructura del proyecto sin dejar áreas sin revisar
- Leer y analizar los archivos más importantes de cada módulo
- Identificar patrones, anti-patrones y code smells
- Proporcionar ejemplos concretos de código (formato: archivo:línea)
- Priorizar hallazgos por criticidad (crítico, alto, medio, bajo)
- Sugerir mejoras específicas con impacto/esfuerzo/prioridad

**FASE 3: VERIFICACIÓN DE COHERENCIA** ⭐ **CRÍTICO**

- Comparar métricas mencionadas en diferentes documentos
- Verificar que números y estadísticas coincidan entre README y .cursorrules
- Identificar discrepancias y corregirlas o documentar razones
- Asegurar que el estado del proyecto sea consistente en toda la documentación

**Ver:** `.cursorrules` para el prompt maestro completo v2.0 con todas las instrucciones detalladas.

### Actualizar Análisis

**Cuándo actualizar:**

- Después de cambios arquitectónicos importantes
- Después de implementar mejoras críticas identificadas
- Cada 3-6 meses o cuando se solicite
- Antes de releases mayores

**Cómo actualizar:**

1. Revisar cambios desde último análisis
2. Ejecutar análisis exhaustivo siguiendo los prompts completos
3. Actualizar `ANALISIS_EXHAUSTIVO.md` con nuevos hallazgos
4. Actualizar fecha de última actualización en este README

## 🗺️ ROADMAP MVP - PLAN DE ACCIÓN PRIORIZADO

**Estado actual:** MVP completado (~100% fases 1-3)  
**Objetivo:** Llegar al 100% del MVP ✅  
**Nota:** Se excluyeron `transport` y `affiliate` del MVP

### 🔴 FASE 1: CRÍTICO - Funcionalidad Core (4-6 semanas)

1. ✅ **Corregir Tests Fallando** (COMPLETADO) - Backend: Todos los tests pasan (204 tests, 751 assertions)
2. ✅ **Migrar Carrito de Session a BD** (COMPLETADO) - Backend: Migrado a tablas `carts` y `cart_items`
3. ✅ **TODOs Commerce Service** (COMPLETADO) - Frontend: 12 métodos implementados
4. ✅ **TODOs Payment Service** (COMPLETADO) - Frontend: 11 métodos implementados
5. ✅ **TODOs Delivery Service** (COMPLETADO) - Frontend: 11 métodos implementados
6. ✅ **TODOs Chat Service** (COMPLETADO) - Frontend: 9 métodos implementados

### 🟡 FASE 2: ALTA PRIORIDAD - Seguridad y Calidad (2-3 semanas)

7. ✅ **Restringir CORS** (COMPLETADO) - Backend: Configurado desde `.env` con `CORS_ALLOWED_ORIGINS`
8. ✅ **Rate Limiting** (COMPLETADO) - Backend: Configurado desde `.env` con límites específicos por tipo
9. ✅ **Paginación en Endpoints** (COMPLETADO) - Backend: Agregada a todos los endpoints de listado
10. ✅ **TODOs Admin Service** (COMPLETADO) - Frontend: 12 métodos implementados
11. ✅ **TODOs Notification Service** (COMPLETADO) - Frontend: 3 métodos implementados
12. ✅ **Índices BD Faltantes** (COMPLETADO) - Backend: Índices agregados para mejorar performance

### 🟢 FASE 3: MEDIA PRIORIDAD - Optimizaciones (1-2 semanas)

13. ✅ **TODOs Analytics Service** (COMPLETADO) - Frontend: 11 métodos implementados con llamadas reales a API
14. ✅ **TODO Location Service** (COMPLETADO) - Frontend: getDeliveryRoutes implementado con llamada real a API
15. ✅ **Limpiar Código Comentado** (COMPLETADO) - Frontend: ~330 líneas eliminadas de main.dart
16. ✅ **Eager Loading Faltante** (COMPLETADO) - Backend: Eager loading agregado para evitar queries N+1
17. ✅ **Analytics Commerce** (COMPLETADO) - Frontend: CommerceReportsPage conectado con API real, CommerceAnalyticsService creado

### 🔵 FASE 4: BAJA PRIORIDAD - Mejoras Adicionales (2-3 semanas)

17. **Documentación API (Swagger)** (1 semana) - Backend
18. **Caching** (1 semana) - Backend
19. **Internacionalización i18n** (1-2 semanas) - Frontend
20. **Mejorar Sistema de Roles** (3-5 días) - Backend

**Total TODOs para MVP:** ✅ **TODOS COMPLETADOS** (commerce, payment, delivery, chat, admin, analytics, location, notification; código comentado eliminado; analytics commerce con API real)

---

## 🔗 Referencias

- **Flutter Docs:** https://flutter.dev/docs
- **Dart Docs:** https://dart.dev/guides
- **Provider Package:** https://pub.dev/packages/provider
- **HTTP Package:** https://pub.dev/packages/http
- **Análisis Exhaustivo:** Ver `ANALISIS_EXHAUSTIVO.md` en raíz del proyecto

## ✅ Correcciones Recientes (Enero 2025)

### Errores Críticos Corregidos:

- ✅ **FlutterSecureStorage:** Manejo de errores BAD_DECRYPT implementado con limpieza automática de almacenamiento corrupto
- ✅ **AdminDashboardPage:** Manejo de valores null en métricas de sistema (cpu_usage, memory_usage, disk_usage)
- ✅ **Roles:** Limpieza completa - solo 4 roles válidos (users, commerce, delivery, admin)
- ✅ **Dashboard:** Eliminados niveles 3 y 4 (Transport y Affiliate), admin movido a nivel 3
- ✅ **Servicios Commerce:** 34 métodos corregidos (URLs y lógica duplicada eliminada)
- ✅ **QR Profile Service:** Endpoint corregido y manejo de errores mejorado
- ✅ **UserProvider:** Sistema de caché y debouncing implementado para prevenir HTTP 429
- ✅ **Tests:** Todos los tests actualizados para usar solo los 4 roles válidos

### Completado 27 Enero 2025 (MVP listo):

- ✅ **TODOs servicios MVP:** commerce, payment, delivery, chat, admin, analytics, location, notification con llamadas reales a API
- ✅ **Código comentado:** ~330 líneas eliminadas de `main.dart`
- ✅ **Analytics commerce:** CommerceReportsPage + CommerceAnalyticsService con API real

### Roles del Sistema:

Solo existen **4 roles válidos**:

- **users** (Level 0): Cliente/Comprador
- **commerce** (Level 1): Comercio/Restaurante
- **delivery** (Level 2): Repartidor/Delivery
- **admin** (Level 3): Administrador

Los roles `transport` y `affiliate` fueron eliminados del código y del dashboard.

## 📞 Soporte

Para soporte técnico o preguntas sobre el proyecto, contactar al equipo de desarrollo.

## 📄 Licencia

Este proyecto es privado y confidencial.

---

**Versión:** 1.0.0  
**Última actualización:** 11 Febrero 2026  
**Estado:** ✅ MVP Completado - En desarrollo activo  
**Tests:** 214 tests pasaron ✅, 0 tests fallaron ✅ (incl. onboarding: payload schedule string, testWidgets con pump)  
**Errores críticos:** ✅ Todos corregidos  
**TODOs servicios MVP:** ✅ Completados (commerce, payment, delivery, chat, admin, analytics, location, notification)
