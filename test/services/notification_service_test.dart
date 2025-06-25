import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../lib/features/services/notification_service.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });
  group('NotificationService', () {
    // late NotificationService notificationService;
    // setUp(() {
    //   notificationService = NotificationService();
    // });

    // test('fetchNotifications returns a list', () async {
    //   final notifications = await notificationService.fetchNotifications();
    //   expect(notifications, isA<List>());
    // });
    // Nota: Descomentar y adaptar el test anterior si el método existe y es mockeable.
  });
}
