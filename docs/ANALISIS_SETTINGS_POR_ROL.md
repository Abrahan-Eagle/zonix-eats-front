# Análisis: Settings por rol y necesidad de la app

**Fecha:** Febrero 2025  
**Alcance:** Pantalla Configuración (`SettingsPage2`) y opciones relacionadas.  
**Objetivo:** Definir qué debe existir, qué no, por rol y por qué la app lo necesita (MVP Zonix Eats).

---

## 1. Estado actual

### 1.1 Acceso a Settings
- **Todos los roles** (users, commerce, delivery_agent, delivery_company, admin) tienen el **mismo último ítem** en el bottom nav: **Configuración**.
- Al pulsar se abre **siempre** `SettingsPage2` (misma pantalla para todos).

### 1.2 Estructura actual de SettingsPage2

| Elemento | users | commerce | delivery | admin |
|----------|-------|----------|----------|-------|
| **Tabs** | Persona, Más | Persona, Publicaciones, Comercios, Más | Persona, Más | Persona, Más |
| **Persona** | | | | |
| → Editar perfil / Foto | ✅ | ✅ | ✅ | ✅ |
| → Mis pedidos | ✅ (OrdersPage) | ✅ (CommerceOrdersPage) | ✅ (OrdersPage) | ✅ (OrdersPage) |
| → Documentos | ❌ | ✅ | ✅ | ✅ |
| → Direcciones | ✅ | ✅ | ✅ | ✅ |
| → Teléfonos | ✅ | ✅ | ✅ | ✅ |
| → Estadísticas (publicaciones) | ❌ | ✅ | ❌ | ❌ |
| → Legal (Términos, Privacidad) | ✅ | ✅ | ✅ | ✅ |
| → Cerrar sesión | ✅ | ✅ | ✅ | ✅ |
| → Eliminar cuenta (link) | ✅ → PrivacySettingsPage | ✅ | ✅ | ✅ |
| **Publicaciones** (tab) | ❌ | ✅ | ❌ | ❌ |
| **Comercios** (tab) | ❌ | ✅ (CommerceListPage) | ❌ | ❌ |
| **Más** | | | | |
| → Historial de actividad | ✅ | ✅ | ✅ | ✅ |
| → Exportar datos | ✅ | ✅ | ✅ | ✅ |
| → Privacidad | ✅ | ✅ | ✅ | ✅ |
| → Config. negocio (Datos, Pagos, Horarios) | ❌ | ✅ | ❌ | ❌ |
| → Promociones y ventas (Promo, Cupones) | ❌ | ✅ | ❌ | ❌ |
| → Más opciones (Abierto/cerrado, Zonas, Pago móvil, Notif.) | ❌ | ✅ | ❌ | ❌ |
| → Soporte (Ayuda, Notificaciones, Acerca de) | ✅ | ✅ | ✅ | ✅ |

### 1.3 Problemas detectados (y estado)
- **Delivery** y **admin** no tienen ninguna opción específica de su rol en Settings (solo ven “Persona + Más” como un user). *Pendiente opcional: control “Disponibilidad” (working) cuando el backend lo exponga.*
- ~~**“Acerca de”** en Soporte abría `MyApp()` en lugar de pantalla Acerca de.~~ **Corregido:** abre `AboutScreen` (en `about_page.dart`).
- ~~**Eliminar cuenta:** dos flujos.~~ **Unificado:** el link en Persona lleva a `PrivacySettingsPage`, donde está el flujo único (deleteAccount → logout → login).
- ~~**Documentos:** se mostraban para todos.~~ **Ajustado:** ocultos para rol `users`; visibles para commerce, delivery y admin.

---

## 2. Qué debe existir por rol (y por qué)

### 2.1 users (comprador)

