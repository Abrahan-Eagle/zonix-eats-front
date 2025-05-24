// pubspec.dart
class Pubspec {
  static const String version = '1.0.0';
  static const String versionBuild = '1';
  static const List<String> authorsName = ['Ing. Abrahan Pulido'];
  static const String description = '''
Zonix es una aplicación innovadora para la gestión y el agendamiento de citas para la compra de bombonas de gas. Diseñada para simplificar el proceso tanto para los usuarios como para los administradores, Zonix automatiza la asignación de horarios y puestos de recogida según la disponibilidad diaria, permitiendo un flujo de trabajo eficiente y controlado.

Con Zonix, los usuarios pueden:
- Registrar sus bombonas y generar citas de compra de forma sencilla.
- Consultar la disponibilidad de citas en función de su ubicación.
- Visualizar y gestionar sus citas programadas.
- Acceder a un sistema de notificaciones sobre su cita y estatus de la jornada.

Funciones principales:
- **Gestión de citas:** Agendamiento y asignación de horarios automáticos, con un límite diario de citas.
- **Control administrativo:** El administrador puede aprobar datos, controlar el ciclo de trabajo, y cerrar la caja al final de la jornada.
- **Validación de disponibilidad:** Verificación de la dirección del usuario para determinar la disponibilidad de citas.
- **Asignación de horarios:** Horarios automáticos con intervalos de 1 minuto entre cada cita, comenzando desde las 9:00 am.

Esta aplicación es una solución completa para la compra eficiente y organizada de bombonas de gas, diseñada para ahorrar tiempo y esfuerzo tanto para los usuarios como para los administradores.

© {{year}} Ing. Abrahan Pulido. Todos los derechos reservados.
  ''';
}

String getAppDescription() {
  final currentYear = DateTime.now().year;
  return Pubspec.description.replaceAll('{{year}}', currentYear.toString());
}
