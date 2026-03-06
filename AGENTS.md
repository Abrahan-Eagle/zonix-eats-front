# AGENTS.md - Zonix Eats Frontend (Flutter App)

> Instrucciones para AI coding agents trabajando en el frontend móvil de Zonix Eats.
> Para documentación detallada, ver `README.md`.
> **Para reglas de mantenimiento y coherencia de skills, ver [MAINTENANCE_SKILLS.md](MAINTENANCE_SKILLS.md).**

## Project Overview

| Métrica                  | Valor                                    |
| ------------------------ | ---------------------------------------- |
| **Framework**            | Flutter >=3.5.0 <4.0.0                   |
| **Lenguaje**             | Dart 3.5.0+                              |
| **Versión**              | 1.0.0                                    |
| **Estado**               | ✅ MVP Completado - En desarrollo activo |
| **Archivos Dart**        | 173                                      |
| **Pantallas**            | 69                                       |
| **Servicios**            | 49                                       |
| **Tests**                | 214 pasaron ✅, 0 fallaron               |
| **Plataformas**          | Android + iOS                            |
| **Última actualización** | 4 Marzo 2026                             |

### Cambios recientes (documentar aquí los avances)

- **4 Mar 2026:** Colores centralizados en `AppColors`: eliminado hardcode en vistas de usuario y onboarding (onboarding, checkout, detalle de orden/delivery, restaurantes). Paleta alineada con logo y psicología del color (marketplace comida rápida). En vistas de usuario y onboarding usar solo `AppColors` o `Theme.of(context).colorScheme`.
- **11 Feb 2026:** Cupón: validación envía `code` y `order_amount`; mensajes de error del backend (422/404/400) mostrados al usuario. Configuración desde `.env` (AppConfig, Pusher, timeouts). Auth Pusher con `shared_secret`.

---

## Setup Commands

```bash
# Instalar dependencias
flutter pub get

# Configurar entorno
cp .env.example .env
# Editar .env con tus URLs

# Verificar instalación
flutter doctor
flutter devices

# Ejecutar app
flutter run                          # Seleccionar dispositivo
flutter run -d <device_id>           # Dispositivo específico
flutter run -d chrome                # Web (debug)

# Hot reload
r                                    # Presionar 'r' en consola
R                                    # Full restart

# Testing
flutter test                         # Todos (214 tests)
flutter test test/services/order_service_test.dart

# Análisis
flutter analyze                      # Análisis de código
flutter format lib/                  # Formatear código
flutter pub outdated                 # Dependencias desactualizadas

# Build
flutter build apk                    # APK release
flutter build apk --debug            # APK debug
flutter build appbundle              # AAB para Play Store
flutter build ios                    # Build iOS

# Limpiar
flutter clean && flutter pub get     # Reset completo
```

---

## Available Skills

| Skill                     | Descripción                                 | Ruta                                                                                               |
| ------------------------- | ------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `flutter-expert`          | Patrones Flutter, widgets, state management | [.agents/skills/flutter-expert/SKILL.md](.agents/skills/flutter-expert/SKILL.md)                   |
| `clean-architecture`      | Arquitectura limpia, capas, SOLID           | [.agents/skills/clean-architecture/SKILL.md](.agents/skills/clean-architecture/SKILL.md)           |
| `mobile-developer`        | Desarrollo móvil, UX nativa                 | [.agents/skills/mobile-developer/SKILL.md](.agents/skills/mobile-developer/SKILL.md)               |
| `ui-ux-pro-max`           | Diseño UI/UX avanzado                       | [.agents/skills/ui-ux-pro-max/SKILL.md](.agents/skills/ui-ux-pro-max/SKILL.md)                     |
| `responsive-design`       | Diseño responsivo, adaptable                | [.agents/skills/responsive-design/SKILL.md](.agents/skills/responsive-design/SKILL.md)             |
| `systematic-debugging`    | Debugging metódico                          | [.agents/skills/systematic-debugging/SKILL.md](.agents/skills/systematic-debugging/SKILL.md)       |
| `test-driven-development` | TDD workflow                                | [.agents/skills/test-driven-development/SKILL.md](.agents/skills/test-driven-development/SKILL.md) |
| `webapp-testing`          | Testing de aplicaciones                     | [.agents/skills/webapp-testing/SKILL.md](.agents/skills/webapp-testing/SKILL.md)                   |
| `code-review-playbook`    | Playbook de code review                     | [.agents/skills/code-review-playbook/SKILL.md](.agents/skills/code-review-playbook/SKILL.md)       |
| `github-code-review`      | Code review en GitHub                       | [.agents/skills/github-code-review/SKILL.md](.agents/skills/github-code-review/SKILL.md)           |
| `flutter-animations`      | Animaciones Flutter (Hero, Implicit, etc)   | [.agents/skills/flutter-animations/SKILL.md](.agents/skills/flutter-animations/SKILL.md)           |
| `git-commit`              | Conventional commits, git workflow          | [.agents/skills/git-commit/SKILL.md](.agents/skills/git-commit/SKILL.md)                           |
| `skill-creator`           | Crear nuevas skills                         | [.agents/skills/skill-creator/SKILL.md](.agents/skills/skill-creator/SKILL.md)                     |

