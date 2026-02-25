---
name: zonix-onboarding
description: Flujo de registro y onboarding de Zonix Eats por rol. Pasos de registro, creación de perfiles, documentos, y configuración inicial.
trigger: Cuando se trabaje con registro de usuarios, onboarding, creación de perfiles de comercio, delivery agents, o proceso de activación.
scope: lib/features/screens/auth/, lib/features/screens/onboarding/, lib/features/services/auth_service.dart
author: Zonix Team
version: 2.0
---

# 🚀 Onboarding - Zonix Eats (Flutter)

## Roles (Terminología Estándar)

| Nivel | Código en BD | Nombre Estándar | Alias aceptados            |
| ----- | ------------ | --------------- | -------------------------- |
| 0     | `users`      | **Buyer**       | Comprador, Cliente         |
| 1     | `commerce`   | **Commerce**    | Comercio, Restaurante      |
| 2     | `delivery`   | **Delivery**    | Delivery Agent, Repartidor |
| 3     | `admin`      | **Admin**       | Administrador              |

## 1. Flujo de Registro por Rol

### Buyer (Compradores)

```
Login/Register → Datos Básicos → Dirección → ¡Listo!
```

**Pasos:**

1. **Registro:** Email + Password, o Google OAuth (`POST /api/auth/google`)
2. **Datos básicos:** Nombre, apellido, teléfono (se actualiza Profile: `PUT /api/onboarding/{id}`)
3. **Dirección:** Calle, ciudad, estado, país, coordenadas GPS
4. **Activación automática:** El usuario puede comprar inmediatamente

### Commerce (Restaurantes/Comercios)

```
Login → Datos Personales → Crear Comercio → Documentos → Logo → Activación por Admin
```

**Pasos:**

1. **Registro:** Misma autenticación que users
2. **Perfil:** Crear perfil con rol commerce (`POST /api/profiles/commerce`)
3. **Datos del comercio:**
   - `business_name` (requerido)
   - `business_type` (requerido)
   - `tax_id` (requerido — RIF)
   - Categoría del comercio
   - Horarios de operación
4. **Documentos:** RIF, permisos sanitarios (`POST /api/documents`)
5. **Logo:** Subir logo del comercio (`POST /api/commerce/logo`)
6. **Activación:** Admin debe aprobar antes de activar

### Delivery (Repartidores)

```
Login → Datos Personales → Crear Perfil Delivery → Documentos → Vehículo → Activación por Admin
```

**Pasos:**

1. **Registro:** Misma autenticación
2. **Perfil:** Crear delivery agent (`POST /api/profiles/delivery-agent`)
3. **Datos:**
   - Nombre completo
   - Cédula de identidad
   - Teléfono
4. **Documentos:**
   - Cédula (foto frente y reverso)
   - Licencia de conducir
   - Registro del vehículo
5. **Vehículo:** `vehicle_type` (requerido), `license_number` (requerido)
6. **Activación:** Admin debe aprobar

## 2. Tablas y Campos por Rol (DB Schemas)

### Rol 0 (Comprador) — Onboarding

| Tabla         | Campos a registrar                                                | Notas                                               |
| ------------- | ----------------------------------------------------------------- | --------------------------------------------------- |
| **profiles**  | `firstName`, `lastName`, `photo_users`                            | `user_id` lo asigna backend. `status` = notverified |
| **phones**    | `operator_code_id`, `number` (7 dígitos), `is_primary = true`     | Front muestra selector de operador (0412, 0414…)    |
| **addresses** | `street`, `latitude`, `longitude`, `city_id`, `is_default = true` | Opcionales: `house_number`, `postal_code`           |

**Después:** middleName, secondLastName, date_of_birth, sex, maritalStatus, fcm_device_token, segunda dirección (entrega), payment_methods.

### Rol 1 (Commerce) — Onboarding

| Tabla         | Campos a registrar                                | Notas                                            |
| ------------- | ------------------------------------------------- | ------------------------------------------------ |
| **profiles**  | `firstName`, `lastName`, `photo_users`, `address` | Dirección del titular (texto)                    |
| **phones**    | `operator_code_id`, `number`, `is_primary = true` | Helper crea Phone al registrar comercio          |
| **commerces** | `business_name`, `business_type`, `tax_id`        | Opcional: `image`, `address`, `open`, `schedule` |

**Después:** addresses (lat/lng del local), documents (RIF/fiscal), payment_methods (para recibir dinero), completar image/schedule.

### Tabla `profiles` (esquema completo)

| Campo                      | Tipo            | Onboarding | Notas                      |
| -------------------------- | --------------- | ---------- | -------------------------- |
| `firstName`                | string          | ✅ Req     |                            |
| `lastName`                 | string          | ✅ Req     |                            |
| `photo_users`              | string nullable | ✅ Req     | Required para crear orden  |
| `middleName`               | string nullable | Después    |                            |
| `secondLastName`           | string nullable | Después    |                            |
| `date_of_birth`            | date nullable   | Después    |                            |
| `sex`                      | enum (F,M,O)    | Opcional   | default M                  |
| `maritalStatus`            | enum            | Opcional   | default single             |
| `status`                   | enum            | Backend    | notverified → completeData |
| `fcm_device_token`         | string nullable | Después    | Al usar la app             |
| `notification_preferences` | json nullable   | Después    |                            |

