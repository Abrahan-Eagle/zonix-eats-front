# Análisis: Settings Zonix Eats vs referencia (Edita el perfil)

Basado en las capturas de referencia de "Edita el perfil" (estilo negocio/perfil público).

---

## Importante: Settings es por rol

**Cada rol ve un Settings distinto.** No todos los usuarios ven las mismas pestañas ni las mismas opciones.

| Rol        | Tabs visibles                    | Contenido específico del rol |
|-----------|-----------------------------------|-------------------------------|
| **users** (comprador) | Persona, Más                     | Persona: foto, editar perfil, mis pedidos, Documentos, Direcciones, Teléfonos, Legal, Cerrar sesión. Más: CUENTA (Actividad, Exportar, Privacidad), SOPORTE (Ayuda, Notificaciones, Acerca de). |
| **commerce**         | Persona, **Publicaciones**, **Comercios**, Más | Lo mismo que users en Persona y Más, **más**: tab Publicaciones (posts), tab Comercios (lista de mis comercios). En **Más**: además de CUENTA y SOPORTE, ve **CONFIGURACIÓN DE NEGOCIO** (Datos comercio, Métodos de pago, Horarios), **PROMOCIONES Y VENTAS** (Crear promo, Cupones), **MÁS OPCIONES** (Abierto/cerrado, Zonas delivery, Pago móvil, Notificaciones comercio). |
| **delivery**         | Persona, Más                     | Misma estructura que **users**. Opciones propias (disponibilidad, vehículo, zonas) se pueden añadir en Más cuando se definan. |
| **admin**            | Persona, Más                     | Misma estructura que **users**. El panel de administración está en otro flujo (dashboard admin); Settings es perfil personal. |

Al mejorar Settings hay que tener en cuenta **para qué rol** aplica cada cambio (ej. icono cámara en foto para todos; horarios y portada solo para commerce; enlaces/redes solo para commerce). **Delivery** y **admin** comparten estructura con users; si se añaden opciones por rol, documentarlas en esta tabla.

---

## Lo que hace bien la referencia

### 1. **Foto de perfil muy visible**
- **Foto circular** grande en la parte superior, a veces superpuesta sobre una **foto de portada** (cover).
- **Icono de cámara** encima de la foto (o en una esquina): deja claro que al tocar se **cambia la foto**, no se va a un formulario.
- Texto de contexto: "Tu perfil es público. Más información".

### 2. **Secciones con títulos claros**
- **Información de la empresa** (o equivalente): nombre, descripción, horarios.
- **Horarios por día**: Domingo a Sábado con estado (Cerrado / Solo con cita).
- **Descripción** y **Dirección** con iconos (documento, pin).
- **Productos y servicios** → Catálogo.
- **Enlaces** → Sitio web, Instagram, Facebook.
- **Información de contacto** → Correo, teléfono, Info.

### 3. **Jerarquía visual**
- Bloque de foto(s) arriba.
- Luego bloques por sección con iconos y texto.
- Sin mezclar “Persona” y “Comercio” en el mismo scroll sin separación.

### 4. **Acciones en la foto**
- Cámara en la foto = “tomar/cambiar foto”.
- No redirige a un formulario largo; la acción es directa.

---

## Lo que tiene hoy Zonix Eats (Settings)

### Por rol (resumen)

- **users / delivery / admin:** tabs **Persona** y **Más**.
- **commerce:** tabs **Persona**, **Publicaciones**, **Comercios** y **Más** (en Más aparecen además las secciones de negocio, promos, horarios, etc.).

### Pestañas y contenido común
- **Persona** (Mi Perfil): cabecera con foto, nombre, email + botones "Editar Perfil" / "Mis Pedidos" + Documentos, Direcciones, Teléfonos, Legal, Cerrar sesión. (Común a todos los roles que ven Persona.)
- **Publicaciones** (solo **commerce**): listado de posts del comercio.
- **Comercios** (solo **commerce**): lista de mis comercios (CommerceListPage).
- **Más**: CUENTA (Actividad, Exportar, Privacidad); si es **commerce**, además CONFIGURACIÓN DE NEGOCIO, PROMOCIONES Y VENTAS, MÁS OPCIONES; luego SOPORTE (Ayuda, Notificaciones, Acerca de).

