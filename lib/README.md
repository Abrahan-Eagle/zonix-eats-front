# Zonix Eats Frontend - Flutter App

## 📋 Descripción

Aplicación móvil de Zonix Eats desarrollada en Flutter. Proporciona una interfaz completa para clientes, comercios y repartidores con funcionalidades en tiempo real.

## 🏗️ Arquitectura

```
lib/
├── config/              # Configuración de la app
├── features/            # Funcionalidades principales
│   ├── screens/         # Pantallas de la app
│   ├── services/        # Servicios de API y WebSocket
│   ├── utils/           # Utilidades específicas
│   └── DomainProfiles/  # Gestión de perfiles
├── helpers/             # Helpers generales
├── models/              # Modelos de datos
└── main.dart           # Punto de entrada
```

## 🚀 Instalación

### Prerrequisitos
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- Dispositivo físico o emulador

### Configuración

1. **Instalar dependencias**
```bash
flutter pub get
```

2. **Configurar URLs**
```dart
// lib/config/app_config.dart
class AppConfig {
  static const String baseUrl = 'http://192.168.27.12:8000/api';
  static const String echoServerUrl = 'http://192.168.27.12:6001';
}
```

3. **Ejecutar aplicación**
```bash
flutter run
```

## 📱 Funcionalidades Implementadas

### 🔐 Autenticación
- Login/Registro de usuarios
- Gestión de tokens JWT
- Persistencia de sesión
- Logout seguro

### 🏪 Restaurantes y Productos
- Lista de restaurantes
- Detalles de restaurante
- Catálogo de productos
- Búsqueda y filtros
- Imágenes con fallback

### 🛒 Carrito de Compras
- Agregar productos
- Actualizar cantidades
- Remover productos
- Calcular totales
- Persistencia local

### 📦 Órdenes
- Crear nueva orden
- Ver historial de pedidos
- Seguimiento en tiempo real
- Cancelar órdenes
- Estados de pedido

### ⭐ Reviews y Calificaciones
- Calificar productos
- Ver reseñas
- Editar reseñas
- Sistema de estrellas

### 💬 Chat en Tiempo Real
- Mensajería instantánea
- Notificaciones push
- Indicador de escritura
- Historial de mensajes

### 🔔 Notificaciones
- Notificaciones push
- Notificaciones en tiempo real
- Marcar como leídas
- Configuración de notificaciones

### 📍 Geolocalización
- Obtener ubicación actual
- Calcular rutas
- Lugares cercanos
- Zonas de entrega

### ❤️ Favoritos
- Agregar restaurantes favoritos
- Ver lista de favoritos
- Remover favoritos
- Sincronización con backend

## 🏗️ Estructura Detallada

### Configuración
```
lib/config/
├── app_config.dart      # URLs y configuración general
├── theme.dart           # Tema de la aplicación
└── constants.dart       # Constantes globales
```

### Features
```
lib/features/
├── screens/             # Pantallas principales
│   ├── auth/           # Autenticación
│   ├── products/       # Productos
│   ├── cart/           # Carrito
│   ├── orders/         # Órdenes
│   ├── profile/        # Perfil
│   └── notifications/  # Notificaciones
├── services/           # Servicios de API
│   ├── auth_service.dart
│   ├── product_service.dart
│   ├── order_service.dart
│   ├── pusher_service.dart
│   └── notification_service.dart
└── utils/              # Utilidades
    ├── image_utils.dart
    ├── location_utils.dart
    └── validation_utils.dart
```

### Modelos
```
lib/models/
├── user.dart           # Modelo de usuario
├── product.dart        # Modelo de producto
├── order.dart          # Modelo de orden
├── cart_item.dart      # Modelo de item del carrito
└── notification.dart   # Modelo de notificación
```

## 🔧 Servicios Principales

### AuthService
```dart
class AuthService {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> register(String name, String email, String password);
  Future<void> logout();
  Future<Map<String, dynamic>> getUserDetails();
}
```

### ProductService
```dart
class ProductService {
  Future<List<Product>> fetchProducts();
  Future<Product> fetchProductDetails(int id);
  Future<List<Product>> fetchProductsByRestaurant(int restaurantId);
}
```

### OrderService
```dart
class OrderService {
  Future<List<Order>> fetchOrders();
  Future<Order> createOrder(Map<String, dynamic> orderData);
  Future<Order> fetchOrderDetails(int id);
  Future<void> cancelOrder(int id);
}
```

### PusherService (Realtime)
```dart
class PusherService {
  Future<bool> initialize();
  Future<bool> subscribeToProfileChannel(
    String channelName, {
    required Function(String eventName, Map<String, dynamic> data) onDomainEvent,
  });
  Future<void> unsubscribeFromChannel(String channelName);
  Future<void> disconnect();
}
```

### NotificationService
```dart
class NotificationService {
  Future<List<Notification>> fetchNotifications();
  Future<void> markAsRead(int id);
  Future<void> deleteNotification(int id);
}
```

## 🎨 UI/UX Components

