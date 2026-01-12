# Zonix Eats Frontend - Aplicación Flutter

## 📋 Descripción General

Frontend de la aplicación Zonix Eats desarrollado en Flutter. Aplicación móvil multi-plataforma para sistema de delivery de comida con soporte para múltiples roles de usuario.

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
│   │   ├── websocket_service.dart
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
- `web_socket_channel: ^2.4.0` - Comunicación WebSocket

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
- Laravel Echo Server corriendo (puerto 6001)

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
API_URL_LOCAL=http://192.168.0.101:8000
API_URL_PROD=https://zonix.uniblockweb.com
```

**Nota:** Reemplazar `192.168.0.101` con la IP de tu servidor backend.

### Configuración de URLs

Las URLs se configuran en `lib/config/app_config.dart`:

```dart
class AppConfig {
  // API URLs
  static const String apiUrlLocal = 'http://192.168.0.101:8000';
  static const String apiUrlProd = 'https://zonix.uniblockweb.com';
  
  // WebSocket URLs
  static const String wsUrlLocal = 'ws://192.168.0.101:6001';
  static const String wsUrlProd = 'wss://zonix.uniblockweb.com';
  
  // La aplicación detecta automáticamente el entorno
  static String get apiUrl {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? apiUrlProd : apiUrlLocal;
  }
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
- ✅ Sincronización con backend
- ✅ Notas especiales

### Órdenes
- ✅ Crear órdenes
- ✅ Listar órdenes del usuario
- ✅ Detalles de orden
- ✅ Seguimiento de estado
- ✅ Cancelar órdenes
- ✅ Subir comprobante de pago

### Chat en Tiempo Real
- ✅ WebSocket implementado
- ✅ Mensajería por orden
- ✅ Notificaciones en tiempo real
- ✅ Reconexión automática

### Sistema Multi-Rol
- ✅ **Nivel 0 (users):** Cliente/Comprador
  - Ver productos y restaurantes
  - Carrito y órdenes
  - Chat y notificaciones
- ✅ **Nivel 1 (commerce):** Comercio/Restaurante
  - Dashboard de comercio
  - Gestión de productos
  - Gestión de órdenes
  - Reportes
- ✅ **Nivel 2 (delivery):** Repartidor
  - Órdenes asignadas
  - Actualización de ubicación
  - Historial de entregas
- ✅ **Nivel 3 (transport):** Agencia de Transporte
- ✅ **Nivel 4 (affiliate):** Afiliado a Delivery
- ✅ **Nivel 5 (admin):** Administrador

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

### WebSocket

```dart
import '../../features/services/websocket_service.dart';

final websocketService = WebSocketService();

// Conectar
await websocketService.connect();

// Suscribirse
await websocketService.subscribeToUser(userId);

// Escuchar mensajes
websocketService.messageStream?.listen((message) {
  if (message['type'] == 'order_status_changed') {
    // Actualizar UI
  }
});
```

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
- [x] Chat en tiempo real (WebSocket)
- [x] Notificaciones
- [x] Geolocalización
- [x] Sistema de reseñas
- [x] Favoritos
- [x] Perfiles de usuario
- [x] Gestión de direcciones y teléfonos

### 🔄 En Desarrollo / Pendiente

- [ ] **CRÍTICO:** Implementar TODOs en `commerce_service.dart` (12 métodos)
- [ ] **CRÍTICO:** Eliminar código comentado extenso en `main.dart`
- [ ] **ALTO:** Implementar internacionalización (i18n)
- [ ] **ALTO:** Implementar subida de imágenes completa
- [ ] Pagos reales (MercadoPago, PayPal)
- [ ] Push notifications nativas
- [ ] Analytics y métricas
- [ ] Optimizaciones de performance

## 🐛 Problemas Conocidos

### Críticos

1. **TODOs Sin Implementar**
   - **Archivo:** `lib/features/services/commerce_service.dart`
   - **Problema:** 12 métodos usan datos mock en lugar de API real
   - **Líneas:** 237, 253, 268, 283, 299, 320, 341, 355, 370, 394, 430, 453

2. **Código Comentado Extenso**
   - **Archivo:** `lib/main.dart`
   - **Problema:** ~330 líneas de código comentado
   - **Solución:** Eliminar código legacy

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

**WebSocket:**
- Conexión: `ws://{host}:6001`
- Autenticación: Token Sanctum
- Canales: `private-user.{userId}`, `private-order.{orderId}`, etc.

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

Este documento contiene un análisis exhaustivo completo del proyecto realizado en Diciembre 2024, cubriendo todas las áreas del sistema:

1. **Arquitectura y Estructura** - Patrones, stack tecnológico, organización
2. **Código y Calidad** - Code smells, patrones, complejidad
3. **Lógica de Negocio** - Entidades, flujos, servicios
4. **Base de Datos** - Modelos, estructura de datos
5. **Seguridad** - Autenticación, vulnerabilidades, protección
6. **Performance** - Bottlenecks, optimizaciones, escalabilidad
7. **Testing** - Cobertura, estrategia, calidad
8. **Frontend** - UI/UX, componentes, state management, routing
9. **Integración con Backend** - APIs, WebSocket, manejo de errores
10. **DevOps e Infraestructura** - Build, deployment, CI/CD
11. **Documentación** - Estado, calidad, mejoras
12. **Estado y Mantenibilidad** - Deuda técnica, métricas
13. **Oportunidades y Mejoras** - Roadmap, priorización

### Realizar Nuevo Análisis Exhaustivo

Cuando se solicite un análisis exhaustivo del proyecto, usar los prompts completos disponibles. El análisis debe:

- Explorar TODA la estructura del proyecto sin dejar áreas sin revisar
- Leer y analizar los archivos más importantes de cada módulo
- Identificar patrones, anti-patrones y code smells
- Proporcionar ejemplos concretos de código cuando sea relevante
- Priorizar hallazgos por criticidad (crítico, alto, medio, bajo)
- Sugerir mejoras específicas y accionables

**Ver:** `.cursorrules` para el prompt maestro completo de análisis.

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

## 🔗 Referencias

- **Flutter Docs:** https://flutter.dev/docs
- **Dart Docs:** https://dart.dev/guides
- **Provider Package:** https://pub.dev/packages/provider
- **HTTP Package:** https://pub.dev/packages/http
- **Análisis Exhaustivo:** Ver `ANALISIS_EXHAUSTIVO.md` en raíz del proyecto

## 📞 Soporte

Para soporte técnico o preguntas sobre el proyecto, contactar al equipo de desarrollo.

## 📄 Licencia

Este proyecto es privado y confidencial.

---

**Versión:** 1.0.0  
**Última actualización:** Diciembre 2024  
**Estado:** MVP Completado ✅ - En desarrollo activo
