import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:zonix/features/services/order_service.dart';

import 'order_service_comprobante_test.mocks.dart';

@GenerateMocks([OrderService])
void main() {
  group('OrderService comprobante', () {
    late MockOrderService mockOrderService;
    setUp(() {
      mockOrderService = MockOrderService();
    });

    test('uploadComprobante llama correctamente al método', () async {
      when(mockOrderService.uploadComprobante(1, 'test.jpg', 'jpg'))
          .thenAnswer((_) async => Future.value());
      await mockOrderService.uploadComprobante(1, 'test.jpg', 'jpg');
      verify(mockOrderService.uploadComprobante(1, 'test.jpg', 'jpg')).called(1);
    });

    test('validarComprobante llama correctamente al método', () async {
      when(mockOrderService.validarComprobante(1, 'validar'))
          .thenAnswer((_) async => Future.value());
      await mockOrderService.validarComprobante(1, 'validar');
      verify(mockOrderService.validarComprobante(1, 'validar')).called(1);
    });
  });
} 