### Custom Skills

| Skill                   | Descripción                         | Ruta                                                                                           |
| ----------------------- | ----------------------------------- | ---------------------------------------------------------------------------------------------- |
| `zonix-onboarding`      | Flujo de registro por rol, pasos    | [.agents/skills/zonix-onboarding/SKILL.md](.agents/skills/zonix-onboarding/SKILL.md)           |
| `zonix-order-lifecycle` | Estados de orden, transiciones      | [.agents/skills/zonix-order-lifecycle/SKILL.md](.agents/skills/zonix-order-lifecycle/SKILL.md) |
| `zonix-realtime-events` | Pusher, FCM, notificaciones push    | [.agents/skills/zonix-realtime-events/SKILL.md](.agents/skills/zonix-realtime-events/SKILL.md) |
| `zonix-ui-design`       | Paleta, cards, layouts, componentes | [.agents/skills/zonix-ui-design/SKILL.md](.agents/skills/zonix-ui-design/SKILL.md)             |

---

## Auto-invoke Skills

| Acción                                 | Skill                            |
| -------------------------------------- | -------------------------------- |
| Crear/modificar pantallas o widgets    | `flutter-expert`                 |
| Crear/modificar servicios              | `flutter-expert`                 |
| Diseñar UI/UX de pantallas             | `ui-ux-pro-max`                  |
| Implementar diseño responsivo          | `responsive-design`              |
| Refactorizar arquitectura              | `clean-architecture`             |
| Funcionalidades específicas de mobile  | `mobile-developer`               |
| Crear o modificar tests                | `test-driven-development`        |
| Debuggear un error                     | `systematic-debugging`           |
| Revisar código de un PR                | `code-review-playbook`           |
| Implementar animaciones o transiciones | `flutter-animations`             |
| Hacer git commit                       | `git-commit`                     |
| Implementar registro/onboarding        | `zonix-onboarding` (custom)      |
| Trabajar con estados/flujo de órdenes  | `zonix-order-lifecycle` (custom) |
| Implementar Pusher o notificaciones    | `zonix-realtime-events` (custom) |
| Diseñar/construir UI o componentes     | `zonix-ui-design` (custom)       |
| Crear nuevas skills para el proyecto   | `skill-creator`                  |

---

## Collaboration Rules

**IMPORTANTE: El usuario es el líder del proyecto.**

1. **SIEMPRE PREGUNTAR** antes de realizar cualquier acción
2. **NUNCA crear archivos nuevos** si es para editar código existente
3. **SIEMPRE sugerir detalladamente** qué hacer y esperar aprobación
4. **NUNCA hacer push/merge a git** sin orden explícita del usuario
5. **Solo hacer commits locales** cuando se realicen cambios
6. **El usuario prueba primero** y da la orden cuando está seguro
7. **Skills personalizadas (`zonix-*`)**: Los agentes pueden proponer crear o actualizar skills nuevas SOLO cuando detecten patrones repetitivos o reglas de negocio importantes que aún no estén cubiertas. Siempre deben:
   - Explicar por qué la skill es necesaria.
   - Describir brevemente el contenido propuesto.
   - Pedir tu aprobación antes de crear/editar la skill.

