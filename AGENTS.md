# AGENTS.md - Zonix Eats Frontend (Flutter App)

> Instrucciones para AI coding agents trabajando en el frontend móvil de Zonix Eats.
> Para documentación detallada, ver `README.md`.
> **Para reglas de mantenimiento y coherencia de skills, ver [MAINTENANCE_SKILLS.md](MAINTENANCE_SKILLS.md).**

## Contexto de sesión

**Al iniciar o retomar trabajo:** Leer [docs/active_context.md](docs/active_context.md) si existe, para recuperar el estado de la última sesión (cambios recientes, áreas tocadas, próximos pasos). Así la IA mantiene contexto sin que el usuario tenga que pedirlo.

---

## Project Overview

| Métrica                  | Valor                                    |
| ------------------------ | ---------------------------------------- |
| **Framework**            | Flutter >=3.5.0 <4.0.0                   |
| **Lenguaje**             | Dart 3.5.0+                              |
| **Versión**              | 1.0.0                                    |
| **Estado**               | ✅ MVP Completado - En desarrollo activo |
| **Archivos Dart**        | 183                                      |
| **Pantallas**            | 79                                       |
| **Servicios**            | 32                                       |
| **Tests**                | 213 pasaron ✅, 1 omitido, 0 fallaron    |
| **Plataformas**          | Android + iOS                            |
| **Última actualización** | 11 Abril 2026                            |

### Cambios recientes (documentar aquí los avances)

