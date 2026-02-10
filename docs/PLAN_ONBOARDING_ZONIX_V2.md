# Plan Onboarding Zonix Eats v2

Basado en tus respuestas, referencias PedidosYa y uso del módulo de dirección tipo CorralX.

---

## 1. Resumen de decisiones

| Tema | Decisión |
|------|----------|
| **Rol** | Se elige **después** de las vistas introductorias/promocionales. |
| **Slides intro** | Sí, tipo PedidosYa (Descubrí locales, Resolvé compras, ubicación, notificaciones, seguimiento). |
| **Ubicación** | Usar el **formulario de dirección** como en el onboarding de CorralX (formulario 2 = dirección). |
| **Datos comprador** | Nombre, apellido, teléfono, dirección (mapa + detalle), opcional “Cuéntanos más de ti” (fecha nacimiento, género). |
| **Datos comerciante** | Los mismos que comprador + datos extra según tablas (commerces, etc.); revisar migraciones. |
| **Dirección** | Celular de contacto para entrega y referencias/indicaciones (estilo PedidosYa). Nombre dirección (Casa/Trabajo/Otro) para comprador y comerciante; comerciante tiene además su tabla. |
| **Guardado** | **Solo al final** del onboarding: todo en memoria durante el flujo; al cerrar el ciclo se envía todo al backend. |
| **Progreso** | Barra de progreso arriba (estilo PedidosYa). Ir atrás sin perder borrador. |

---

## 2. Orden del flujo propuesto

1. **Slides introductorios** (con imágenes, X para saltar, Continuar)  
   - Ej. “Descubrí locales y pedí tus platos favoritos”  
   - “Resolvé tus compras en minutos”  
   - “Descubre qué hay cerca tuyo” (ubicación)  
   - “Seguí tus pedidos minuto a minuto” (notificaciones)  
   - “Seguí tu pedido en tiempo real” (tracking) → **Comenzar**

2. **Elección de rol**  
   - Comprador (users) | Comerciante (commerce)  
   - Define qué pasos y campos se muestran después.

3. **Cuéntanos más de ti** (ambos roles)  
   - Nombre(s), Apellido(s)  
   - Fecha nacimiento (DD/MM/AAAA)  
   - Género: Femenino, Masculino, No binario, Prefiero no decir  
   - Botón “Guardar datos”, enlace “Ahora no” para omitir (solo esta pantalla).

4. **Dirección** (según formulario dirección CorralX + PedidosYa)  
   - Mapa + pin + “Confirma tu dirección” + campo calle + Confirmar  
   - Detalles: piso/apto/casa, referencias/indicaciones (límite ej. 100 caracteres), celular contacto, nombre (Casa / Trabajo / Otro)  
   - País, estado, ciudad (según API existente).

5. **Solo comerciante**  
   - Datos negocio: razón social, tipo negocio, RIF/tax_id, dirección negocio (¿misma que perfil o otra?), foto, teléfono, horario/open, etc. (según migraciones).

6. **Resumen / Listo**  
   - Revisión y botón **Finalizar** → envío único al backend y `completed_onboarding = 1`.

---

## 3. Tablas y campos relevantes (backend – migraciones)

### users
- `id`, `name`, `email`, `password`, `google_id`, `given_name`, `family_name`, `profile_pic`, `AccessToken`, `completed_onboarding`, `role`, `remember_token`, `timestamps`

### profiles
- `id`, `user_id`, `firstName`, `middleName`, `lastName`, `secondLastName`, `photo_users`, `date_of_birth`, `maritalStatus`, `sex`, `status`, `address` (text nullable), `fcm_device_token`, `notification_preferences`, `timestamps`
- **Nota:** El teléfono **no** está en `profiles`; se eliminó por migración. El teléfono va en la tabla `phones` (ver abajo).

### addresses
- `id`, `street`, `house_number`, `postal_code`, `latitude`, `longitude`, `status`, `is_default`, `profile_id`, `city_id`, `timestamps`  
- **No hay hoy:** `delivery_instructions` (referencias), `contact_phone`, `label` (Casa/Trabajo/Otro). Si se quieren como en PedidosYa, haría falta migración nueva.

