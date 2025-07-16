import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zonix_eats_front/features/services/commerce_notification_service.dart';

@GenerateMocks([http.Client, FlutterSecureStorage])
import 'commerce_notification_service_test.mocks.dart';

void main() {
  group('CommerceNotificationService Tests', () {
    late MockClient mockClient;
    late MockFlutterSecureStorage mockStorage;
    late CommerceNotificationService service;

    setUp(() {
      mockClient = MockClient();
      mockStorage = MockFlutterSecureStorage();
      service = CommerceNotificationService();
    });

    group('getNotifications', () {
      test('should return list of notifications when API call is successful', () async {
        // Arrange
        const token = 'test_token';
        const expectedResponse = '''
        {
          "success": true,
          "data": [
            {
              "id": 1,
              "title": "New Order",
              "body": "You have a new order #123",
              "type": "order",
              "read_at": null,
              "created_at": "2024-01-15T10:00:00Z"
            },
            {
              "id": 2,
              "title": "Payment Validated",
              "body": "Payment for order #123 has been validated",
              "type": "payment",
              "read_at": "2024-01-15T11:00:00Z",
              "created_at": "2024-01-15T10:30:00Z"
            }
          ]
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await service.getNotifications();

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 2);
        expect(result[0]['title'], 'New Order');
        expect(result[0]['type'], 'order');
        expect(result[0]['read_at'], isNull);
        expect(result[1]['title'], 'Payment Validated');
        expect(result[1]['type'], 'payment');
        expect(result[1]['read_at'], isNotNull);
      });

      test('should return filtered notifications when type parameter is provided', () async {
        // Arrange
        const token = 'test_token';
        const notificationType = 'order';
        const expectedResponse = '''
        {
          "success": true,
          "data": [
            {
              "id": 1,
              "title": "New Order",
              "body": "You have a new order #123",
              "type": "order",
              "read_at": null,
              "created_at": "2024-01-15T10:00:00Z"
            }
          ]
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await service.getNotifications(type: notificationType);

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 1);
        expect(result[0]['type'], 'order');
      });

      test('should return unread notifications when read parameter is false', () async {
        // Arrange
        const token = 'test_token';
        const expectedResponse = '''
        {
          "success": true,
          "data": [
            {
              "id": 1,
              "title": "New Order",
              "body": "You have a new order #123",
              "type": "order",
              "read_at": null,
              "created_at": "2024-01-15T10:00:00Z"
            }
          ]
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await service.getNotifications(read: false);

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 1);
        expect(result[0]['read_at'], isNull);
      });

      test('should throw exception when token is not found', () async {
        // Arrange
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.getNotifications(),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception when API call fails', () async {
        // Arrange
        const token = 'test_token';
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Server error"}', 500));

        // Act & Assert
        expect(
          () => service.getNotifications(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getNotification', () {
      test('should return notification when API call is successful', () async {
        // Arrange
        const token = 'test_token';
        const notificationId = 1;
        const expectedResponse = '''
        {
          "success": true,
          "data": {
            "id": 1,
            "title": "Test Notification",
            "body": "Test notification body",
            "type": "system",
            "read_at": null,
            "created_at": "2024-01-15T10:00:00Z"
          }
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await service.getNotification(notificationId);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], 1);
        expect(result['title'], 'Test Notification');
        expect(result['type'], 'system');
      });

      test('should throw exception when notification not found', () async {
        // Arrange
        const token = 'test_token';
        const notificationId = 999;
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Notification not found"}', 404));

        // Act & Assert
        expect(
          () => service.getNotification(notificationId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('markAsRead', () {
      test('should mark notification as read successfully', () async {
        // Arrange
        const token = 'test_token';
        const notificationId = 1;
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"success": true}', 200));

        // Act & Assert
        expect(
          () => service.markAsRead(notificationId),
          returnsNormally,
        );
      });

      test('should throw exception when marking as read fails', () async {
        // Arrange
        const token = 'test_token';
        const notificationId = 999;
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Notification not found"}', 404));

        // Act & Assert
        expect(
          () => service.markAsRead(notificationId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('markAllAsRead', () {
      test('should mark all notifications as read successfully', () async {
        // Arrange
        const token = 'test_token';
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"success": true}', 200));

        // Act & Assert
        expect(
          () => service.markAllAsRead(),
          returnsNormally,
        );
      });

      test('should throw exception when marking all as read fails', () async {
        // Arrange
        const token = 'test_token';
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Server error"}', 500));

        // Act & Assert
        expect(
          () => service.markAllAsRead(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteNotification', () {
      test('should delete notification successfully', () async {
        // Arrange
        const token = 'test_token';
        const notificationId = 1;
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"success": true}', 200));

        // Act & Assert
        expect(
          () => service.deleteNotification(notificationId),
          returnsNormally,
        );
      });

      test('should throw exception when deletion fails', () async {
        // Arrange
        const token = 'test_token';
        const notificationId = 999;
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Notification not found"}', 404));

        // Act & Assert
        expect(
          () => service.deleteNotification(notificationId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getNotificationStats', () {
      test('should return notification statistics successfully', () async {
        // Arrange
        const token = 'test_token';
        const expectedResponse = '''
        {
          "success": true,
          "data": {
            "total_notifications": 50,
            "unread_notifications": 15,
            "today_notifications": 5,
            "order_notifications": 20,
            "payment_notifications": 15,
            "delivery_notifications": 10,
            "system_notifications": 5
          }
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await service.getNotificationStats();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['total_notifications'], 50);
        expect(result['unread_notifications'], 15);
        expect(result['today_notifications'], 5);
        expect(result['order_notifications'], 20);
        expect(result['payment_notifications'], 15);
        expect(result['delivery_notifications'], 10);
        expect(result['system_notifications'], 5);
      });

      test('should throw exception when getting stats fails', () async {
        // Arrange
        const token = 'test_token';
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Server error"}', 500));

        // Act & Assert
        expect(
          () => service.getNotificationStats(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getUnreadNotifications', () {
      test('should return unread notifications', () async {
        // Arrange
        const token = 'test_token';
        const expectedResponse = '''
        {
          "success": true,
          "data": [
            {
              "id": 1,
              "title": "Unread Notification 1",
              "read_at": null
            },
            {
              "id": 2,
              "title": "Unread Notification 2",
              "read_at": null
            }
          ]
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await service.getUnreadNotifications();

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 2);
        expect(result[0]['read_at'], isNull);
        expect(result[1]['read_at'], isNull);
      });
    });

    group('getNotificationsByType', () {
      test('should return notifications by type', () async {
        // Arrange
        const token = 'test_token';
        const notificationType = 'order';
        const expectedResponse = '''
        {
          "success": true,
          "data": [
            {
              "id": 1,
              "title": "Order Notification 1",
              "type": "order"
            },
            {
              "id": 2,
              "title": "Order Notification 2",
              "type": "order"
            }
          ]
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await service.getNotificationsByType(notificationType);

        // Assert
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 2);
        expect(result[0]['type'], 'order');
        expect(result[1]['type'], 'order');
      });
    });

    group('getUnreadCount', () {
      test('should return unread count successfully', () async {
        // Arrange
        const token = 'test_token';
        const expectedResponse = '''
        {
          "success": true,
          "data": [
            {"id": 1, "read_at": null},
            {"id": 2, "read_at": null},
            {"id": 3, "read_at": null}
          ]
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await service.getUnreadCount();

        // Assert
        expect(result, 3);
      });

      test('should return 0 when no unread notifications', () async {
        // Arrange
        const token = 'test_token';
        const expectedResponse = '''
        {
          "success": true,
          "data": []
        }
        ''';

        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(expectedResponse, 200));

        // Act
        final result = await service.getUnreadCount();

        // Assert
        expect(result, 0);
      });

      test('should return 0 when API call fails', () async {
        // Arrange
        const token = 'test_token';
        when(mockStorage.read(key: 'token')).thenAnswer((_) async => token);
        when(mockClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('{"error": "Server error"}', 500));

        // Act
        final result = await service.getUnreadCount();

        // Assert
        expect(result, 0);
      });
    });

    group('WebSocket Integration', () {
      test('should handle new notification from WebSocket', () {
        // Arrange
        final notificationData = {
          'id': 1,
          'title': 'WebSocket Notification',
          'body': 'This is a test notification',
          'type': 'system',
        };

        // Act
        service._handleNewNotification(notificationData);

        // Assert
        expect(service.notifications.length, 1);
        expect(service.notifications[0]['title'], 'WebSocket Notification');
        expect(service.notifications[0]['type'], 'system');
      });

      test('should handle order created from WebSocket', () {
        // Arrange
        final orderData = {
          'id': 123,
          'total': 25.50,
        };

        // Act
        service._handleOrderCreated(orderData);

        // Assert
        expect(service.notifications.length, 1);
        expect(service.notifications[0]['title'], 'Nueva Orden Recibida');
        expect(service.notifications[0]['type'], 'order');
        expect(service.notifications[0]['body'], contains('orden #123'));
        expect(service.notifications[0]['body'], contains('\$25.50'));
      });

      test('should handle order status changed from WebSocket', () {
        // Arrange
        final statusData = {
          'order_id': 123,
          'new_status': 'preparing',
        };

        // Act
        service._handleOrderStatusChanged(statusData);

        // Assert
        expect(service.notifications.length, 1);
        expect(service.notifications[0]['title'], 'Estado de Orden Actualizado');
        expect(service.notifications[0]['type'], 'order_status');
        expect(service.notifications[0]['body'], contains('orden #123'));
        expect(service.notifications[0]['body'], contains('En Preparación'));
      });

      test('should handle payment validated from WebSocket', () {
        // Arrange
        final paymentData = {
          'order_id': 123,
          'is_valid': true,
        };

        // Act
        service._handlePaymentValidated(paymentData);

        // Assert
        expect(service.notifications.length, 1);
        expect(service.notifications[0]['title'], 'Pago Validado');
        expect(service.notifications[0]['type'], 'payment');
        expect(service.notifications[0]['body'], contains('orden #123'));
        expect(service.notifications[0]['body'], contains('validado'));
      });

      test('should handle payment rejected from WebSocket', () {
        // Arrange
        final paymentData = {
          'order_id': 123,
          'is_valid': false,
        };

        // Act
        service._handlePaymentValidated(paymentData);

        // Assert
        expect(service.notifications.length, 1);
        expect(service.notifications[0]['title'], 'Pago Rechazado');
        expect(service.notifications[0]['type'], 'payment');
        expect(service.notifications[0]['body'], contains('orden #123'));
        expect(service.notifications[0]['body'], contains('rechazado'));
      });

      test('should handle delivery request from WebSocket', () {
        // Arrange
        final deliveryData = {
          'order_id': 123,
        };

        // Act
        service._handleDeliveryRequest(deliveryData);

        // Assert
        expect(service.notifications.length, 1);
        expect(service.notifications[0]['title'], 'Solicitud de Delivery');
        expect(service.notifications[0]['type'], 'delivery');
        expect(service.notifications[0]['body'], contains('orden #123'));
      });

      test('should get correct status text for different statuses', () {
        // Act & Assert
        expect(service._getStatusText('pending_payment'), 'Pendiente de Pago');
        expect(service._getStatusText('paid'), 'Pagado');
        expect(service._getStatusText('preparing'), 'En Preparación');
        expect(service._getStatusText('ready'), 'Listo');
        expect(service._getStatusText('on_way'), 'En Camino');
        expect(service._getStatusText('delivered'), 'Entregado');
        expect(service._getStatusText('cancelled'), 'Cancelado');
        expect(service._getStatusText('unknown'), 'Desconocido');
      });
    });
  });
} 