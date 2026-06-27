# Checklist — Zonix Glasses Frontend

## Entorno

- [ ] `flutter pub get`
- [ ] `cp .env.example .env` — `API_URL_LOCAL` apuntando a back
- [ ] Backend `zonix-glasses-back` en ejecución

## Identificadores (ya configurados)

| Plataforma | Valor |
|------------|-------|
| Dart | `zonix_glasses` |
| Android / iOS | `com.zonix.glasses` |

## Firebase

- [ ] Crear proyecto Firebase Glasses
- [ ] Descargar `google-services.json` → `android/app/`
- [ ] Descomentar `apply plugin: 'com.google.gms.google-services'` en `android/app/build.gradle`

## Verificación

```bash
flutter analyze
flutter test
flutter run
```
