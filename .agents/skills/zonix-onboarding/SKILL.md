---
name: zonix-onboarding
description: Flujo de registro y onboarding de Zonix Eats. Solo Buyer y Commerce van por onboarding movil. Delivery Company y Delivery Agent se registran desde paneles admin/company (modulos separados).
trigger: Cuando se trabaje con registro de usuarios, onboarding, creacion de perfiles, o proceso de activacion de Commerce.
scope: lib/features/screens/auth/, lib/features/screens/onboarding/, lib/features/services/auth/
author: Zonix Team
version: 3.0
updated: 2026-03-31
---

# Onboarding - Zonix Eats (Flutter)

## Roles del sistema (6)

| Codigo en BD       | Nombre Estandar     | Onboarding movil? | Como se registra |
| ------------------ | ------------------- | ----------------- | ---------------- |
| `users`            | **Buyer**           | SI (2 pasos)      | Google OAuth o email |
| `commerce`         | **Commerce**        | SI (4 pasos)      | Google OAuth o email + aprobacion admin |
| `delivery_company` | **Delivery Company**| NO                | Admin envia link invitacion, empresa se registra, admin aprueba |
| `delivery_agent`   | **Delivery Agent**  | NO                | Company crea agente o envia link, company aprueba |
| `delivery`         | **Delivery**        | NO (no MVP)       | Repartidor autonomo, pendiente de implementar |
| `admin`            | **Admin**           | NO                | Creado internamente |

## 1. Flujo de Onboarding Movil

### Buyer (2 pasos)

```
Google Sign-In → Carrusel (4 pags) → Seleccionar "Soy Cliente"
→ Paso 1: Datos personales + foto (obligatoria) + telefono
→ Paso 2: Direccion (mapa + GPS)
→ PUT /api/onboarding/{id} (completed_onboarding=true, role=users)
→ MainRouter (dashboard buyer)
```

### Commerce (4 pasos)

```
Google Sign-In → Carrusel → Seleccionar "Soy Comercio"
→ Paso 1: Datos personales + foto + telefono (igual que Buyer)
→ Paso 2: Direccion personal
→ Paso 3: Datos del comercio (nombre, telefono local, horario)
→ Paso 4: Direccion del establecimiento
→ PUT /api/onboarding/{id} (completed_onboarding=true, role=commerce)
→ Commerce queda con status=pending_review
→ Admin aprueba → status=approved → visible en busquedas
```

## 2. Flujos que NO van en onboarding movil

### Delivery Company (modulo dashboard admin)
- Admin envia link de invitacion a la empresa.
- La empresa se registra usando el link.
- Admin revisa datos y aprueba/rechaza/edita.
- Punto de acceso: dashboard admin (movil + web Blade).

### Delivery Agent (modulo dashboard company)
- La Delivery Company puede crear agentes directamente desde su panel.
- O puede enviar un link al repartidor para que se registre.
- La empresa revisa datos y aprueba/rechaza.
- Punto de acceso: dashboard delivery company.

## 3. API Endpoints de Onboarding

### Autenticacion (publicas, con throttle)
```
POST /api/auth/register   → { name, email, password, password_confirmation, role }
POST /api/auth/login      → { email, password }
POST /api/auth/google     → { id_token } (crea User si no existe, completed_onboarding=false)
```

### Cierre de onboarding (auth:sanctum)
```
PUT /api/onboarding/{id}  → { completed_onboarding: true, role?: "users"|"commerce" }
```
IMPORTANTE: Este endpoint SOLO acepta `completed_onboarding` (boolean, required) y `role` (opcional, in:users,commerce). NO acepta datos de perfil.

### Creacion de datos durante onboarding (auth:sanctum)
```
POST /api/profiles          → Crear perfil (firstName, lastName, photo_users, etc.)
POST /api/profiles/add-commerce → Crear comercio asociado a perfil existente
POST /api/phones            → Crear telefono (operator_code_id, number)
POST /api/addresses         → Crear direccion (street, city_id, latitude, longitude)
GET  /api/profile           → Ver perfil del usuario autenticado
PUT  /api/profile           → Actualizar perfil del usuario autenticado
```

## 4. Archivos clave (Flutter)

| Archivo | Responsabilidad |
|---------|----------------|
| `lib/features/screens/auth/sign_in_screen.dart` | Google Sign-In, bifurcacion onboarding vs MainRouter |
| `lib/features/screens/onboarding/onboarding_screen.dart` | Carrusel 4 paginas |
| `lib/features/screens/onboarding/onboarding_page3.dart` | Seleccion de rol (users / commerce) |
| `lib/features/screens/onboarding/client_onboarding_flow.dart` | Flujo completo Buyer (2 pasos) y Commerce (4 pasos, via isCommerce) |
| `lib/features/screens/onboarding/commerce_onboarding_flow.dart` | Wrapper que extiende ClientOnboardingFlow con isCommerce=true |
| `lib/features/screens/onboarding/onboarding_service.dart` | PUT /api/onboarding/{id} |
| `lib/features/screens/onboarding/onboarding_provider.dart` | Estado en memoria (paso, rol, datos, foto) |

## 5. Tablas involucradas

| Tabla | Campos de onboarding | FK |
|-------|---------------------|-----|
| `users` | `completed_onboarding` (bool), `role` (enum 6 valores) | - |
| `profiles` | `firstName`, `lastName`, `photo_users`, `date_of_birth`, `sex` | `user_id` |
| `phones` | `operator_code_id`, `number` (7 digitos), `is_primary` | `profile_id` |
| `addresses` | `street`, `house_number`, `postal_code`, `city_id`, `latitude`, `longitude`, `is_default` | `profile_id` |
| `commerces` | `business_name`, `schedule`, `status` (pending_review/approved/rejected/suspended) | `profile_id` |

Campos legacy a ignorar: `profiles.address` (usar tabla `addresses`), `profiles.phone` (accessor que lee de `phones`).

## 6. Reglas de negocio

1. Cada usuario tiene **un unico rol fijo** (no multi-rol).
2. Commerce necesita **aprobacion admin** para operar (status en tabla commerces).
3. Commerce con `pending_review` puede configurar todo (productos, horarios) pero NO aparece en busquedas de buyers.
4. Google OAuth crea User automaticamente si no existe (`completed_onboarding = false`).
5. **Foto de perfil es obligatoria** para avanzar en el onboarding (bloquea paso 1).
6. Telefono unificado en tabla `phones` (no en `profiles.phone`).
7. Profile se crea DURANTE el onboarding, no en el registro.

## 7. Cross-references

- **Estados de orden:** `zonix-order-lifecycle`
- **Patrones API:** `zonix-api-patterns` (response format)
- **Eventos FCM:** `zonix-realtime-events` (fcm_device_token)
- **Pagos post-onboarding:** `zonix-payments` (payment_methods)
- **UI patterns:** `zonix-ui-design` (colores, cards, botones)
