import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/admin/admin_orders_page.dart';
import 'package:zonix/features/services/admin_service.dart';

class _FakeAdminService extends AdminService {
  @override
  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    String? status,
    int? commerceId,
  }) async {
    return {
      'success': true,
      'data': {
        'items': [
          {
            'id': 101,
            'status': 'paid',
            'total': 25.5,
            'delivery_fee': 2.0,
            'created_at': '2026-04-01T10:00:00Z',
            'commerce': {'business_name': 'Burger House'},
            'profile': {'first_name': 'Ana', 'last_name': 'Pérez'},
          }
        ],
        'pagination': {
          'current_page': page,
          'last_page': 1,
          'per_page': 15,
          'total': 1,
        }
      }
    };
  }
}

void main() {
  testWidgets('AdminOrdersPage renderiza orden desde envelope canónico', (tester) async {
    final service = _FakeAdminService();

    await tester.pumpWidget(
      ChangeNotifierProvider<AdminService>.value(
        value: service,
        child: const MaterialApp(
          home: AdminOrdersPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Burger House'), findsOneWidget);
    expect(find.text('Pagado'), findsNWidgets(2));
    expect(find.textContaining('\$25.50'), findsOneWidget);
  });
}

