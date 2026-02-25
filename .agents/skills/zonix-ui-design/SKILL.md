---
name: zonix-ui-design
description: Sistema de diseño visual de Zonix Eats. Paleta de colores, tipografía, cards, botones, y layouts para todas las pantallas.
trigger: Cuando se diseñe o construya UI, pantallas, widgets, cards, botones, o cualquier componente visual de la app.
scope: lib/features/screens/, lib/features/widgets/, lib/core/theme/
author: Zonix Team
version: 2.0
---

# 🎨 Zonix Eats — Sistema de Diseño (Flutter)

## 1. Paleta de Colores (del logo "burger espacial")

| Token              | Hex                     | Uso                                                   |
| ------------------ | ----------------------- | ----------------------------------------------------- |
| `primary`          | `#3299FF`               | CTAs, botones primarios, iconos activos, tabs activas |
| `background-dark`  | `#1A2E46`               | Scaffold modo oscuro, navbar                          |
| `surface-dark`     | `#23262B`               | Cards en modo oscuro                                  |
| `card-cream`       | `#F9F0E0`               | Cards modo claro, fondos suaves                       |
| `accent-orange`    | `#FF9800`               | Botón principal checkout/carrito                      |
| `accent-yellow`    | `#FFC107`               | Precios, badges "Nuevo", "Oferta"                     |
| `success`          | `#43D675`               | Totales, disponible, precios destacados               |
| `danger`           | `#FF4B3E`               | Eliminar, alertas, cerrar sesión                      |
| `text-primary`     | `#FFFFFF`               | Texto sobre oscuro                                    |
| `text-secondary`   | `rgba(255,255,255,0.7)` | Subtexto modo oscuro                                  |
| `background-light` | `#F5F7F8`               | Scaffold modo claro                                   |

## 2. Tipografía y Bordes

- **Font:** Plus Jakarta Sans (Google Fonts)
- **Cards:** border-radius `16–20px`, sombra suave
- **Botones primarios:** border-radius `16px` (pill: `28px`)
- **Controles +/-:** Círculos, mínimo `36px` área táctil
- **Padding lateral:** `20–24px`
- **Max width mobile:** `360–414px`

## 3. Componentes Clave

### Card de Producto

- Imagen: `80x80px`, borderRadius `20px`, placeholder con icono `shopping_bag`
- Nombre: `18px`, semibold
- Precio: verde `#43D675`, `20px`
- Controles +/-: círculos con iconos, botón eliminar rojo

### Botón Principal (CTA)

- Ancho completo, altura `~52px`
- Naranja `#FF9800` para checkout/carrito
- Azul `#3299FF` para acciones generales
- Texto blanco, icono izquierdo

### Cards de Información

- Fondo: `#F9F0E0` (claro) o `#23262B` (oscuro)
- Bordes redondeados `16–20px`
- Sombra suave
- Padding `16–20px`

### Badges

- "Principal", "Activo" → azul `#3299FF`
- "Oferta", "Nuevo" → amarillo `#FFC107`
- Compactos, fondos sutiles

### Empty States

- Icono grande centrado
- Mensaje principal (bold)
- Mensaje secundario (color secundario)

## 4. Layouts por Pantalla

### Carrito

```
Header ("Carrito", 26px bold)
├── Estado vacío: ilustración + "El carrito está vacío"
├── Lista cards producto (imagen + info + controles +/-)
├── Resumen de orden (Total Items + Total a pagar en verde)
└── Barra fija inferior: Botón "Proceder al pago" (naranja)
```

### Checkout

```
AppBar ("Checkout" + ←)
├── Resumen compra (cards items compactas)
├── Tipo entrega: Recoger | Envío (radio/chips)
├── Dirección (si Envío): cards seleccionables con check
├── Desglose: Subtotal + Impuesto + Envío + Total (verde)
└── Botón "Confirmar compra" (naranja, loading spinner)
```

### Detalle Producto

```
AppBar (← + "Detalle" + ♡)
├── Imagen: ~40% viewport, borderRadius inferior 20px
├── Card info: nombre (22px) + precio (verde) + link restaurante (azul)
├── Descripción (2–4 líneas)
└── Barra fija: selector cantidad (- N +) + "Añadir al carrito" (azul pill)
```

### Mi Perfil / Settings

```
AppBar: "Mi Perfil" + 4 tabs pill (Persona|Publicaciones|Comercios|Más)
├── Profile header: avatar circular + nombre + email
├── Acciones: "Editar Perfil" (verde) + "Mis Pedidos" (outlined)
├── Settings card: Documentos | Direcciones | Teléfonos
├── Estadísticas: chips (Publicaciones N, Activas N)
├── Legal: Términos + Privacidad
└── Cerrar sesión (rojo outlined) + Eliminar cuenta (red text)
```

### Onboarding Carousel (4 pantallas)

```
PageView con dots indicator + Atrás/Siguiente:
0. Bienvenida: ilustración central + título + subtítulo
1. Beneficios: iconos + 2–3 beneficios cortos
2. Cómo funciona: iconos comida en círculo + descripción
3. Selección rol: 3 cards (Cliente | Restaurante | Delivery) + Continuar
```

## 5. Navegación por Rol

| Rol      | Bottom Nav                                                |
| -------- | --------------------------------------------------------- |
| Buyer    | Productos · Carrito · Mis Órdenes · Restaurantes · Config |
| Commerce | Dashboard · Órdenes · Inventario · Reportes · Config      |
| Delivery | Entregas · Historial · Rutas · Ganancias · Config         |
| Admin    | Panel · Usuarios · Seguridad · Analytics · Config         |

## 6. Estados de UI

Todas las pantallas deben manejar estos estados:

1. **Loading:** Shimmer en imagen, skeleton en cards
2. **Vacío:** Ilustración amigable + mensaje + CTA
3. **Error:** Texto rojo debajo del componente afectado
4. **Éxito:** Texto verde o SnackBar
5. **Deshabilitado:** Botón gris + texto "No disponible"

## 7. Cross-references

- **Onboarding por rol:** `zonix-onboarding` § 1 (flujos de registro)
- **Checkout layout:** `zonix-payments` § 5 (campos financieros en UI)
- **Estados de orden en UI:** `zonix-order-lifecycle` § 1
