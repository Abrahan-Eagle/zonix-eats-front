import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });
  group('NotificationService', () {
    // Aquí puedes agregar tests reales cuando el método esté implementado
    // test('fetchNotifications returns a list', () async {
    //   final notificationService = NotificationService();
    //   final notifications = await notificationService.fetchNotifications();
    //   expect(notifications, isA<List<NotificationItem>>());
    // });
  });
}