### Foto en Persona
- Foto circular con borde degradado.
- **Tap en la foto** → ya abre cámara y actualiza (implementado).
- Icono de lápiz (editar) → va al formulario de perfil.

### Puntos fuertes actuales
- Tabs claros (Persona / Más / Comercio si aplica).
- Tiles con iconos (Documentos, Direcciones, Teléfonos).
- Bloque Legal (Términos, Privacidad).
- Cerrar sesión y eliminar cuenta visibles.

---

## Mejoras sugeridas para Zonix Eats

### Prioridad alta

| Mejora | Referencia | Zonix actual | Acción sugerida |
|--------|------------|--------------|------------------|
| **Icono de cámara en la foto** | Círculo con cámara en la esquina de la foto | Solo ícono de lápiz aparte | Añadir un **badge/icono de cámara** sobre la foto (ej. esquina inferior derecha) para que sea obvio que “tap = nueva foto”. |
| **Secciones con título** | "Información de la empresa", "Enlaces", "Contacto" | Todo en un solo bloque sin títulos de sección | En **Persona**, agrupar con títulos: **"Datos personales"** (Editar perfil, Documentos, Direcciones, Teléfonos), **"Legal"**, **"Cuenta"** (Cerrar sesión, Eliminar). |
| **Horarios del comercio** | Días con estado (Cerrado / Solo con cita) | En otra pantalla (commerce) | Solo rol **commerce**: en Persona o en Más, mostrar **resumen de horarios** (ej. “Lun–Vie 9–18, Sáb cerrado”) o enlace directo a “Horarios”. |

### Prioridad media

| Mejora | Referencia | Zonix actual | Acción sugerida |
|--------|------------|--------------|------------------|
| **Foto de portada (comercio)** | Cover + foto de perfil | Solo foto circular | Solo rol **commerce**: opcional **imagen de portada** del negocio y foto de perfil superpuesta. |
| **Enlaces / redes** | Sitio web, Instagram, Facebook | No hay bloque “Enlaces” en settings | Solo rol **commerce**: sección **"Enlaces"** (web, Instagram, Facebook) en datos del comercio o en Settings. |
| **Contacto visible** | Correo empresa, teléfono | Email en cabecera; teléfono en Teléfonos | **Todos los roles**: en cabecera de Persona, mostrar **teléfono principal** (si existe) junto al email. |
| **Descripción del negocio** | Descripción / categoría visible | En comercio, en otra pantalla | Solo rol **commerce**: en Persona o cabecera, mostrar **descripción o categoría** del negocio bajo el nombre. |

### Prioridad baja

| Mejora | Referencia | Zonix actual | Acción sugerida |
|--------|------------|--------------|------------------|
| **Texto “Tu perfil es público”** | Bajo la foto | No existe | Opcional: bajo la foto, texto tipo “Tu perfil es visible para los comercios” + “Más información” (enlace a privacidad). |
| **Header de pantalla** | Compartir, megáfono, perfil | Atrás + título + logout/settings | Valorar **acción de compartir perfil** (si aplica) o mantener solo las acciones actuales. |

---

## Resumen de cambios recomendados (orden sugerido)

1. **Añadir icono de cámara sobre la foto** en Settings (Persona), manteniendo tap = abrir cámara.
2. **Agrupar contenido de Persona** con títulos de sección: "Datos personales", "Legal", "Cuenta".
3. **Para comercio:** resumen de horarios y/o enlace a Horarios; opcional: portada + enlaces (web, redes).
4. **Mostrar teléfono principal** en la cabecera si existe (o primera línea debajo del email).
5. **Opcional:** texto “Tu perfil es visible…” bajo la foto y enlace a Privacidad.

Con esto, Settings de Zonix Eats se acerca a la claridad y estructura de la referencia, sin copiar el diseño al detalle.

---

## Recordatorio para desarrollo

- **Settings no es igual para todos:** users, commerce, delivery y admin tienen tabs y/o bloques distintos.
- Al añadir una nueva opción o sección, definir **para qué rol** es (y en qué tab: Persona, Más, Comercios, etc.).
- La pestaña **Persona** es común; **Publicaciones** y **Comercios** solo commerce; el contenido de **Más** se amplía para commerce (CONFIGURACIÓN DE NEGOCIO, PROMOCIONES, MÁS OPCIONES).
- **Delivery** y **admin** comparten estructura con users; si se añaden opciones por rol, documentarlas en esta tabla.