- **11 Abr 2026:** PDF recibo (`ReceiptPdfBuilder`): totales al pie del área útil sin segunda hoja innecesaria — **pedidos cortos** (≤7 ítems y sin notas especiales): `pw.Spacer` + `pw.Inseparable` con resumen; **pedidos largos o con notas**: `pw.Flexible` + `pw.LimitedBox` + `pw.Stack` con resumen en `Positioned` inferior (última página de tabla). Constante `_maxItemsForSpacerSummaryFooter`. Regresión en `test/features/screens/orders/receipt_pdf_builder_test.dart`. Validación: `flutter test` (bloque recibo), `flutter analyze` en archivo tocado.
- **11 Abr 2026:** Cierre módulo **Mis pedidos (buyer) — lista de activas**: varias órdenes activas visibles a la vez, ordenadas por fecha (más reciente primero); títulos de comercio sin compartir fila con el chip de estado (evita cortes tipo “Restaur/ante”); texto **producto(s)** en español; en `pending_payment` se ocultan barra de progreso y “15 min” genéricos (no sugieren entrega antes de pagar); CTA **“Ver pedido”** vs **“Seguir pedido”** según estado; `OrderService` muestra mensaje backend para `ORDER_MAX_CONCURRENT_OPEN`. Validación: `flutter analyze` sin issues en archivos tocados.
- **7 Abr 2026:** Alineación backlog **QR buyer (escáner escaparate)**: verificado en código que el acceso principal es el `IconButton` QR en [`buyer_shell.dart`](lib/features/widgets/buyer_shell.dart) (sin `FloatingActionButton` en flujo buyer/restaurantes; otros roles conservan sus FAB propios); tests unitarios [`storefront_qr_test.dart`](test/features/utils/storefront_qr_test.dart) para `StorefrontQrParser` y `StorefrontQrPending`. Validación: `flutter test` completo **206 OK**, 1 skip.
- **7 Abr 2026:** Cierre módulo **QR comercio / storefront** — `CommerceShareQrPage`: tarjeta compartible (QR con deep link `zonix://restaurant/{id}`, logo Zonix embebido, export PNG con fondo opaco vía `RepaintBoundary`); compartir y copiar enlace HTTP usando `AppConfig.appLinkBase` (`APP_LINK_BASE_*` en `.env`); `commerce_dashboard_page` pasa la imagen del comercio al flujo QR; `RestaurantDetailsPage` resuelve `logoUrl` desde `Restaurant.image` al abrir por deep link (corrige cabecera sin imagen). Validación: `flutter analyze` sin issues; `flutter test` según entorno.
- **7 Abr 2026:** Remediación plan forense (arquitectura de arranque + a11y): extracción de `main.dart` a `lib/app/main_router.dart`, `fcm_bootstrap.dart`, `fcm_hooks.dart`, `notification_navigation.dart`; `Semantics` en CTAs críticos (login Google, órdenes, carrito/checkout: Ir a pagar, cupón, confirmar pedido). Validación: `flutter analyze` sin issues; `flutter test` **190 OK**, 1 skip.
- **2 Abr 2026:** Cierre módulo UI/tema (Bloque B) — unificación visual en paneles por rol (`lib/features/screens/admin`, `commerce`, `delivery`, `delivery_company`): colores vía `AppColors` + `Theme.colorScheme` / helpers; tokens `adminHealth*` en `app_colors.dart` para gradientes del banner de salud del dashboard admin; prompts de trabajo y verificación en `docs/PROMPT_MAESTRO_UI_COLORES_Y_TEMA.md`, `docs/PROMPT_MAESTRO_ZONIX_EATS.md`, `docs/PROMPT_VERIFICACION_SOLO_ESTETICA.md`. Sin cambios en `*_service.dart` de red. Validación: `flutter analyze` sin issues; `flutter test` 190 OK, 1 skip.
- **1 Abr 2026:** Hardening transversal final (frontend) — cierre de contratos y realtime por rol: (1) `commerce_orders_page`, `delivery_orders_page` y `delivery_company_orders_page` consumen evento canónico (`canonicalEventName` + normalización con `RealtimeEventUtils`), (2) filtro de relevancia realtime en delivery company endurecido a canal propio para eliminar refresh espurio, (3) refactor de parsing en servicios `OrderService`, `CommerceOrderService` y `AdminService` con extractores comunes de envelope/list/map y mensajes de error más consistentes para reducir drift canónico/legacy. Validación: `flutter analyze` sin issues + pruebas de servicios y pantallas críticas en verde.
- **1 Abr 2026:** Hardening global transversal (frontend) completado para cierre: (1) listeners de órdenes/chat unificados a `canonicalEventName` (fallback a `eventName`) para reducir pérdidas por variaciones de nombre de evento, (2) `NotificationService` añade deduplicación por `eventId` reciente en notificaciones realtime (además del debounce temporal), (3) normalización de URLs de media en detalle de órdenes para compatibilidad uniforme (`/storage/...`, rutas absolutas y relativas), (4) reemplazo de catches silenciosos críticos por `debugPrint` contextual en tracking/pagos/onboarding. Validación final: `flutter analyze` sin issues y `flutter test` completo en verde (190 tests, 1 skip).
- **1 Abr 2026:** Cierre módulo Tiempo Real y Notificaciones (frontend) — robustez de contrato y deduplicación: se normaliza consumo de eventos en `PusherService` con `canonicalEventName`, `eventId`, `schemaVersion`, `occurredAt`; nuevo util central `realtime_event_utils.dart` con normalización + dedupe por `event_id` (TTL/LRU) y descarte básico fuera de orden por `order_id`; `orders_page` consume evento canónico; mitigación de ruido en notificaciones foreground reforzada (`main.dart` + `NotificationService`); parser de tracking en buyer (`order_detail/current_order_detail`) soporta payload anidado/plano de `DeliveryLocationUpdated`; `delivery_orders_page` deja de esperar `OrderPendingAssignment` en canal de delivery-agent (flujo corresponde a company). Validación: `flutter test test/features/services/realtime_event_utils_test.dart` OK y `flutter analyze` sin issues.
- **1 Abr 2026:** Cierre módulo Métodos de Pago (frontend) — estado 10/10 verificable coordinado con backend: `OrderService.uploadPaymentProof` robustecido para aceptar cualquier 2xx y parsear `message/errors` del backend; `CommerceOrderService.validatePayment` exige motivo al rechazar (`is_valid=false`) y mejora parsing de errores para feedback UX consistente; compatibilidad mantenida con contrato canónico y alias legacy durante transición. Certificación final: `flutter analyze` sin issues + bloque de pruebas de servicios de órdenes/comprobante en verde.
- **1 Abr 2026:** Cierre coordinado con backend del módulo saneamiento Factories/Seeders: sin cambios funcionales de código en frontend, pero se valida compatibilidad con dataset demo actualizado (carrito con `line_id` consistente y roles delivery corregidos en fixtures de backend) para pruebas integradas buyer/commerce/delivery.
- **31 Mar 2026:** Cierre formal módulo Catálogo (frontend) — estado 10/10 técnico: parsers de servicios alineados al contrato canónico `data.items` con compatibilidad legacy, consumo de `/api/buyer/orders` adaptado a envelope estándar, validación estática sin issues y bloque de regresión smoke de catálogo/carrito en verde.
- **31 Mar 2026:** Forense catálogo (frontend) ejecutado y aplicado: (1) semántica de stock corregida (`stock_quantity = null` ahora se interpreta como stock ilimitado con `hasStockLimit`), (2) validaciones de UI en `products_page`, `product_detail_page` y `restaurant_details_page` respetan esa semántica y siguen bloqueando agotados reales, (3) `CartService` consolida ítems repetidos por producto (merge de cantidad) y mantiene regla uni-commerce, (4) detalle de restaurante deja de sobre-fetch global y consulta productos por comercio vía backend (`/buyer/search/products?commerce_id=...`), (5) categorías de productos migradas a fuente backend y búsqueda con debounce en productos/restaurante; barra de carrito en detalle filtrada al comercio actual. Certificación: bloque crítico de `flutter test` OK.
- **31 Mar 2026:** Corrección integral de bugs (frontend): (1) onboarding commerce ahora exige `house_number` en paso 4 (validator + payload limpio), (2) `AddressService` mejora parseo de errores backend por campo y elimina falso éxito por `409` con substring, (3) `client_onboarding_flow` separa operador telefónico personal vs comercio para evitar contaminación de payload, (4) login social endurecido: navegación solo si sesión backend queda autenticada (`isAuthenticated` + `userId` válido), (5) `GoogleSignInService` evita persistir token local antes de confirmar backend. Certificación: `flutter test` completo 167 OK / 1 skip.
- **31 Mar 2026:** Cierre módulo Onboarding Buyer+Commerce (frontend): (1) contrato de identidad alineado para onboarding (`createAddress`/`createDocument` usan `profileId` canónico), (2) en commerce onboarding ya no se silencian fallos críticos de CI/teléfono del comercio, evitando completar flujo con datos incompletos, (3) `OnboardingService` mejora propagación de errores HTTP/backend para feedback real. Verificación: `flutter test test/features/screens/onboarding` OK.
- **31 Mar 2026:** Diagnóstico y remediación: (1) Modelo `Order` y `CommerceOrder` — default `'pending_payment'`, getters alineados al enum canónico (backward-compatible con legacy). (2) `commerce_order_service` — filtros de estado corregidos a `processing`/`shipped`. (3) ~18 dependencias muertas eliminadas de `pubspec.yaml`. (4) Catches vacíos reemplazados con `debugPrint` en 10 servicios. (5) Métricas AGENTS.md actualizadas a conteos reales.
- **27 Mar 2026:** Cierre diagnóstico UX/rendimiento: (1) `OrderConfirmationPage` — contenido en `SingleChildScrollView` + lista con `shrinkWrap`/`NeverScrollableScrollPhysics`, `SafeArea` inferior único para CTAs (evita RenderFlex overflow en pantallas chicas/teclado). (2) `UserProvider._registerFcmToken` — si no hay `fcm_token` en almacenamiento, intenta `FirebaseMessaging.instance.getToken()` (no web) y persiste antes de registrar en API. (3) `MainRouter` — cache del `Future` de `getUserDetails()` en estado, refresco solo al cambiar rol; menos rebuilds del `FutureBuilder`. (4) `main.dart` — cuerpo del router envuelto en `AppOfflineBanner`. (5) Widgets reutilizables: `app_offline_banner.dart`, `app_skeleton.dart`, `app_empty_state.dart`. (6) Ajustes relacionados en órdenes commerce/delivery (Pusher `OrderPendingAssignment`, haptics, tabs con contadores, botones ~56px en rutas), `order_detail` / `current_order_detail`, `checkout_page`. Verificación: `flutter analyze` sin issues, `flutter test` 167 OK / 1 skip.
- **26 Mar 2026:** Limpieza completa todos los roles + flujo pickup: (1) Bugs corregidos: AdminService duplicado en admin_users_page, context.read en initState de \_AgentsList, DeliveryService() local en qr_scanner y incoming_order_dialog, ScaffoldMessenger tras pop en admin_orders/disputes, filtros de rol incompletos en admin_users. (2) Placeholders cerrados: botón "Ver todo" eliminado, eliminar comercio redirige a soporte, zonas commerce como vista solo lectura, historial notificaciones mejorado. (3) ~1100 Colors.\* reemplazados por AppColors en ~70 archivos. (4) Contraste adaptivo en restaurants_page, URL soporte en AppConfig. (5) Fix overflow en network_image_with_fallback (fallback compacto <=80px). (6) Sonido en notificaciones Pusher: showLocalNotification() como backup de FCM. (7) Flujo pickup buyer: modelo Order con isPickup/isDeliveryOrder/commerceName/commerceAddress; 4 pantallas adaptadas (OrderDetailPage, CurrentOrderDetailPage, OrderHistoryDetailPage, OrderConfirmationPage) para mostrar "Retiro en tienda" sin mapa/repartidor. Tests: 167 frontend OK, 269 backend OK, 0 issues en analyze.
- **20 Mar 2026:** Jarvis — Backlog producto/técnico documentado en `docs/active_context.md` (alineado con backend: backlog + prioridad sugerida ETA / rutas / tarifa). Sin cambios de código.
- **19 Mar 2026:** Subida a dev: commits de cierre comprobante (Commerce) y feat Pusher Streams, notificaciones, auth, mejoras Android/iOS (google-services, sonido notificación, package com.zonix.eats). Documentación actualizada en AGENTS.md y active_context.
- **19 Mar 2026:** Cierre flujo comprobante (Commerce): en detalle de orden se quitaron los enlaces "Ver comprobante" y "Ver comprobante (PDF)" (se mantiene imagen táctil y diálogo; PDF solo icono + texto). Botones Validar/Rechazar solo se muestran si la orden está en `pending_payment`; si la orden está cancelada no se muestran. Al rechazar el pago, tras éxito de la API se hace `Navigator.pop(context)` para volver al dashboard; si la API devuelve 400 (orden ya cancelada), se recarga la orden y también se hace pop. Eliminado import `url_launcher`. Archivo: `commerce_order_detail_page.dart`.
- **18 Mar 2026:** Optimización de Pusher y tiempo real: `PusherService.dart` refactorizado a `Streams` (evita pérdida de eventos por sobrescritura de callbacks). Backend corregido para evitar broadcast público redundante. Actualizadas 9 pantallas (Commerce, Orders, Chat, Dashboard) y `UserProvider` para usar suscripciones seguras (`dispose`).
- **10 Mar 2026:** PASO 7 y 8 del flujo de compra: (1) Comprador: en detalle de orden pendiente de pago puede subir comprobante (imagen) con método de pago y referencia; si ya subió, se muestra "Comprobante subido correctamente. Esperando validación del comercio." y opción "Reemplazar comprobante". (2) Comercio: en detalle de orden ve "Datos para conciliar" (método, referencia, monto), comprobante e imagen, y botones Validar/Rechazar; validación envía `rejection_reason` al backend; tras validar se muestra "Pago recibido" (método y referencia). (3) Backend: se permite "Aprobar para pago" aunque la orden ya tenga comprobante (para flujo comprador sube primero). (4) Diálogo subir comprobante: dropdown con `value` y métodos del comercio vía `getAvailablePaymentMethodsForOrder`; extensión de archivo (jpeg/png) detectada desde path.
- **9 Mar 2026:** Flujo de órdenes (Buyer) extendido: desde Carrito → `CheckoutPage` (“Finalizar pedido”) → creación de orden (`pending_payment`) con `OrderService.createOrder` → `OrderConfirmationPage` (“¡Pedido realizado!”) → `CurrentOrderDetailPage` (tracking en vivo) → `OrderHistoryDetailPage` (historial) → `OrderRatingPage` (calificar comercio y delivery). La lógica de estados sigue el backend (`pending_payment` → `paid` → `processing/preparing` → `shipped/out_for_delivery` → `delivered`).
- **9 Mar 2026:** Módulo Historial de órdenes (Buyer): cards de historial reciente/historial abren `OrderHistoryDetailPage` con layout tipo recibo (header con comercio, fecha, estado, productos, entrega y resumen de pago); botones “Volver a pedir” (reutiliza lógica de carrito) y “Descargar recibo” que llevan a `OrderDetailPage`. UI adaptada a modo claro/oscuro usando `AppColors`/Theme (sin colores hardcodeados).
- **9 Mar 2026:** Módulo Exportar datos: ProfileService.exportPersonalData() llama a `/api/profile/export`; DataExportPage genera archivo (path_provider + share_plus) y abre panel compartir para guardar/compartir; formato TXT con ciudad legible (city.name) y activity_type (login, order_placed).
- **6 Mar 2026:** Módulo Ayuda y Soporte terminado: `HelpAndFAQPage` con contenido por rol (users, commerce, delivery, delivery_company, admin), búsqueda en tiempo real sobre FAQs, temas populares (grid) que filtran, acordeón de preguntas frecuentes con "Ver todas" (scroll automático a la sección), bloque "¿Aún necesitas ayuda?" con Chat en vivo y Enviar correo. Al cambiar el texto de búsqueda se resetea "Ver todas". Documentación en cabecera del archivo. Cierre de módulo: library directives (`help_and_faq_page`, `bottom_nav_persistence`), prefer_const_constructors, actualización AGENTS.md, README.md y docs/active_context.md.
- **6 Mar 2026:** Bottom nav: persistencia por rol (clave `bottomNavIndex_$role`), sin doble "Saved 0" al cargar rol; nivel por defecto y niveles permitidos por rol (level 0 = users, 1 = commerce, etc.). Lógica extraída a `lib/features/utils/bottom_nav_persistence.dart` (bottomNavStorageKey, defaultLevelForRole, levelsForRole). Tests en `test/features/utils/bottom_nav_persistence_test.dart` (21 tests: claves, niveles, SharedPreferences).
- **6 Mar 2026:** Onboarding: dropdown código de operador (paso 1 y paso 3 comercio) con fallback si no hay carga, hint "Código", y formato de visualización (0412, no 00412) vía `_formatOperatorCodeDisplay` en `client_onboarding_flow.dart`.
- **6 Mar 2026:** Módulo Documentos: DocumentService usa AuthHelper (getAuthHeaders/getToken) para evitar 401 tras escáner; pantalla editar RIF muestra y permite editar Domicilio fiscal (controller + TextFormField); modelo Document acepta `tax_domicile` del backend como fallback.
- **6 Mar 2026:** Módulo Documents: solo CI y RIF; formato al escribir (CI: V-12.345.678, RIF: J-19217553-0) con `document_input_formatters.dart`; formato al mostrar con `rif_formatter.dart` y `formattedRifNumber`; estado Verificado/Pendiente en lista y detalle (`approved`). Requisito de documento para método de pago pago móvil (comercio). Tests: rif_formatter y Document model.
- **6 Mar 2026:** Documentado en AGENTS.md: Profile como entidad principal; uso de getMyProfile() y fetchMyPhones/fetchMyDocuments cuando el API es por usuario autenticado.
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
flutter test                         # Todos (~167 tests + skips según entorno)
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