### Widgets Reutilizables
```dart
// ImageWithFallback
class ImageWithFallback extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  
  // Widget con fallback atractivo para imágenes rotas
}

// LoadingWidget
class LoadingWidget extends StatelessWidget {
  final String message;
  
  // Widget de carga consistente
}

// ErrorWidget
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  
  // Widget de error con opción de reintentar
}
```

### Temas y Estilos
```dart
// lib/config/theme.dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.orange,
      fontFamily: 'Roboto',
      // Configuración completa del tema
    );
  }
}
```

## 📊 Estado de la Aplicación

### Gestión de Estado
- **Provider**: Para estado global
- **SharedPreferences**: Para persistencia local
- **Streams**: Para comunicación en tiempo real

### Ejemplo de Provider
```dart
class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  
  List<CartItem> get items => _items;
  double get total => _items.fold(0, (sum, item) => sum + item.total);
  
  void addItem(Product product, int quantity) {
    // Lógica para agregar al carrito
    notifyListeners();
  }
}
```

## 🔐 Seguridad

### Almacenamiento Seguro
```dart
// lib/helpers/auth_helper.dart
class AuthHelper {
  static const _storage = FlutterSecureStorage();
  
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
}
```

### Validación de Datos
```dart
// lib/features/utils/validation_utils.dart
class ValidationUtils {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
}
```

## 🧪 Testing

### Tests Unitarios
```dart
// test/services/auth_service_test.dart
void main() {
  group('AuthService Tests', () {
    test('should login successfully with valid credentials', () async {
      // Test de login
    });
    
    test('should fail login with invalid credentials', () async {
      // Test de login fallido
    });
  });
}
```

### Tests de Widgets
```dart
// test/widgets/login_screen_test.dart
void main() {
  testWidgets('Login screen shows all required fields', (WidgetTester tester) async {
    await tester.pumpWidget(LoginScreen());
    
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
```

### Ejecutar Tests
```bash
# Todos los tests
flutter test

# Tests específicos
flutter test test/services/auth_service_test.dart

# Tests con coverage
flutter test --coverage
```

## 📱 Navegación

### Rutas Principales
```dart
// lib/main.dart
MaterialApp(
  routes: {
    '/': (context) => SplashScreen(),
    '/login': (context) => LoginScreen(),
    '/home': (context) => HomeScreen(),
    '/products': (context) => ProductsScreen(),
    '/cart': (context) => CartScreen(),
    '/orders': (context) => OrdersScreen(),
    '/profile': (context) => ProfileScreen(),
  },
)
```

### Navegación con Parámetros
```dart
// Navegar a detalles de producto
Navigator.pushNamed(
  context, 
  '/product-details',
  arguments: {'productId': product.id}
);

// Recibir parámetros
final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
final productId = args['productId'];
```

## 🔄 Integración con Backend

### Configuración de HTTP Client
```dart
// lib/features/services/base_service.dart
class BaseService {
  static final http = HttpClient();
  
  static Future<Map<String, String>> getHeaders() async {
    final token = await AuthHelper.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
```

### Manejo de Errores
```dart
class ApiException implements Exception {
  final String message;
  final int statusCode;
  
  ApiException(this.message, this.statusCode);
}

// En servicios
try {
  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw ApiException('Error en la API', response.statusCode);
  }
} catch (e) {
  throw ApiException('Error de conexión', 0);
}
```

## 📊 Performance

### Optimizaciones
- **Lazy Loading**: Cargar imágenes bajo demanda
- **Caching**: Cache de datos y imágenes
- **Pagination**: Paginación de listas grandes
- **Debouncing**: Evitar requests excesivos

### Métricas
- Tiempo de inicio < 3 segundos
- Transiciones fluidas 60fps
- Uso de memoria < 200MB
- Tiempo de respuesta API < 2 segundos

## 🐛 Troubleshooting

### Problemas Comunes

1. **Error de conexión API**
   - Verificar URLs en app_config.dart
   - Verificar que el backend esté corriendo
   - Revisar configuración de red

2. **Error de WebSocket**
   - Verificar que Echo Server esté corriendo
   - Revisar configuración de URLs
   - Verificar autenticación

3. **Error de imágenes**
   - Verificar URLs de imágenes
   - Revisar permisos de red
   - Usar ImageWithFallback widget

### Debug Mode
```bash
# Ejecutar en modo debug
flutter run --debug

# Ver logs detallados
flutter logs
```

## 📈 Roadmap

### Próximas Funcionalidades
- [ ] Push notifications nativas
- [ ] Pagos con tarjeta
- [ ] Mapa interactivo
- [ ] Modo offline
- [ ] Analytics
- [ ] Tests de integración

### Mejoras Técnicas
- [ ] Migración a Riverpod
- [ ] Implementar BLoC pattern
- [ ] Optimización de imágenes
- [ ] Cache inteligente
- [ ] CI/CD pipeline

---

**Versión**: 1.0.0  
**Flutter**: 3.0+  
**Dart**: 3.0+  
**Última actualización**: Julio 2024  
**Estado**: Nivel 0 Completado ✅ 