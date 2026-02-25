# Zonix Eats – Ciclo de compra y vistas por nivel

Documento de análisis del flujo completo de una compra, desde el inicio hasta la entrega, indicando qué ve y hace cada rol en cada paso.

---

## 1. Resumen de los 4 niveles (roles)

| Nivel | Rol | Pantallas principales | Participación en compra |
|-------|-----|------------------------|-------------------------|
| **0** | Comprador (users) | Productos, Carrito, Órdenes, Restaurantes | Crea orden, paga, recibe, califica |
| **1** | Comercio (commerce) | Dashboard, Órdenes, Productos, Reportes | Valida pago, prepara, envía |
| **2/3** | Delivery (rider/company) | Entregas, Historial, Rutas, Ganancias | Acepta, recoge, entrega |
| **4** | Admin | Panel Admin, Usuarios, Seguridad, Analytics | Supervisión, disputas |

---

## 2. Diagrama general – Flujo de una compra (inicio a fin)

```mermaid
flowchart TB
    subgraph NIVEL_0["🛒 NIVEL 0: COMPRADOR"]
        A1[ProductsPage / RestaurantsPage]
        A2[ProductDetailPage / RestaurantDetailsPage]
        A3[CartPage]
        A4[CheckoutPage]
        A5[OrdersPage]
        A6[Order Detail / Tracking]
        
        A1 -->|"Tap producto"| A2
        A2 -->|"Agregar al carrito"| A3
        A3 -->|"Ir a pagar"| A4
        A4 -->|"Confirmar compra"| A5
        A5 -->|"Tap orden"| A6
    end
    
    subgraph NIVEL_1["🏪 NIVEL 1: COMERCIO"]
        B1[CommerceDashboardPage]
        B2[CommerceOrdersPage]
        B3[CommerceOrderDetailPage]
        
        B1 -->|"Ver órdenes"| B2
        B2 -->|"Tap orden"| B3
    end
    
    subgraph NIVEL_2["🚴 NIVEL 2: DELIVERY"]
        C1[DeliveryOrdersPage]
        C2[Detalle orden / Aceptar]
        
        C1 --> C2
    end
    
    subgraph NIVEL_4["👑 NIVEL 4: ADMIN"]
        D1[AdminDashboardPage]
    end
    
    A4 -->|"POST /orders"| E[(Backend: Orden pending_payment)]
    E --> B2
    B3 -->|"Validar pago"| F[(paid)]
    B3 -->|"En preparación"| G[(processing)]
    B3 -->|"Enviar"| H[(shipped)]
    H --> C1
    C2 -->|"Entregar"| I[(delivered)]
    I --> A5
```

---

## 3. Estados de la orden y acciones por nivel

```mermaid
stateDiagram-v2
    [*] --> pending_payment: Cliente confirma compra (CheckoutPage)
    
    pending_payment --> paid: Comercio valida comprobante (CommerceOrderDetailPage)
    pending_payment --> cancelled: Timeout 5 min / Cliente cancela
    
    paid --> processing: Comercio: "En preparación"
    paid --> cancelled: Comercio cancela
    
    processing --> shipped: Comercio: "Enviar" (lista para delivery)
    processing --> cancelled: Comercio cancela
    
    shipped --> delivered: Delivery: "Entregar"
    
    delivered --> [*]: Cliente califica (obligatorio)
    cancelled --> [*]
```

| Estado | Quién lo cambia | Pantalla | Acción |
|--------|------------------|----------|--------|
| `pending_payment` | Sistema (al crear) | CheckoutPage → OrdersPage | Cliente sube comprobante (si aplica) |
| `paid` | Comercio | CommerceOrderDetailPage | Comercio: Validar / Rechazar comprobante |
| `processing` | Comercio | CommerceOrderDetailPage | Comercio: "En preparación" |
| `shipped` | Comercio | CommerceOrderDetailPage | Comercio: "Enviar" |
| `delivered` | Delivery | DeliveryOrdersPage (detalle) | Delivery: "Entregar" |
| `cancelled` | Cliente / Comercio | Varias | Cancelar según reglas |

---

## 4. Vista detallada por nivel – Qué ve cada uno durante la compra

### NIVEL 0: COMPRADOR (users)

```mermaid
flowchart LR
    subgraph Entrada
        P1[ProductsPage]
        P2[RestaurantsPage]
    end
    
    subgraph Búsqueda_producto
        D1[ProductDetailPage]
        D2[RestaurantDetailsPage]
    end
    
    subgraph Carrito_y_checkout
        C1[CartPage]
        C2[CheckoutPage]
    end
    
    subgraph Post_compra
        O1[OrdersPage]
        O2[Order Detail]
    end
    
    P1 --> D1
    P2 --> D2
    D1 --> C1
    D2 --> C1
    C1 --> C2
    C2 --> O1
    O1 --> O2
```