---

## Architecture

### Estructura del Proyecto

```
lib/
├── config/
│   └── app_config.dart              # Configuración central (URLs, timeouts)
├── features/
│   ├── screens/                     # 69 pantallas por feature
│   │   ├── auth/                    # Login, Register, Google OAuth
│   │   ├── products/                # Catálogo, búsqueda, detalles
│   │   ├── cart/                    # Carrito de compras
│   │   ├── orders/                  # Órdenes y seguimiento
│   │   ├── restaurants/             # Lista de restaurantes
│   │   ├── commerce/                # Panel de comercio
│   │   ├── delivery/                # Panel de delivery
│   │   ├── admin/                   # Panel de administrador
│   │   └── settings/                # Configuración de usuario
│   ├── services/                    # 49 servicios (API communication)
│   │   ├── auth/                    # Servicios de autenticación
│   │   ├── cart_service.dart
│   │   ├── order_service.dart
│   │   ├── commerce_service.dart
│   │   ├── pusher_service.dart      # Tiempo real (Pusher, NO WebSocket)
│   │   └── ...
│   └── DomainProfiles/              # Módulos de perfiles
│       ├── Profiles/
│       ├── Addresses/
│       ├── Documents/
│       └── Phones/
├── models/                          # Modelos de datos
├── helpers/
│   └── auth_helper.dart             # Headers + token management
├── widgets/                         # Widgets reutilizables
└── main.dart                        # Punto de entrada
```

### Patrón Arquitectónico

**Feature-based Architecture con Provider Pattern:**

```
User Interaction (Screen)
    ↓
Provider / Service (extends ChangeNotifier)
    ↓
HTTP Request (API) usando AuthHelper.getAuthHeaders()
    ↓
Backend Laravel
    ↓
HTTP Response
    ↓
Service actualiza estado
    ↓
notifyListeners()
    ↓
UI Update (Consumer<Service>)
```

---

## Code Style

### Naming Conventions

| Tipo       | Convención                   | Ejemplo              |
| ---------- | ---------------------------- | -------------------- |
| Archivos   | snake_case                   | `order_service.dart` |
| Clases     | PascalCase                   | `OrderService`       |
| Variables  | camelCase                    | `orderId`            |
| Constantes | camelCase o UPPER_SNAKE_CASE | `maxRetryAttempts`   |
| Métodos    | camelCase                    | `loadOrders()`       |

### Service Pattern

```dart
class OrderService extends ChangeNotifier {
  final String _baseUrl = AppConfig.apiUrl;

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await AuthHelper.getAuthHeaders();
      final url = Uri.parse('$_baseUrl/api/buyer/orders');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _orders = (data['data'] as List)
              .map((json) => Order.fromJson(json))
              .toList();
        }
      } else {
        _error = 'Error al cargar órdenes';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Screen Pattern

```dart
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderService>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<OrderService>(
        builder: (context, service, child) {
          if (service.isLoading) return const Center(child: CircularProgressIndicator());
          if (service.error != null) return Center(child: Text('Error: ${service.error}'));
          if (service.orders.isEmpty) return const Center(child: Text('No hay órdenes'));
          return ListView.builder(
            itemCount: service.orders.length,
            itemBuilder: (context, index) => OrderListItem(order: service.orders[index]),
          );
        },
      ),
    );
  }
}
```

### Model Pattern

```dart
class Order {
  final int id;
  final String status;
  final double total;
  final DateTime createdAt;
  final Commerce? commerce;

