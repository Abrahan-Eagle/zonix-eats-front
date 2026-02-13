# Prompt para Stitch - Diseño completo Zonix Eats

**Copia este texto y úsalo en [Stitch (withgoogle.com)](https://stitch.withgoogle.com) para que la IA genere diseños de todas las vistas y formularios de la app.**

---

## CONTEXTO DE LA APP

**Zonix Eats** es una aplicación móvil de delivery de comida (similar a Rappi, Uber Eats) con 4 roles de usuario. Es un MVP en Flutter con backend Laravel. La identidad visual proviene del logo (hamburguesa como planeta Saturno, "burger espacial"), con paleta extraída del mismo. Diseño moderno, limpio, mobile-first, con estilo similar a CorralX (tabs, cards, estructura clara). Idioma: español.

---

## PALETA DE COLORES (extraída del logo `assets/images/logo_login.png`)

El logo representa una hamburguesa estilizada como planeta Saturno: cuerpo crema/azul oscuro, anillo azul brillante con sección naranja-amarillo, líneas de velocidad azules y acento rojo.

- **Azul oscuro principal:** `#1A2E46` — fondos modo oscuro, texto primario, elementos de marca
- **Azul brillante (acento):** `#3299FF` — botones primarios, enlaces, iconos activos, CTAs
- **Naranja-amarillo vibrante:** `#FFC107` — precios, ofertas, badges "Nuevo", highlights
- **Crema / blanco roto:** `#F9F0E0` — fondos modo claro, cards, texto secundario
- **Rojo de acento:** `#FF0000` — alertas, errores, "En Vivo", cerrar sesión, urgente
- **Negro:** `#000000` — fondos oscuros, contraste

---

## ROLES Y FLUJOS

### Rol 0 - Comprador (users)
- Navegación bottom: Productos, Carrito, Mis Órdenes, Restaurantes, Configuración
- Flujo: explorar → agregar al carrito → checkout → pagar → seguir orden

### Rol 1 - Comercio (commerce)
- Navegación bottom: Dashboard, Órdenes, Inventario/Productos, Reportes, Configuración
- Flujo: gestionar pedidos, productos, horarios, reportes

### Rol 2 - Delivery (delivery)
- Navegación bottom: Entregas, Historial, Rutas, Ganancias, Configuración

### Rol 3 - Admin (admin)
- Navegación: Panel Admin, Usuarios, Seguridad, Analytics, Configuración

---

## PANTALLAS A DISEÑAR (todas las vistas)

### 1. AUTENTICACIÓN
- **Login / Sign In:** email, contraseña, botón "Iniciar sesión", link "¿Olvidaste contraseña?", botón "Google Sign-In"
- **Onboarding** (varias pantallas): bienvenida, permisos, selección de rol

### 2. COMPRADOR (users)
- **Productos (Home):** grid de productos, búsqueda, filtros, cards con imagen, nombre, precio
- **Detalle producto:** imagen grande, nombre, descripción, precio, botón "Agregar al carrito", selector cantidad
- **Carrito:** lista de ítems (imagen, nombre, precio, cantidad), subtotal, botón "Ir a pagar"
- **Checkout:** resumen orden, dirección de entrega, método de pago, total, botón "Confirmar pedido"
- **Mis Órdenes:** lista de órdenes con estado (pending_payment, paid, processing, shipped, delivered, cancelled), tap para ver detalle
- **Detalle orden:** productos, total, estado, botón subir comprobante (si pending_payment)
- **Restaurantes:** lista de comercios cercanos, mapa o listado, card con nombre, rating, dirección
- **Detalle restaurante:** info del comercio, menú/productos
- **Favoritos:** lista de posts/productos favoritos

### 3. MI PERFIL / CONFIGURACIÓN (Settings)
- **Mi Perfil** con 4 tabs en AppBar (iconos): Persona, Publicaciones, Comercios, Más
  - **Tab Persona:** card con foto, nombre, email; botón azul "Editar Perfil"; botón outlined "Mis Pedidos"; sección Legal (Términos, Privacidad); Estadísticas (Publicaciones, Activas en chips); Cerrar sesión (rojo); Eliminar cuenta
  - **Tab Publicaciones:** vacío "No tienes publicaciones aún" con icono + "Crea tu primera publicación para empezar"
  - **Tab Comercios:** botón azul "Agregar Restaurante"; cards de restaurantes con: icono en contenedor azul claro, nombre, RIF, dirección, badge "Principal", stats (Rating, Ventas, Productos), acciones Ver | Editar | Eliminar
  - **Tab Más:** Historial actividad, Exportar datos, Privacidad; (si commerce) Datos comercio, Métodos pago, Horario, Estado abierto/cerrado, Promociones, Zonas delivery, Notificaciones; Notificaciones, Ayuda, Acerca de
- **Editar Perfil:** formulario firstName, lastName, phone, foto, direcciones
- **Documentos, Direcciones, Teléfonos:** listas con opción agregar/editar
- **Datos del comercio:** formulario business_name, business_type, tax_id, address, phone, image, open, schedule

### 4. COMERCIO (commerce)
- **Dashboard:** cards con métricas (órdenes pendientes, ventas hoy, productos activos), lista de órdenes recientes
- **Órdenes:** tabs o filtros por estado, lista de órdenes, tap para detalle
- **Detalle orden comercio:** productos, cliente, dirección, total, botones Validar pago / Cambiar estado
- **Productos/Inventario:** lista de productos con imagen, nombre, precio, disponible (toggle), botón "Agregar producto"
- **Formulario producto:** nombre, descripción, precio, imagen, disponible, stock
- **Reportes:** gráficos, métricas de ventas
- **Mis Restaurantes (CommerceListPage):** ver lista completa arriba (tab Comercios)
- **Detalle restaurante:** datos, ubicación, stats, productos
- **Formulario agregar restaurante:** business_name, business_type, tax_id, address, horario, open
- **Promociones:** lista, formulario crear promo
- **Zonas de delivery:** mapa o lista de zonas
- **Métodos de pago:** lista de métodos (pago móvil, transferencia, efectivo)
- **Chat:** lista de conversaciones por orden
- **Mensajes chat:** burbujas, input envío

### 5. DELIVERY (delivery)
- **Entregas disponibles:** lista de órdenes para aceptar
- **Mis entregas:** órdenes asignadas con mapa/ruta
- **Historial:** entregas completadas
- **Rutas:** mapa con rutas
- **Ganancias:** resumen de ganancias

### 6. ADMIN (admin)
- **Dashboard admin:** métricas globales, usuarios, órdenes, comercios
- **Usuarios:** lista, buscar, detalle
- **Seguridad:** configuración
- **Analytics:** gráficos, reportes

### 7. COMUNES
- **Notificaciones:** lista de notificaciones
- **Ayuda y FAQ:** preguntas frecuentes
- **Acerca de:** versión, autor
- **Eliminar cuenta:** confirmación
- **Exportar datos:** opciones de export

---

## FORMULARIOS CLAVE (campos)

| Formulario | Campos |
|------------|--------|
| Login | email, contraseña |
| Registro/Onboarding cliente | firstName, lastName, phone, dirección (street, house_number, postal_code, city, country), foto |
| Onboarding comercio | business_name, business_type, tax_id, address, schedule, owner_ci |
| Onboarding delivery | según tipo (company o agent): datos empresa o vehicle_type, license_number |
| Editar perfil | firstName, lastName, phone, photo |
| Crear producto | name, description, price, image, available, stock_quantity |
| Crear restaurante | business_name, business_type, tax_id, address, horario, open |
| Dirección | street, house_number, postal_code, latitude, longitude, city_id |
| Crear promoción | código, descuento, vigencia |

---

## ESTILO VISUAL (coherente con el logo "burger espacial")

- **Cards:** bordes redondeados (12–16px), sombra sutil, fondo crema `#F9F0E0` en modo claro
- **Botones primarios:** azul brillante `#3299FF`, relleno, bordes redondeados
- **Botones secundarios:** outlined, borde azul brillante
- **Botones destructivos:** outlined rojo `#FF0000`
- **Iconos:** estilo geométrico amigable, contenedores con fondo azul claro para destacar
- **Badges:** "Principal", "Activo" en azul brillante; "Oferta", "Nuevo" en naranja-amarillo `#FFC107`
- **Estadísticas:** chips/cards con icono, número grande, label
- **Empty states:** icono grande centrado, mensaje principal, mensaje secundario
- **Tabs en AppBar:** iconos (persona, article/publicaciones, store/comercios, more); tab activa en azul brillante

---

## INSTRUCCIONES PARA STITCH

Diseña todas las vistas y formularios listados para la app Zonix Eats. **La paleta de colores proviene del logo** (`assets/images/logo_login.png`): azul oscuro, azul brillante para CTAs, naranja-amarillo para precios/ofertas, crema para fondos claros, rojo para alertas. El diseño debe ser mobile-first (vertical, ~360–414px ancho). Mantén consistencia: mismo estilo de cards, botones y espaciado en toda la app. La estética debe ser coherente con el logo "burger espacial". Genera mockups/wireframes para cada pantalla principal y formularios clave. Prioriza: Login, Home comprador, Carrito, Checkout, Mi Perfil (tabs), Dashboard comercio, Mis Restaurantes (cards estilo CorralX), formularios de producto y restaurante.
