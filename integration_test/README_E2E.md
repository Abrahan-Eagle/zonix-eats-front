# Tests de Integración End-to-End (E2E)

## Descripción

Este directorio contiene tests de integración end-to-end que hacen peticiones HTTP reales entre el Frontend (Flutter) y el Backend (Laravel).

## Archivos

- `e2e_multi_role_test.dart` - Test completo de simulación entre todos los roles con peticiones HTTP reales
- `multi_role_simulation_test.dart` - Test de simulación de UI (sin peticiones HTTP)

## Requisitos

### Backend
1. El backend debe estar corriendo:
   ```bash
   cd zonix-eats-back
   php artisan serve
   ```

2. La base de datos debe tener datos de prueba o usuarios de prueba:
   - `buyer@test.com` / `password`
   - `commerce@test.com` / `password`
   - `delivery@test.com` / `password`
   - `admin@test.com` / `password`

3. El backend debe estar accesible en la URL configurada en `AppConfig.apiUrl` (por defecto: `http://192.168.27.12:8000`)

### Frontend
1. Flutter SDK instalado
2. Dependencias instaladas:
   ```bash
   flutter pub get
   ```

## Ejecutar Tests E2E

### Ejecutar todos los tests E2E:
```bash
flutter test integration_test/e2e_multi_role_test.dart
```

### Ejecutar en un dispositivo específico:
```bash
flutter test integration_test/e2e_multi_role_test.dart -d <device_id>
```

### Ver dispositivos disponibles:
```bash
flutter devices
```

## Estructura del Test E2E

El test `e2e_multi_role_test.dart` simula el siguiente flujo:

1. **FASE 1: Autenticación** - Verifica que el backend está disponible e intenta autenticarse con todos los roles
2. **FASE 2: Buyer** - Busca productos y restaurantes
3. **FASE 3: Buyer** - Crea una orden
4. **FASE 4: Commerce** - Ve dashboard y gestiona órdenes
5. **FASE 5: Commerce** - Ve analytics y reportes
6. **FASE 6: Delivery** - Ve órdenes asignadas y actualiza estados
7. **FASE 7: Admin** - Ve estadísticas del sistema
8. **FASE 8: Resumen** - Muestra el resumen del flujo completo

## Configuración

### Cambiar URL del Backend

Edita `lib/config/app_config.dart`:
```dart
static const String apiUrlLocal = 'http://TU_IP:8000';
```

### Configurar Usuarios de Prueba

Los usuarios de prueba deben existir en el backend. Puedes crearlos usando:

1. **Seeders de Laravel:**
   ```bash
   cd zonix-eats-back
   php artisan db:seed --class=TestUsersSeeder
   ```

2. **Manualmente** a través de la API o base de datos

### Tokens de Autenticación

El test intenta autenticarse automáticamente. Si la autenticación falla, el test continuará pero algunas peticiones pueden retornar 401/403.

## Salida del Test

El test imprime información detallada sobre cada petición:
- ✅ Éxito
- ⚠️ Advertencia (respuesta inesperada pero no crítica)
- ❌ Error

Ejemplo de salida:
```
🔐 FASE 1: Autenticación de Roles
✅ Backend disponible en: http://192.168.27.12:8000
🔑 Intentando autenticación...
   ✅ Buyer autenticado
   ✅ Commerce autenticado

🛒 FASE 2: Buyer - Búsqueda y Navegación
📋 GET /api/buyer/restaurants
   Status: 200
   ✅ Restaurantes encontrados: 5
```

## Troubleshooting

### Backend no disponible
- Verifica que `php artisan serve` esté corriendo
- Verifica la URL en `AppConfig.apiUrl`
- Verifica que no haya problemas de firewall

### Autenticación falla
- Verifica que los usuarios de prueba existan en la base de datos
- Verifica las credenciales en el código del test
- Algunos endpoints pueden funcionar sin autenticación

### Timeouts
- Aumenta el timeout en las peticiones HTTP si el backend es lento
- Verifica la conexión de red

## Notas

- Los tests E2E requieren que tanto el backend como el frontend estén corriendo
- Algunas peticiones pueden fallar si no hay datos en la base de datos
- El test está diseñado para ser resiliente y continuar incluso si algunas fases fallan
- Los datos de prueba creados durante el test pueden necesitar limpieza manual