### phones
- `id`, `profile_id`, `operator_code_id`, `number` (7 caracteres), `is_primary`, `status`, `approved`, `timestamps`
- **operator_codes:** `id`, `code` (ej. 0412), `name` (ej. Movilnet). El teléfono completo = código + número.

### commerces
- `id`, `profile_id`, `business_name`, `business_type`, `tax_id`, `image`, `phone`, `address`, `open`, `schedule`, `membership_*`, `commission_percentage`, `cancellation_count`, `last_cancellation_date`, `timestamps`

### Relaciones dirección
- `countries` → `states` (countries_id) → `cities` (state_id)  
- `addresses.city_id` → `cities.id`

---

## 4. CorralX como referencia

- **En este workspace no existe** la ruta `CorralX-Frontend/lib/onboarding`.  
- En `stitch_zonix_eats_onboarding_screen` hay un paso “delivery” que es solo **promocional** (ilustración + texto), no un formulario de dirección con mapa y campos.
- Para alinear con “formulario 2 que es de dirección” de CorralX necesito:
  - **Opción A:** Ruta exacta del proyecto CorralX en tu máquina (o en el workspace) para leer esos archivos, o  
  - **Opción B:** Copiar aquí (o adjuntar) el contenido o capturas del formulario de dirección de CorralX (vista + campos).

---

## 5. Preguntas pendientes (para cerrar el plan)

### 5.1 “Cuéntanos más de ti”
- ¿Incluimos **No binario** y **Prefiero no decir** en género? (en las imágenes de PedidosYa aparecen).
- ¿“Ahora no” en esa pantalla solo **omite esa pantalla** y sigue al paso de dirección, o debe saltar también otros pasos?

### 5.2 Dirección en BD
- Para **referencias/indicaciones** (ej. “casa blanca con rejas…”) y **nombre** (Casa/Trabajo/Otro):  
  - ¿Quieres que agreguemos columnas en `addresses` (ej. `delivery_instructions`, `label`) por migración nueva, o prefieres guardar eso en otro sitio (ej. `profiles.address` como texto libre o JSON)?
- **Celular de contacto para la entrega**: hoy el teléfono va en `profiles.phone` y en `phones`. ¿El “celular para esta dirección” es el mismo que el del perfil o puede ser distinto por dirección? (si es distinto, haría falta campo en `addresses` o en una tabla de “contactos por dirección”).

### 5.3 Comerciante – dirección
- ¿El comerciante tiene **una sola dirección** (la del negocio en `commerces.address` + opcionalmente una en `addresses` como perfil), o **dos** (personal en `addresses` y negocio en `commerces`)? ¿En onboarding pedimos las dos o solo la del negocio?

### 5.4 Permisos (ubicación / notificaciones)
- ¿Los pasos de **ubicación** y **notificaciones** son **obligatorios** (no se puede seguir sin aceptar) o **todos** se pueden saltar con “X” / “Ahora no”?

### 5.5 CorralX – formulario 2
- Cuando puedas, comparte **formulario 2 (dirección)** de CorralX:  
  - ya sea la ruta al proyecto/carpeta en el workspace, o  
  - el listado de campos y si hay mapa, confirmación en dos pasos, etc.  
  Así se deja el paso de dirección de Zonix alineado con ese ejemplo.

---

## 6. Siguiente paso

Con las respuestas a la sección 5 y (si aplica) el contenido o ruta del formulario de dirección de CorralX, se puede:

1. Definir el **orden exacto** de pantallas y qué campos tiene cada una.  
2. Decidir si hace falta **migración** en `addresses` (y/o `profiles`/commerces) para referencias, label y teléfono de entrega.  
3. Bajar el flujo a **cambios concretos** en el onboarding actual de Zonix (pantallas, modelo de borrador en memoria y envío final al backend).