| Opción | ¿Debe existir? | Motivo |
|--------|----------------|--------|
| Editar perfil / Foto | **Sí** | Requerido para pedidos: firstName, lastName, phone, photo_users. |
| Mis pedidos | **Sí** | Flujo core: ver y seguir órdenes. |
| Direcciones | **Sí** | Necesarias: dirección casa (default) y entrega; búsqueda de comercios por geolocalización. |
| Teléfonos | **Sí** | Dato mínimo por rol. |
| Documentos | **Opcional** | No obligatorio para comprador en MVP; se puede mantener para consistencia o ocultar. |
| Términos / Privacidad | **Sí** | Legal y transparencia. |
| Cerrar sesión | **Sí** | Básico. |
| Eliminar cuenta | **Sí** | Derecho a supresión (GDPR / buena práctica). |
| Historial de actividad | **Opcional** | No crítico para MVP; puede quedarse. |
| Exportar datos | **Sí** | Derecho a portabilidad (GDPR). |
| Privacidad (política/preferencias) | **Sí** | Legal y control del usuario. |
| Ayuda / Notificaciones / Acerca de | **Sí** | Soporte y info de la app. |

**Resumen users:** Todo lo actual en Persona y Más tiene sentido, salvo valorar si “Documentos” e “Historial de actividad” se muestran u ocultan en MVP.

---

### 2.2 commerce (tienda/restaurante)

| Opción | ¿Debe existir? | Motivo |
|--------|----------------|--------|
| Todo lo de **users** | **Sí** | Un comercio es un usuario con rol commerce; necesita perfil, direcciones, teléfonos, etc. |
| Tab **Publicaciones** | **Sí** | Contenido del comercio (posts); alineado con negocio. |
| Tab **Comercios** | **Sí** | Lista de sus comercios; necesario si puede tener más de uno. |
| Estadísticas (publicaciones) | **Sí** | Métricas básicas de publicaciones. |
| Datos del comercio | **Sí** | Información básica, contacto, horarios (schedule), open. |
| Horarios | **Sí** | Apertura/cierre; backend lo usa (schedule como string). |
| Estado abierto/cerrado | **Sí** | Campo `open`; afecta visibilidad y pedidos. |
| Métodos de pago / Datos de pago móvil | **Sí** | Quién recibe el pago; crítico para cobros. |
| Zonas de delivery | **Sí** | Dónde entrega; necesario para lógica de envío. |
| Notificaciones del comercio | **Sí** | Alertas de pedidos, etc. |
| Promociones / Cupones | **Sí** | MVP permite promociones manuales. |

**Resumen commerce:** Lo que hay hoy para commerce en Settings es coherente con el MVP. Revisar si “Datos de pago móvil” y “Métodos de pago” están bien separados en backend para no duplicar concepto.

---

### 2.3 delivery (repartidor: agent o company)

| Opción | ¿Debe existir? | Motivo |
|--------|----------------|--------|
| Todo lo de **users** (perfil, direcciones, teléfonos, legal, cuenta, más) | **Sí** | Mismo perfil base; delivery tiene datos adicionales pero comparte persona. |
| Documentos | **Sí** | Backend: verificación de repartidor (licencia, etc.). |
| **No** tabs de Publicaciones ni Comercios | **Correcto** | No aplican. |
| **Falta:** algo tipo “Disponibilidad” (working on/off) | **Recomendado** | Backend usa `working` para asignación de entregas. Hoy no está en Settings; podría estar en Dashboard delivery o aquí. |
| **Falta:** datos específicos delivery (vehículo, licencia si aplica) | **Opcional** | Si el perfil delivery se edita en otra pantalla (onboarding/dashboard), no es obligatorio duplicar en Settings. |

**Resumen delivery:** Lo actual (Persona + Más, sin bloques commerce) es correcto. Mejora: exponer “Disponibilidad” (working) desde Settings o desde el dashboard de delivery para que el repartidor pueda activar/desactivar sin confusión.

---

### 2.4 admin

| Opción | ¿Debe existir? | Motivo |
|--------|----------------|--------|
| Todo lo de **users** (perfil, direcciones, teléfonos, legal, cuenta, más) | **Sí** | Admin es un usuario; debe poder editar su perfil y usar opciones de cuenta. |
| **No** tabs de Publicaciones ni Comercios | **Correcto** | No aplican. |
| Eliminar cuenta / Cerrar sesión | **Criterio de producto** | Habitualmente se restringe o se añade doble verificación para admin; si el producto lo permite, puede quedarse. |
| Configuración de sistema/seguridad | **No en esta pantalla** | Ya existe en Admin Dashboard (Seguridad, Usuarios, Sistema). Settings = cuenta personal. |