  Order({required this.id, required this.status, required this.total, required this.createdAt, this.commerce});

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      status: json['status'],
      total: double.parse(json['total'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      commerce: json['commerce'] != null ? Commerce.fromJson(json['commerce']) : null,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'status': status, 'total': total};

  Order copyWith({int? id, String? status, double? total}) {
    return Order(id: id ?? this.id, status: status ?? this.status, total: total ?? this.total, createdAt: createdAt);
  }
}
```

### Key Rules

1. **SIEMPRE usar `AppConfig.apiUrl`** — NUNCA URLs hardcodeadas
2. **SIEMPRE usar `AuthHelper.getAuthHeaders()`** para requests autenticados
3. **SIEMPRE `WidgetsBinding.instance.addPostFrameCallback`** para cargar datos en `initState`
4. **SIEMPRE `Consumer<Service>`** para rebuilds reactivos
5. **Pusher SOLAMENTE** para tiempo real (NO WebSocket)
6. **`flutter_secure_storage`** para tokens, `shared_preferences` para preferencias
7. **Colores:** En vistas de usuario y onboarding no usar `Colors.*` ni `Color(0x...)` hardcodeados; usar `AppColors` (`lib/features/utils/app_colors.dart`) o `Theme.of(context).colorScheme`

---

## Tech Stack

### Core

```yaml
provider: ^6.1.2 # State management
http: ^1.2.2 # HTTP client
pusher_channels_flutter: # Real-time (Pusher, NO WebSocket)
flutter_secure_storage: ^9.2.2 # Secure token storage
shared_preferences: ^2.3.2 # Local preferences
```

### Auth

```yaml
google_sign_in: ^6.2.1 # Google OAuth
flutter_web_auth_2: ^3.1.2 # Web auth flow
```

### UI/UX

```yaml
flutter_svg: ^2.0.10+1 # SVGs
google_fonts: ^6.2.1 # Typography
shimmer: ^2.0.0 # Loading effects
smooth_page_indicator: ^1.2.0+3 # Page indicators
```

### Utilities

```yaml
geolocator: ^13.0.1 # Geolocation
image_picker: ^1.1.2 # Image selection
logger: ^2.4.0 # Logging
intl: ^0.19.0 # i18n
flutter_dotenv: ^5.2.1 # Environment vars
```

---

## Authentication

```dart
class AuthHelper {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await _storage.read(key: _tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> saveToken(String token) async =>
      await _storage.write(key: _tokenKey, value: token);

  static Future<String?> getToken() async =>
      await _storage.read(key: _tokenKey);

  static Future<void> deleteToken() async =>
      await _storage.delete(key: _tokenKey);

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
```

---

## Real-time (Pusher + FCM)

### Pusher

```dart
class PusherService {
  late PusherChannelsFlutter pusher;

  Future<void> init() async {
    pusher = PusherChannelsFlutter.getInstance();
    await pusher.init(apiKey: 'YOUR_PUSHER_KEY', cluster: 'us2');
    await pusher.connect();
  }

  Future<void> subscribe(String channelName) async {
    await pusher.subscribe(channelName: channelName, onEvent: (event) { ... });
  }
}
```

### FCM (Firebase Cloud Messaging)

- Pedir permiso → Obtener token → Enviar al backend
- `onMessage` para foreground, `onMessageOpenedApp` para tap

---

## Business Rules (MVP)

### Decisiones Clave

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

### Carrito

```dart
// ✅ Solo productos de UN comercio
// Si usuario intenta agregar producto de otro comercio:
if (cart.commerceId != product.commerceId) {
  // Mostrar alerta: "¿Deseas limpiar el carrito actual?"
  // Si acepta → cartService.clearCart() + cartService.addProduct(product)
}

// Validar disponibilidad
if (!product.available) throw Exception('Producto no disponible');

// Validar stock (si existe)
if (product.stockQuantity != null && quantity > product.stockQuantity!) {
  throw Exception('Stock insuficiente');
}

// Validar cantidad: 1-100
```

### Order States

```
pending_payment → paid → processing → shipped → delivered
                → cancelled
```

Colores: `pending_payment` → orange, `processing` → blue, `shipped` → purple, `delivered` → green, `cancelled` → red

```dart
enum OrderStatus {
  pendingPayment,   // pending_payment
  processing,       // processing
  shipped,          // shipped
  delivered,        // delivered
  cancelled,        // cancelled
}
```

### Onboarding Comercio (Paso 4)

```dart
// Crear comercio:
CommerceDataService.createCommerceForExistingProfile(profileId, data)
// → POST /api/profiles/add-commerce. Devuelve data.id (commerce_id).

// schedule: Enviar siempre como string (backend valida string)
// Si es Map: schedule.isEmpty ? '' : jsonEncode(_commerceSchedule)

// Dirección del establecimiento:
AddressService.createAddress(..., role: 'commerce', commerceId: commerceId)
// sin profile_id en el body cuando hay commerceId
```

### 💰 Modelo de Negocio

**Costos y Precios:**

- **Costo Delivery:** Híbrido (Base fija + Por distancia) - Cliente paga
- **Membresía/Comisión:** Membresía mensual obligatoria (base) + Comisión % sobre ventas del mes (extra)
- **Mínimo pedido:** No hay mínimo
- **Tarifa servicio:** No hay
- **Propinas:** No permitidas

**Pagos:**

- **Métodos:** Todos (efectivo, transferencia, tarjeta, pago móvil, digitales)
- **Quién recibe:** Comercio directamente
- **Manejo:** Tiempo real
- **Pago a delivery:** Del comercio (después de recibir pago del cliente) → **Delivery recibe 100% del delivery_fee** (Opción A confirmada)

**Límites:**

- **Distancia máxima:** 60 minutos de tiempo estimado
- **Quejas/Disputas:** Sistema de tickets con admin

### Penalizaciones y Tiempos Límite

- **Cancelaciones:** Penalizaciones si exceden límites (5 cancelaciones/rechazos)
- **Tiempos límite:** 5 minutos para subir/validar comprobante (cancelación automática)
- **Rating:** Obligatorio, separado (comercio/delivery), no editable
- **Promociones:** Manual (comercio/admin), código o automático
- **Métodos de pago:** Solo UN método por orden (no mitad y mitad)
- **Delivery no encontrado:** Continúa buscando, no cancela orden

### Direcciones y Geolocalización

**USERS tiene 2 direcciones:**

1. **Predeterminada (Casa):** `is_default = true` en tabla `addresses`
   - **Uso:** Base para búsqueda de comercios por geolocalización
   - **Ubicación:** GPS + inputs y selects para mayor precisión
2. **Entrega (Pedido):** Puede ser diferente, se guarda temporalmente o como nueva dirección
   - **Ubicación:** GPS + inputs y selects para mayor precisión

**Búsqueda de Comercios por Geolocalización:**

- **Rango inicial:** 1-1.5 km desde dirección predeterminada del usuario
- **Expansión automática:** Si no hay comercios abiertos, expande automáticamente a 4-5 km
- **Expansión manual:** Usuario puede ampliar rango si desea buscar más lejos
- **Cálculo:** Haversine para calcular distancia entre coordenadas GPS

### Campos Requeridos por Rol

**USERS:** firstName, lastName, phone, photo_users (required)
**COMMERCE:** 7 campos requeridos + 16 opcionales
**DELIVERY COMPANY:** 9 campos requeridos + campos opcionales (igual estructura que COMMERCE)
**DELIVERY AGENT:** 7 campos requeridos + campos opcionales

**IMPORTANTE:** Ver backend README.md sección completa "📋 DATOS REQUERIDOS POR ACCIÓN Y ROL" para detalles específicos de cada campo.

---

## Testing

```bash
flutter test                         # Todos (214 tests)
flutter test test/services/...       # Específico
flutter analyze                      # Análisis estático
```

### Test Pattern

```dart
void main() {
  group('OrderService Tests', () {
    testWidgets('Shows loading indicator', (tester) async {
      final mockService = MockOrderService();
      when(mockService.isLoading).thenReturn(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OrderService>.value(
            value: mockService,
            child: const OrdersPage(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
```

---

## Análisis Exhaustivo

**Ubicación:** `ANALISIS_EXHAUSTIVO.md` (si existe)
**Versión de Prompts:** 2.0 - Basada en Experiencia Real

### PROMPT MAESTRO - ANÁLISIS COMPLETO v2.0

```
Realiza un ANÁLISIS COMPLETO Y EXHAUSTIVO del proyecto Zonix Eats Frontend.

INSTRUCCIONES GENERALES:
- Explora TODA la estructura del proyecto sin dejar áreas sin revisar
- Lee y analiza los archivos más importantes de cada módulo
- Identifica patrones, anti-patrones y code smells
- Proporciona ejemplos concretos de código cuando sea relevante (formato: archivo:línea)
- Prioriza hallazgos por criticidad (crítico, alto, medio, bajo)
- Sugiere mejoras específicas y accionables con estimación de esfuerzo
- **VERIFICA COHERENCIA** entre diferentes archivos de documentación (README, AGENTS.md, etc.)

METODOLOGÍA DE ANÁLISIS:

FASE 1: EXPLORACIÓN INICIAL
1. Mapear estructura completa de directorios y archivos
2. Identificar archivos de configuración clave (pubspec.yaml, .env, etc.)
3. Leer archivos de documentación principales (README.md, AGENTS.md, etc.)
4. Identificar stack tecnológico completo y versiones
5. Mapear dependencias principales y secundarias

FASE 2: ANÁLISIS PROFUNDO POR ÁREA
1. ARQUITECTURA Y ESTRUCTURA (173 archivos Dart, Feature-based + Provider)
2. CÓDIGO Y CALIDAD (convenciones Dart/Flutter, God Object en main.dart)
3. LÓGICA DE NEGOCIO (carrito, órdenes, chat, servicios MVP completados)
4. MODELOS Y ESTRUCTURA DE DATOS (fromJson/toJson, serialización)
5. SEGURIDAD (flutter_secure_storage, tokens, validación)
6. PERFORMANCE (bundle size, renderizado, caching)
7. TESTING (214 tests, estrategia, cobertura)
8. FRONTEND/UI (componentes, state management, routing, a11y)
9. INTEGRACIÓN CON BACKEND (232 endpoints, Firebase + Pusher)
10. DEVOPS E INFRAESTRUCTURA
11. DOCUMENTACIÓN
12. ESTADO Y MANTENIBILIDAD
13. OPORTUNIDADES Y MEJORAS

Para cada sección: Fortalezas (✅), Debilidades (⚠️/❌), Recomendaciones priorizadas.

FORMATO DE SALIDA:
1. RESUMEN EJECUTIVO: Estado, fortalezas top 5, mejoras top 5, score (X/10)
2. ANÁLISIS POR SECCIÓN con subsecciones numeradas
3. CHECKLIST DE VERIFICACIÓN FINAL
```

**Prompts específicos disponibles (v2.0):** Arquitectónico, Código/Calidad, Lógica de Negocio, Modelos/Datos, Seguridad, Performance, Testing, Frontend/UI, Integración Backend, DevOps, Documentación, Coherencia, Estado/Mantenibilidad, Oportunidades/Mejoras.

### Checklist de Verificación Final

- ✅ Todas las 14 secciones principales fueron analizadas
- ✅ Se verificó coherencia entre diferentes archivos de documentación
- ✅ Se identificaron y corrigieron discrepancias encontradas
- ✅ Las métricas mencionadas son consistentes en toda la documentación
- ✅ Se incluyeron métricas cuantificables cuando fue posible

**Cuándo actualizar:** Después de cambios arquitectónicos importantes, cada 3-6 meses, o antes de releases mayores.

---

## Pending Improvements

### 🟡 ALTO

- i18n/localización completa
- Optimización de imágenes y assets
- Error handling centralizado

### 🟢 MEDIO

- Widget tests para pantallas principales
- Offline mode / caching local
- Deep linking
- Analytics (Firebase Analytics)

---

**Documentación completa:** Ver `README.md`
**Backend API:** Ver `zonix-eats-back/AGENTS.md`
**Última actualización:** 4 Marzo 2026
