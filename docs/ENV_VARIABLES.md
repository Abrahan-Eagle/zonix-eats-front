# Variables .env — Zonix Glasses Frontend

Referencia de variables. Ver `.env.example` como plantilla.

## Principales

| Variable | Uso |
|----------|-----|
| `APP_NAME` | Nombre visible (`Zonix Glasses`) |
| `ENVIRONMENT` | `development` / `staging` / `production` |
| `API_URL_DEV`, `API_URL_TEST`, `API_URL_PROD` | Base URL del backend |
| `WS_URL_*` | WebSocket (Pusher) si aplica |
| `ENABLE_PUSHER`, `ENABLE_WEBSOCKETS` | Flags tiempo real |
| `FIREBASE_*` | Push FCM |

## Notas

- URLs de servidor y Firebase son credenciales/infra del entorno actual.
- El paquete Dart se llama `zonix_glasses` (`com.zonix.glasses`).
