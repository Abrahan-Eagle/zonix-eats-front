import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/utils/rif_formatter.dart';

void main() {
  group('formatRifDisplay', () {
    test('returns null for null or empty', () {
      expect(formatRifDisplay(null), isNull);
      expect(formatRifDisplay(''), isNull);
    });

    test('formats RIF with hyphens to standard form', () {
      expect(formatRifDisplay('J-19217553-0'), equals('J-19217553-0'));
      expect(formatRifDisplay('V-19217553-0'), equals('V-19217553-0'));
    });

    test('formats RIF without hyphens to standard form', () {
      expect(formatRifDisplay('J192175530'), equals('J-19217553-0'));
      expect(formatRifDisplay('V192175530'), equals('V-19217553-0'));
    });

    test('accepts lowercase and returns uppercase', () {
      expect(formatRifDisplay('j192175530'), equals('J-19217553-0'));
    });

    test('returns raw when pattern does not match', () {
      expect(formatRifDisplay('INVALID'), equals('INVALID'));
    });
  });
}