## Modelo de datos: Profile como entidad principal

- En el backend, **Profile** es la entidad principal: teléfonos, documentos y direcciones pertenecen al perfil (`profile_id`). **Users** es 1:1 con Profile (cuenta de login).
- En la app: al cargar “mis” datos (teléfonos, documentos), usar `ProfileService().getMyProfile()` y luego `profile.id` cuando el API espere `profile_id`, o `profile.userId` cuando el API use `user_id` por compatibilidad. Servicios como `fetchMyPhones()` / `fetchMyDocuments()` ya resuelven al usuario autenticado sin pasar id.

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

| Skill                   | Descripción                           | Ruta                                                                                           |
| ----------------------- | ------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `zonix-onboarding`      | Flujo de registro por rol, pasos      | [.agents/skills/zonix-onboarding/SKILL.md](.agents/skills/zonix-onboarding/SKILL.md)           |
| `zonix-order-lifecycle` | Estados de orden, transiciones        | [.agents/skills/zonix-order-lifecycle/SKILL.md](.agents/skills/zonix-order-lifecycle/SKILL.md) |
| `zonix-realtime-events` | Pusher, FCM, notificaciones push      | [.agents/skills/zonix-realtime-events/SKILL.md](.agents/skills/zonix-realtime-events/SKILL.md) |
| `zonix-ui-design`       | Paleta, cards, layouts, componentes   | [.agents/skills/zonix-ui-design/SKILL.md](.agents/skills/zonix-ui-design/SKILL.md)             |
| `context-updater`       | Resumir sesión en docs/active_context | [.agents/skills/context-updater/SKILL.md](.agents/skills/context-updater/SKILL.md)             |
| `documentar-avances`    | Proponer texto para Cambios recientes | [.agents/skills/documentar-avances/SKILL.md](.agents/skills/documentar-avances/SKILL.md)       |

