import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zonix_glasses/features/utils/bottom_nav_persistence.dart';

void main() {
  group('bottomNavStorageKey', () {
    test('rol vacío devuelve clave para user', () {
      expect(bottomNavStorageKey(''), 'bottomNavIndex_user');
    });

    test('rol user devuelve clave correcta', () {
      expect(bottomNavStorageKey('user'), 'bottomNavIndex_user');
    });

    test('rol admin devuelve clave correcta', () {
      expect(bottomNavStorageKey('admin'), 'bottomNavIndex_admin');
    });

    test('cada rol tiene clave distinta (persistencia por rol)', () {
      final keys = ['user', 'admin', 'custom']
          .map((r) => bottomNavStorageKey(r))
          .toSet();
      expect(keys.length, 3);
    });
  });

  group('defaultLevelForRole', () {
    test('user tiene level 0', () {
      expect(defaultLevelForRole('user'), 0);
    });

    test('admin tiene level 1', () {
      expect(defaultLevelForRole('admin'), 1);
    });

    test('rol vacío o desconocido devuelve 0', () {
      expect(defaultLevelForRole(''), 0);
      expect(defaultLevelForRole('unknown'), 0);
    });
  });

  group('levelsForRole', () {
    test('user solo tiene nivel 0', () {
      expect(levelsForRole('user'), [0]);
    });

    test('admin solo tiene nivel 1', () {
      expect(levelsForRole('admin'), [1]);
    });

    test('rol vacío o desconocido devuelve [0]', () {
      expect(levelsForRole(''), [0]);
      expect(levelsForRole('unknown'), [0]);
    });
  });

  group('Persistencia con SharedPreferences (integración)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('guardar y leer índice por rol admin', () async {
      final prefs = await SharedPreferences.getInstance();
      final key = bottomNavStorageKey('admin');
      await prefs.setInt(key, 2);
      expect(prefs.getInt(key), 2);
    });

    test('guardar índices distintos por rol no se pisan', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(bottomNavStorageKey('user'), 0);
      await prefs.setInt(bottomNavStorageKey('admin'), 1);
      expect(prefs.getInt(bottomNavStorageKey('user')), 0);
      expect(prefs.getInt(bottomNavStorageKey('admin')), 1);
    });

    test('clave inexistente devuelve null (app usará 0 por defecto)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(bottomNavStorageKey('admin')), isNull);
    });
  });
}
