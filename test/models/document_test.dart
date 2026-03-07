import 'package:flutter_test/flutter_test.dart';
import 'package:zonix/features/DomainProfiles/Documents/models/document.dart';

void main() {
  group('Document', () {
    test('fromJson parses CI document', () {
      final json = {
        'id': 1,
        'type': 'ci',
        'number_ci': 12345678,
        'rif_number': null,
        'taxDomicile': null,
        'front_image': null,
        'issued_at': '2020-01-01',
        'expires_at': '2030-01-01',
        'approved': false,
        'status': true,
      };
      final doc = Document.fromJson(json);
      expect(doc.id, 1);
      expect(doc.type, 'ci');
      expect(doc.numberCi, '12345678');
      expect(doc.rifNumber, isNull);
      expect(doc.approved, false);
      expect(doc.status, true);
    });

    test('fromJson parses RIF document', () {
      final json = {
        'id': 2,
        'type': 'rif',
        'number_ci': null,
        'rif_number': 'J-19217553-0',
        'taxDomicile': 'Caracas',
        'front_image': 'documents/front/1.jpg',
        'issued_at': null,
        'expires_at': null,
        'approved': true,
        'status': true,
      };
      final doc = Document.fromJson(json);
      expect(doc.id, 2);
      expect(doc.type, 'rif');
      expect(doc.rifNumber, 'J-19217553-0');
      expect(doc.taxDomicile, 'Caracas');
      expect(doc.approved, true);
    });

    test('formattedRifNumber returns formatted RIF', () {
      final doc = Document(
        id: 1,
        type: 'rif',
        rifNumber: 'J192175530',
        approved: false,
        status: true,
      );
      expect(doc.formattedRifNumber, 'J-19217553-0');
    });

    test('formattedRifNumber returns null when rifNumber is null', () {
      final doc = Document(
        id: 1,
        type: 'ci',
        approved: false,
        status: true,
      );
      expect(doc.formattedRifNumber, isNull);
    });

    test('getApprovedStatus returns approved or pending', () {
      expect(
        Document(id: 1, approved: true, status: true).getApprovedStatus(),
        'approved',
      );
      expect(
        Document(id: 1, approved: false, status: true).getApprovedStatus(),
        'pending',
      );
    });
  });
}