---

## Auto-invoke Skills

| Acción                                 | Skill                                                 |
| -------------------------------------- | ----------------------------------------------------- |
| Crear/modificar pantallas o widgets    | `flutter-expert`                                      |
| Crear/modificar servicios              | `flutter-expert`                                      |
| Diseñar UI/UX de pantallas             | `ui-ux-pro-max`                                       |
| Implementar diseño responsivo          | `responsive-design`                                   |
| Refactorizar arquitectura              | `clean-architecture`                                  |
| Funcionalidades específicas de mobile  | `mobile-developer`                                    |
| Crear o modificar tests                | `test-driven-development`                             |
| Debuggear un error                     | `systematic-debugging`                                |
| Revisar código de un PR                | `code-review-playbook`                                |
| Implementar animaciones o transiciones | `flutter-animations`                                  |
| Hacer git commit                       | `git-commit`                                          |
| Implementar registro/onboarding        | `zonix-onboarding` (custom)                           |
| Trabajar con estados/flujo de órdenes  | `zonix-order-lifecycle` (custom)                      |
| Implementar Pusher o notificaciones    | `zonix-realtime-events` (custom)                      |
| Diseñar/construir UI o componentes     | `zonix-ui-design` (custom)                            |
| Crear nuevas skills para el proyecto   | `skill-creator`                                       |
| Cerrar sesión con cambios relevantes   | `context-updater` (actualizar docs/active_context.md) |
| Finalizar tarea y documentar avances   | `documentar-avances` (proponer Cambios recientes)     |

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
flutter test                         # Todos (~167 tests + skips según entorno)
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
7. TESTING (250 tests, estrategia, cobertura)
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
**Última actualización:** 31 Marzo 2026