| Paso | Vista | Acción | Siguiente |
|------|-------|--------|-----------|
| 1 | **ProductsPage** | Ver productos cercanos (geolocalización) | Tap producto |
| 2 | **ProductDetailPage** | Ver detalle, cantidad, notas, agregar | Tap "Agregar" |
| ALT | **RestaurantsPage** | Lista restaurantes | Tap restaurante |
| ALT | **RestaurantDetailsPage** | Ver menú, agregar productos | Tap "Agregar" |
| 3 | **CartPage** | Revisar carrito, ajustar cantidades | Tap "Ir a pagar" |
| 4 | **CheckoutPage** | Tipo entrega (pickup/delivery), dirección, confirmar | Tap "Confirmar compra" |
| 5 | **OrdersPage** | Lista de órdenes (Pusher actualiza estados) | Tap orden |
| 6 | **OrderDetailPage** | Ver estado, productos, total, **chat con comercio** (Pusher), subir comprobante (si pending_payment), cancelar (dentro 5 min) | - |

✅ **MVP:** `OrdersPage` navega a `OrderDetailPage` al hacer tap. El comprador puede subir comprobante (método de pago + referencia) y cancelar dentro del tiempo límite. **Chat:** Botón de chat abre `BuyerOrderChatPage`; mensajes en tiempo real vía **Pusher** (https://pusher.com).

ProductsPage y RestaurantsPage son vías alternativas; ambas alimentan el mismo carrito.

---

### NIVEL 1: COMERCIO (commerce)

```mermaid
flowchart LR
    subgraph Dashboard
        D[CommerceDashboardPage]
    end
    
    subgraph Órdenes
        O1[CommerceOrdersPage]
        O2[CommerceOrderDetailPage]
    end
    
    subgraph Otras
        P[CommerceProductsPage]
        R[CommerceReportsPage]
    end
    
    D --> O1
    O1 --> O2
    O2 -->|Validar pago| O2
    O2 -->|En preparación| O2
    O2 -->|Enviar| O2
```

| Paso | Vista | Acción | Resultado |
|------|-------|--------|-----------|
| 1 | **CommerceDashboardPage** | Resumen órdenes (paid, processing) | Tap orden o "Ver órdenes" |
| 2 | **CommerceOrdersPage** | Tabs: Todas, Pendientes, En Proceso, Enviadas, Entregadas, Canceladas | Tap orden |
| 3 | **CommerceOrderDetailPage** | Ver cliente, productos, total, **chat con cliente** (Pusher) | - |
| 3a | Si `pending_payment` + comprobante | Botones "Validar" / "Rechazar" | → paid o cancelled |
| 3a' | Si `pending_payment` (sin acuerdo tras chat) | Botón "Rechazar orden" (motivo opcional) | → cancelled |
| 3b | Si `paid` | "En preparación" / "Cancelar" | → processing |
| 3c | Si `processing` | "Enviar" / "Cancelar" | → shipped |

---

### NIVEL 2/3: DELIVERY (delivery_agent / delivery_company)

```mermaid
flowchart LR
    subgraph Entregas
        D1[DeliveryOrdersPage]
        D2[Detalle orden]
    end
    
    subgraph Otras
        H[DeliveryHistoryPage]
        R[DeliveryRoutesPage]
        E[DeliveryEarningsPage]
    end
    
    D1 --> D2
    D2 -->|Aceptar| D2
    D2 -->|Entregar| D2
```

| Paso | Vista | Acción | Resultado |
|------|-------|--------|-----------|
| 1 | **DeliveryOrdersPage** | Ver órdenes asignadas (shipped) | Filtros: Todos, Pendientes, En Progreso, Completadas |
| 2 | **Detalle orden** | Ver dirección, cliente, productos | Aceptar (si pendiente) / Entregar |
| 3 | - | Tap "Entregar" | Estado → delivered |

Nota: Delivery ve órdenes en estado `shipped` que le han sido asignadas. La asignación se hace en backend (cercanía, disponibilidad).

---

### NIVEL 4: ADMIN

```mermaid
flowchart LR
    subgraph Admin
        A1[AdminDashboardPage]
        A2[AdminUsersPage]
        A3[AdminSecurityPage]
        A4[AdminAnalyticsPage]
    end
    
    A1 --> A2
    A1 --> A3
    A1 --> A4
```

| Vista | Función en la compra |
|-------|----------------------|
| **AdminDashboardPage** | Supervisión general, métricas |
| **AdminUsersPage** | Gestión usuarios (buyer, commerce, delivery) |
| **AdminAnalyticsPage** | Reportes, analytics |
| **AdminSecurityPage** | Seguridad del sistema |

El admin no participa directamente en el ciclo de compra; supervisa y gestiona disputas según el modelo de negocio.

---

## 5. Secuencia temporal – Una compra de principio a fin

```mermaid
sequenceDiagram
    participant B as Comprador
    participant C as Comercio
    participant D as Delivery
    participant API as Backend

    B->>API: POST /orders (cart items, delivery_type)
    API-->>B: Orden creada (pending_payment)
    Note over B: OrdersPage muestra nueva orden
    
    B->>B: Sube comprobante (si pago manual)
    C->>CommerceOrdersPage: Ve orden pendiente
    C->>CommerceOrderDetailPage: Abre orden
    C->>API: Validar pago (validar/rechazar)
    API-->>C: paid
    Note over C: Botón "En preparación"
    
    C->>API: PUT status → processing
    Note over C: Prepara pedido
    
    C->>API: PUT status → shipped
    API-->>D: Asigna a delivery (si hay disponible)
    D->>DeliveryOrdersPage: Ve orden asignada
    
    D->>D: Va a recoger / entregar
    D->>API: PUT status → delivered
    API-->>B: Notificación (Pusher)
    
    B->>OrdersPage: Ve orden entregada
    B->>API: Crea review (obligatorio)
```

---

## 6. Navegación y rutas (MainRouter)

### Bottom nav por nivel

| Nivel | Índice 0 | 1 | 2 | 3 | Config |
|-------|----------|---|---|---|--------|
| 0 Comprador | ProductsPage | CartPage | OrdersPage | RestaurantsPage | SettingsPage2 |
| 1 Comercio | CommerceDashboardPage | CommerceOrdersPage | CommerceProductsPage | CommerceReportsPage | SettingsPage2 |
| 2 Delivery | DeliveryOrdersPage | DeliveryHistoryPage | DeliveryRoutesPage | DeliveryEarningsPage | SettingsPage2 |
| 3 Delivery Co. | DeliveryOrdersPage | DeliveryHistoryPage | DeliveryRoutesPage | DeliveryEarningsPage | SettingsPage2 |
| 4 Admin | AdminDashboardPage | AdminUsersPage | AdminSecurityPage | AdminAnalyticsPage | SettingsPage2 |

### Rutas con nombre (`Navigator.pushNamed`)

| Ruta | Pantalla |
|------|----------|
| `/order-details` | OrderDetailPage (comprador) |
| `/commerce/orders` | CommerceOrdersPage |
| `/commerce/order/:id` | CommerceOrderDetailPage |

### Navegación por push (ejemplos)

| Origen | Destino |
|--------|---------|
| ProductsPage | ProductDetailPage |
| RestaurantsPage | RestaurantDetailsPage |
| CartPage | CheckoutPage |
| CheckoutPage | OrdersPage |
| OrdersPage | OrderDetailPage |
| CommerceOrdersPage | CommerceOrderDetailPage |
| CommerceDashboardPage | CommerceOrderDetailPage |

---

## 7. Estado MVP (Febrero 2025)

| Área | Estado | Notas |
|------|--------|-------|
| CheckoutPage | ✅ | Calcula subtotal + envío (\$2.50 si delivery), envía delivery_fee al backend |
| OrderDetailPage | ✅ | Nueva: ver detalle, subir comprobante (método + referencia), cancelar (5 min) |
| OrdersPage | ✅ | Tap navega a OrderDetailPage; ruta /order-details en onGenerateRoute |
| Flujo comprobante | ✅ | Cliente sube en OrderDetailPage; backend valida payment_method y reference_number |
| Backend delivery_fee | ✅ | Acepta y guarda delivery_fee; valida total = subtotal + delivery_fee |
| Sincronización | ⚠️ | Carrito local; verificar addToRemoteCart vs restricción uni-commerce si se usa |
| Pusher | ⚠️ | OrdersPage suscrito a profile.{userId}; confirmar eventos de orden |
| **Pusher (chat)** | ✅ | BuyerOrderChatPage y CommerceChatMessagesPage suscritos a `private-order.{orderId}`; evento `NewMessage` para mensajes en tiempo real (https://pusher.com) |

---

## 8. Resumen ejecutivo

1. **Comprador**: ProductsPage / RestaurantsPage → ProductDetail / RestaurantDetails → CartPage → CheckoutPage → OrdersPage.
2. **Comercio**: CommerceOrdersPage → CommerceOrderDetailPage; valida pago, pasa a preparación y luego a enviado.
3. **Delivery**: DeliveryOrdersPage; recibe órdenes en `shipped`, las entrega y marca como `delivered`.
4. **Admin**: Supervisión y analytics, sin pasos obligatorios en el ciclo de compra.

Estados: `pending_payment` → `paid` → `processing` → `shipped` → `delivered`. Cada transición la ejecuta el rol correspondiente desde su detalle de orden.

---

*Documento generado a partir del análisis del código de Zonix Eats (frontend Flutter).*
*Fecha: Febrero 2025*
