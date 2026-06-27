# Zonix Glasses — Frontend (Flutter)

Companion app Flutter para Zonix Glasses (paquete Dart: `zonix_glasses`). Auth, perfiles, direcciones, teléfonos, documentos, notificaciones y settings.

## Requisitos

- Flutter SDK estable
- Backend `zonix-glasses-back` en ejecución

## Setup

```bash
flutter pub get
cp .env.example .env
flutter run
flutter analyze
flutter test
```

## Identificadores nativos

| Plataforma | ID |
|------------|-----|
| Android | `com.zonix.glasses` |
| iOS / macOS | `com.zonix.glasses` |
| Dart | `zonix_glasses` |

## Estructura

- `lib/app/` — router, FCM, navegación
- `lib/config/` — `AppConfig`
- `lib/features/` — módulos
- `test/` — tests

## Backend hermano

Ver `../zonix-glasses-back`.

## Firebase

Crear proyecto Firebase nuevo para `com.zonix.glasses`. Colocar `google-services.json` en `android/app/` y habilitar el plugin en `android/app/build.gradle`.

## Documentación IA

- `AGENTS.md`, `.cursorrules`, `docs/active_context.md`
