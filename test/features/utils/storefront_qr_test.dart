import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zonix/features/utils/storefront_qr_parser.dart';
import 'package:zonix/features/utils/storefront_qr_pending.dart';

void main() {
  group('StorefrontQrParser', () {
    test('empty and whitespace are invalid', () {
      expect(StorefrontQrParser.parse('').kind, StorefrontQrKind.invalid);
      expect(StorefrontQrParser.parse('   ').kind, StorefrontQrKind.invalid);
    });

    test('pickup and delivery deep links are order QR, not commerce', () {
      final p = StorefrontQrParser.parse('zonix://pickup/99');
      expect(p.kind, StorefrontQrKind.orderPickupOrDelivery);
      expect(p.commerceId, isNull);

      final d = StorefrontQrParser.parse('zonix://delivery/12');
      expect(d.kind, StorefrontQrKind.orderPickupOrDelivery);
    });

    test('zonix://restaurant/{id} string prefix', () {
      final a = StorefrontQrParser.parse('zonix://restaurant/42');
      expect(a.kind, StorefrontQrKind.commerce);
      expect(a.commerceId, 42);

      final b = StorefrontQrParser.parse('zonix://restaurant/7?x=1');
      expect(b.commerceId, 7);

      final extra = StorefrontQrParser.parse('zonix://restaurant/7/extra');
      expect(extra.commerceId, 7);
    });

    test('zonix URI with host restaurant', () {
      final p = StorefrontQrParser.parse('zonix://restaurant/100');
      expect(p.kind, StorefrontQrKind.commerce);
      expect(p.commerceId, 100);
    });

    test('https URL with path /r/{id}', () {
      final p = StorefrontQrParser.parse('https://api.example.com/r/15');
      expect(p.kind, StorefrontQrKind.commerce);
      expect(p.commerceId, 15);
    });

    test('https URL with /foo/r/{id}/bar segment pair', () {
      final p = StorefrontQrParser.parse('https://host/x/r/88/y');
      expect(p.commerceId, 88);
    });

    test('invalid id yields invalid', () {
      expect(StorefrontQrParser.parse('zonix://restaurant/0').kind,
          StorefrontQrKind.invalid);
      expect(StorefrontQrParser.parse('zonix://restaurant/-1').kind,
          StorefrontQrKind.invalid);
    });

    test('unrecognized text is invalid', () {
      expect(StorefrontQrParser.parse('hello world').kind, StorefrontQrKind.invalid);
    });
  });

  group('StorefrontQrPending', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('save then consume returns id and clears', () async {
      await StorefrontQrPending.save(33);
      expect(await StorefrontQrPending.peek(), 33);
      expect(await StorefrontQrPending.consume(), 33);
      expect(await StorefrontQrPending.peek(), isNull);
      expect(await StorefrontQrPending.consume(), isNull);
    });

    test('peek without save is null', () async {
      expect(await StorefrontQrPending.peek(), isNull);
    });
  });
}
