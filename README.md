# Zonix Eats Frontend (Flutter)

Aplicación móvil de Zonix Eats desarrollada en Flutter. Permite a clientes, comercios y repartidores interactuar con la plataforma de pedidos y entregas en tiempo real.

---

## 📦 Estructura del proyecto

```
lib/
  core/           # Utilidades, helpers, temas, constantes globales
  models/         # Modelos de datos (Product, User, etc.)
  features/       # Features principales agrupadas por dominio
    products/
      screens/
      services/
      widgets/
    cart/
    auth/
    profile/
    ...           # Otras features (delivery, orders, etc.)
  helpers/        # Funciones utilitarias generales
  main.dart
assets/           # Imágenes, fuentes, íconos
 test/            # Tests unitarios y de widgets (refleja la estructura de lib/)
```

---

## 🚀 Cómo correr la app

1. Instala dependencias:
   ```bash
   flutter pub get
   ```
2. Corre la app en modo desarrollo:
   ```bash
   flutter run
   ```
3. Compila para producción:
   ```bash
   flutter build apk --release
   ```

---

## 🧪 Testing y Mocks

### Ejecutar Tests
```bash
flutter test
```

### Estrategia de Testing
Los tests están diseñados para ser **estables, rápidos y confiables** sin depender de servicios externos:

#### Mocks Implementados
- **Servicios HTTP**: Usamos `MockClient` para simular respuestas de API
- **Almacenamiento Seguro**: Mockeamos `flutter_secure_storage` para tests
- **Plugins Externos**: Simulamos GoogleSignIn y otros plugins cuando es necesario

#### Ejemplos de Mocks

**OrderService Mock:**
```dart
class MockOrderService extends OrderService {
  @override
  Future<List<Order>> fetchOrders() async {
    return [Order(id: 1, estado: 'pendiente', total: 100, items: [])];
  }
}
```

**UserProvider Mock:**
```dart
class UserProviderMock extends UserProvider {
  @override
  Future<Map<String, dynamic>> getUserDetails() async {
    return {
      'users': {'id': 1, 'role': 'users'},
      'role': 'users',
      'userId': 1,
    };
  }
}
```

#### Configuración de Tests
```dart
setUp(() {
  // Mock secure storage
  const MethodChannel channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (MethodCall methodCall) async {
      if (methodCall.method == 'read') {
        return 'mock_token';
      }
      return null;
    },
  );
});
```

### Convenciones de Testing
- **Tests Unitarios**: Para lógica de negocio y servicios
- **Tests de Widgets**: Para componentes UI simples
- **Mocks**: Para servicios externos (HTTP, storage, plugins)
- **Nombres**: Descriptivos en español (ej: "Puede crear orden con items")

---

## 📝 Convenciones y buenas prácticas
- Agrupa el código por dominio/feature.
- Usa nombres claros y descriptivos para archivos y carpetas.
- Mantén los tests junto a la lógica que prueban.
- Usa mocks para servicios externos en los tests.
- Documenta cualquier convención especial aquí.

---

## 📄 Contacto y soporte
Para dudas o soporte, contacta a tu equipo de desarrollo o abre un issue en el repositorio.
