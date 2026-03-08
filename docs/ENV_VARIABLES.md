# Variables .env - Zonix Eats Frontend

**En producción solo deben tenerse en cuenta las variables listadas en "Variables para producción". Las de "Pruebas / demo" no deben usarse ni configurarse en producción.**

---

## Variables para producción

Son las únicas que importan en producción.

### Obligatorias

| Variable | Uso |
|----------|-----|
| `API_URL` o `API_URL_LOCAL` / `API_URL_PROD` | URL del backend (AppConfig.apiUrl). En prod usar `API_URL_PROD`. |
| `APP_NAME` | Nombre de la app |

### Recomendadas (tiempo real y entorno)

| Variable | Uso |
|----------|-----|
| `API_URL_PROD` | URL del API en producción |
| `PUSHER_APP_KEY`, `PUSHER_APP_CLUSTER` | Pusher (notificaciones, tiempo real) |
| `ENABLE_PUSHER` | `true` si usas Pusher en prod |
| `APP_DOMAIN` | Dominio de la app (deep links, compartir) |
| `CONTACT_EMAIL` | Email de contacto |

### Opcionales (tienen default en código)

Solo si quieres cambiar el valor; si no, se usan los de `app_config.dart`.

| Variable | Uso |
|----------|-----|
| `CONNECTION_TIMEOUT`, `RECEIVE_TIMEOUT`, `REQUEST_TIMEOUT` | Timeouts HTTP (ms) |
| `DEFAULT_PAGE_SIZE`, `MAX_PAGE_SIZE` | Paginación |
| `DEFAULT_DELIVERY_FEE` | Tarifa delivery (UI) |
| `OSM_TILE_URL`, `NOMINATIM_*`, `GOOGLE_MAPS_*`, `OPENSTREETMAP_VIEW_URL`, `WHATSAPP_BASE_URL` | Mapas, geocoding, enlaces externos |
| `APP_VERSION`, `APP_BUILD_NUMBER` | Versión y build |

---

## Variables de prueba / demo — NO TENER EN CUENTA EN PRODUCCIÓN

Solo para desarrollo o entornos de prueba. **No configurar en producción.** Documentadas para que el equipo no las use en prod.

| Variable | Uso (solo desarrollo/pruebas) |
|----------|-------------------------------|
| `API_URL_LOCAL` | URL del backend en local (ej. http://192.168.27.12:8000). |
| `API_URL_TEST` | URL de backend de pruebas (ej. test.eats.aiblockweb.com). |
| `APP_DOMAIN_LOCAL` | Dominio/IP local (ej. 192.168.27.12). |
| `DEBUG_MODE` | Activar logs y comportamiento de depuración. En prod debe ser `false` o no definirse. |
| `ENABLE_LOGGING` | Logs detallados. En prod normalmente `false`. |
| `ENVIRONMENT` | Entorno (development/staging); no referenciado en AppConfig, solo documental. |

En producción: no definir `API_URL_TEST`, `APP_DOMAIN_LOCAL`; usar `API_URL_PROD` y `APP_DOMAIN`. Dejar `DEBUG_MODE` y `ENABLE_LOGGING` en `false` o sin definir.

---

## No usadas por el código

- `PUSHER_AUTH_ENDPOINT`: no se usa; la URL de auth se arma con `AppConfig.apiUrl + '/api/broadcasting/auth'`.
- `WS_URL_*`, `ECHO_*`: tiempo real es solo Pusher.
- `GOOGLE_GEN_AI_*`: no referenciadas en `lib/`.
- `GOOGLE_MAPS_API_KEY`, `FIREBASE_*`: solo si usas esos servicios en la app.
