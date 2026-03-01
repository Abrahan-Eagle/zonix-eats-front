// pubspec.dart
class Pubspec {
  static const String version = '1.0.0';
  static const String versionBuild = '1';
  static const List<String> authorsName = ['Ing. Abrahan Pulido'];
  static const String description = '''
Zonix es una aplicación innovadora para la gestión y el agendamiento de pedidos de comida a domicilio. Diseñada para simplificar el proceso tanto para los usuarios como para los restaurantes, Zonix automatiza la asignación de horarios y puestos de entrega según la disponibilidad diaria, permitiendo una experiencia fluida y eficiente.

## Características Principales

- **Gestión de Pedidos**: Sistema completo para crear, gestionar y rastrear pedidos
- **Entrega a Domicilio**: Coordinación automática con repartidores
- **Pagos Seguros**: Múltiples métodos de pago integrados
- **Notificaciones en Tiempo Real**: Actualizaciones instantáneas del estado del pedido
- **Gestión de Restaurantes**: Panel completo para administrar menús y pedidos
- **Sistema de Repartidores**: Coordinación eficiente de entregas

## Tecnologías

- **Frontend**: Flutter para aplicaciones móviles multiplataforma
- **Backend**: Laravel con API REST
- **Base de Datos**: MySQL
- **Tiempo real**: Pusher Channels para notificaciones y chat
- **Autenticación**: Laravel Sanctum

Esta aplicación es una solución completa para la gestión eficiente y organizada de pedidos de comida, diseñada para ahorrar tiempo y esfuerzo tanto para los usuarios como para los restaurantes.

© {{year}} Ing. Abrahan Pulido. Todos los derechos reservados.
  ''';
}

String getAppDescription() {
  final currentYear = DateTime.now().year;
  return Pubspec.description.replaceAll('{{year}}', currentYear.toString());
}
