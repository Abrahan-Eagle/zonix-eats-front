# Zonix Eats Frontend (Flutter)

Aplicación móvil de Zonix Eats desarrollada en Flutter. Permite a clientes, comercios y repartidores interactuar con la plataforma de pedidos y entregas en tiempo real.

---

## 📦 Estructura del proyecto

```
lib/
  core/           # Utilidades, helpers, temas, constantes globales
  models/         # Modelos de datos (Product, User, etc.)
  features/       # Features principales agrupadas por dominio
    products/
      screens/
      services/
      widgets/
    cart/
    auth/
    profile/
    ...           # Otras features (delivery, orders, etc.)
  helpers/        # Funciones utilitarias generales
  main.dart
assets/           # Imágenes, fuentes, íconos
 test/            # Tests unitarios y de widgets (refleja la estructura de lib/)
```

---

## 🚀 Cómo correr la app

1. Instala dependencias:
   ```bash
   flutter pub get
   ```
2. Corre la app en modo desarrollo:
   ```bash
   flutter run
   ```
3. Compila para producción:
   ```bash
   flutter build apk --release
   ```

---

## 🧪 Cómo correr los tests

```bash
flutter test
```
Todos los tests relevantes deben pasar. Los tests de servicios usan mocks para evitar dependencias de red.

---

## 📝 Convenciones y buenas prácticas
- Agrupa el código por dominio/feature.
- Usa nombres claros y descriptivos para archivos y carpetas.
- Mantén los tests junto a la lógica que prueban.
- Usa mocks para servicios externos en los tests.
- Documenta cualquier convención especial aquí.

---

## 📄 Contacto y soporte
Para dudas o soporte, contacta a tu equipo de desarrollo o abre un issue en el repositorio.