**Resumen admin:** Settings como “cuenta personal” (Persona + Más) está bien. No mezclar aquí opciones de panel de administración.

---

## 3. Qué NO debe existir (o unificar)

| Situación | Acción recomendada |
|-----------|---------------------|
| “Acerca de” abre `MyApp()` | Corregir a `AboutPage()`. |
| Dos flujos de eliminar cuenta (AccountDeletionPage vs PrivacySettingsPage → deleteAccount) | Unificar: o todo por `PrivacySettingsPage` (delete directo + logout + navegación) o un solo “Eliminar cuenta” que use un único flujo (p. ej. pantalla dedicada que llame al mismo endpoint y luego logout). |
| Documentos para comprador | Mantener visible si el backend lo soporta para todos; si solo tiene sentido para commerce/delivery, ocultar para `users` en Settings. |
| Switch “Notificaciones” en Más (siempre true, onChanged vacío) | Conectar con preferencias reales o quitar hasta tener backend/estado real. |

---

## 4. Resumen por rol (checklist)

| Rol | Persona (perfil, pedidos, docs, direcciones, teléfonos, legal, cerrar sesión, eliminar cuenta) | Tabs extra | Sección “Más” (actividad, exportar, privacidad, soporte) | Secciones commerce (negocio, promos, más opciones) |
|-----|------------------------------------------------------------------------------------------------|------------|-----------------------------------------------------------------|-----------------------------------------------------|
| **users** | ✅ Todo | ❌ | ✅ Todo | ❌ |
| **commerce** | ✅ Todo + Estadísticas | ✅ Publicaciones, Comercios | ✅ Todo | ✅ Todo |
| **delivery** | ✅ Todo (documentos sí) | ❌ | ✅ Todo | ❌ |
| **admin** | ✅ Todo | ❌ | ✅ Todo | ❌ |

**Faltante opcional:** para **delivery**, una forma de cambiar “Disponibilidad” (working) si no está ya en su dashboard.

---

## 5. Archivos implicados

- `lib/features/screens/settings/settings_page_2.dart` – Pantalla principal; condicional `isCommerce`; Documentos por rol; “Acerca de” → `AboutScreen`; eliminar cuenta → `PrivacySettingsPage`; Notificaciones deshabilitado + “Próximamente”.
- `lib/features/screens/about/about_page.dart` – Pantalla “Acerca de” (clase `AboutScreen`).
- `lib/features/DomainProfiles/Profiles/screens/privacy_settings_page.dart` – Eliminar cuenta (flujo único: deleteAccount → logout → login).
- `lib/features/screens/account_deletion_page.dart` – Ya no se usa desde Settings; se puede mantener para otras rutas o deprecar.
- `lib/main.dart` – Último ítem del bottom nav “Configuración” para todos los niveles.

---

## 6. Próximos pasos sugeridos

1. ~~**Corregir bug:** “Acerca de” → `AboutPage()`.~~ **Hecho:** “Acerca de” abre `AboutScreen` (renombrado en `about_page.dart`; antes era `MyApp`).
2. ~~**Unificar eliminación de cuenta:** Un solo punto de entrada y un solo flujo.~~ **Hecho:** El enlace “Eliminar cuenta permanentemente” en Settings lleva a `PrivacySettingsPage`, donde está el flujo único (deleteAccount → logout → ir a login). Se eliminó la navegación a `AccountDeletionPage` desde Settings.
3. ~~**Opcional por rol:** Ocultar “Documentos” para `users`.~~ **Hecho:** En Persona, el tile “Documentos” solo se muestra si `userRole != 'users'` (commerce, delivery, admin lo ven).
4. **Delivery – Disponibilidad (working):** Pendiente. El backend tiene el campo `working` en `delivery_agents`; cuando exista endpoint para actualizarlo (ej. `PATCH /api/delivery/working`), añadir en Settings o en dashboard delivery un control para activar/desactivar disponibilidad.
5. ~~**Notificaciones en Más:** Dejarlo deshabilitado/informativo hasta tener backend.~~ **Hecho:** Switch deshabilitado (`onChanged: null`), subtítulo “Próximamente” y valor fijo `true`.