### Tabla `phones` (esquema completo)

| Campo              | Tipo      | Notas                                |
| ------------------ | --------- | ------------------------------------ |
| `profile_id`       | FK        | Backend lo asigna                    |
| `operator_code_id` | FK        | Ref a `operator_codes` (0412, 0414…) |
| `number`           | string(7) | Solo la parte local                  |
| `is_primary`       | boolean   | default false, onboarding = true     |
| `status`           | boolean   | default true                         |
| `approved`         | boolean   | default false, para verificación     |

### Tabla `addresses` (esquema completo)

| Campo          | Tipo          | Notas                                     |
| -------------- | ------------- | ----------------------------------------- |
| `profile_id`   | FK            | Backend lo asigna                         |
| `street`       | string        | Requerido                                 |
| `house_number` | string null   | Opcional                                  |
| `postal_code`  | string null   | Opcional                                  |
| `latitude`     | decimal(10,7) | Para geolocalización                      |
| `longitude`    | decimal(10,7) | Para geolocalización                      |
| `city_id`      | FK cities     | Requiere catálogo cities>states>countries |
| `is_default`   | boolean       | true = casa, false = entrega              |
| `status`       | enum          | notverified, completeData, etc.           |

## 3. API Endpoints de Onboarding

### Autenticación:

```
POST /api/auth/register   → { name, email, password, password_confirmation }
POST /api/auth/login      → { email, password }
POST /api/auth/google     → { id_token }
POST /api/auth/logout     → (auth:sanctum)
POST /api/auth/refresh    → Refresh token
```

### Perfil y Onboarding:

```
PUT  /api/onboarding/{id} → Actualizar datos de onboarding
GET  /api/profile         → Ver perfil actual
PUT  /api/profile         → Actualizar perfil
POST /api/profiles        → Crear perfil básico
POST /api/profiles/commerce       → Crear perfil de comercio
POST /api/profiles/delivery-agent → Crear perfil de delivery
POST /api/profiles/add-commerce   → Agregar comercio a perfil existente
```

### Teléfonos:

```
GET  /api/phones              → Listar teléfonos
GET  /api/phones/operator-codes → Códigos de operador (Venezuela)
POST /api/phones              → Agregar teléfono
PUT  /api/phones/{id}         → Actualizar
DELETE /api/phones/{id}       → Eliminar
```

### Direcciones:

```
GET    /api/addresses     → Listar direcciones
POST   /api/addresses     → Crear dirección
PUT    /api/addresses/{id} → Actualizar dirección
DELETE /api/addresses/{id} → Eliminar dirección
POST   /api/addresses/getCountries       → Obtener países
POST   /api/addresses/get-states-by-country → Estados por país
POST   /api/addresses/get-cities-by-state   → Ciudades por estado
```

### Documentos:

```
GET    /api/documents     → Listar documentos del perfil
POST   /api/documents     → Subir nuevo documento
GET    /api/documents/{id} → Ver documento
PUT    /api/documents/{id} → Actualizar documento
DELETE /api/documents/{id} → Eliminar documento
```

## 4. Teléfonos Venezuela

Operadoras soportadas (tabla `operator_codes`):

- **0412** — Digitel
- **0414** — Movistar
- **0424** — Movistar
- **0416** — Movilnet
- **0426** — Movilnet

**Patrón en Flutter:** Selector de operador (dropdown) + campo de 7 dígitos.

## 5. Reglas de Negocio del Onboarding

1. **Un usuario puede tener MÚLTIPLES roles** (ej: ser buyer Y commerce)
2. **Commerce puede tener MÚLTIPLES comercios** (multi-negocio)
3. **Solo Admin activa** perfiles Commerce y Delivery
4. **Google OAuth** crea el usuario automáticamente si no existe
5. **Tokens** se generan con Laravel Sanctum y se guardan en SecureStorage
6. **El onboarding es progresivo** — funcionalidades básicas disponibles mientras completa pasos
7. **Teléfono unificado en tabla `phones`** — ya no se usa `profiles.phone` (deprecado). Se lee vía accessor del perfil
8. **Dirección `profiles.address`** es legacy — dirección canónica es tabla `addresses`

## 6. Patrón de Service en Flutter

```dart
class AuthService {
    Future<Map<String, dynamic>> login(String email, String password) async {
        final response = await http.post(
            Uri.parse('${AppConfig.apiUrl}/auth/login'),
            body: { 'email': email, 'password': password },
        );
        await _storage.write(key: 'auth_token', value: data['token']);
        return data;
    }

    Future<Map<String, dynamic>> googleLogin() async {
        final googleUser = await GoogleSignIn().signIn();
        final googleAuth = await googleUser.authentication;
        final response = await http.post(
            Uri.parse('${AppConfig.apiUrl}/auth/google'),
            body: { 'id_token': googleAuth.idToken },
        );
        return data;
    }
}
```

## 7. Cross-references

- **Estados de orden:** `zonix-order-lifecycle` § 1-2
- **Patrones API:** `zonix-api-patterns` § 1 (response format)
- **Eventos al registrar:** `zonix-realtime-events` § 7 (fcm_device_token)
- **Pagos post-onboarding:** `zonix-payments` § 3 (payment_methods polimórfico)
