import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/services/dispute_service.dart';

void main() {
  group('DisputeService labels', () {
    test('maps dispute status labels for buyer UI', () {
      expect(DisputeService.statusLabel('pending'), 'Pendiente');
      expect(DisputeService.statusLabel('in_review'), 'En revisión');
      expect(DisputeService.statusLabel('resolved'), 'Resuelta');
      expect(DisputeService.statusLabel('closed'), 'Cerrada');
    });

    test('maps dispute type labels for buyer UI', () {
      expect(DisputeService.typeLabel('payment_issue'), 'Problema de pago');
      expect(DisputeService.typeLabel('delivery_problem'), 'Problema de entrega');
      expect(DisputeService.typeLabel('quality_issue'), 'Problema de calidad');
      expect(DisputeService.typeLabel('other'), 'Otro');
    });
  });
}
