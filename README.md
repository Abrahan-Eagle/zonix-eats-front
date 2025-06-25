# zonix

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Zonix Eats Frontend

## Descripción
Frontend de Zonix Eats, desarrollado en Flutter. Permite a usuarios navegar productos, hacer pedidos y gestionar su cuenta.

## Instalación
```bash
cd zonix-eats-front
flutter pub get
flutter run # para desarrollo
flutter test # para tests
```

## Variables de Entorno
- API_URL_LOCAL, API_URL_PROD

## Estructura
- lib/features: Pantallas y servicios
- lib/models: Modelos de datos
- lib/helpers: Utilidades
- test/: Pruebas unitarias y de integración

## Testing
```bash
flutter test
```

## Buenas Prácticas
- Usa logger para debug
- Valida formularios y errores de red
- Elimina código y pantallas ajenas al dominio

## Créditos
- Imágenes de productos: [TheMealDB](https://www.themealdb.com/api.php)
