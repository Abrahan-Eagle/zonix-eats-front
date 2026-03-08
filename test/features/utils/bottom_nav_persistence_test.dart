import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zonix/features/utils/bottom_nav_persistence.dart';

void main() {
  group('bottomNavStorageKey', () {
    test('rol vacío devuelve clave para users', () {
      expect(bottomNavStorageKey(''), 'bottomNavIndex_users');
    });

    test('rol users devuelve clave correcta', () {
      expect(bottomNavStorageKey('users'), 'bottomNavIndex_users');
    });

    test('rol commerce devuelve clave correcta', () {
      expect(bottomNavStorageKey('commerce'), 'bottomNavIndex_commerce');
    });

    test('rol delivery devuelve clave correcta', () {
      expect(bottomNavStorageKey('delivery'), 'bottomNavIndex_delivery');
    });

    test('rol delivery_agent devuelve clave correcta', () {
      expect(bottomNavStorageKey('delivery_agent'), 'bottomNavIndex_delivery_agent');
    });

    test('cada rol tiene clave distinta (persistencia por rol)', () {
      final keys = ['users', 'commerce', 'delivery', 'delivery_agent', 'delivery_company', 'admin']
          .map((r) => bottomNavStorageKey(r))
          .toSet();
      expect(keys.length, 6);
    });
  });

  group('defaultLevelForRole', () {
    test('users tiene level 0', () {
      expect(defaultLevelForRole('users'), 0);
    });

    test('commerce tiene level 1', () {
      expect(defaultLevelForRole('commerce'), 1);
    });

    test('delivery y delivery_agent tienen level 2', () {
      expect(defaultLevelForRole('delivery'), 2);
      expect(defaultLevelForRole('delivery_agent'), 2);
    });

    test('delivery_company tiene level 3', () {
      expect(defaultLevelForRole('delivery_company'), 3);
    });

    test('admin tiene level 4', () {
      expect(defaultLevelForRole('admin'), 4);
    });

    test('rol vacío o desconocido devuelve 0', () {
      expect(defaultLevelForRole(''), 0);
      expect(defaultLevelForRole('unknown'), 0);
    });
  });

  group('levelsForRole', () {
    test('users solo tiene nivel 0', () {
      expect(levelsForRole('users'), [0]);
    });

    test('commerce solo tiene nivel 1', () {
      expect(levelsForRole('commerce'), [1]);
    });

    test('delivery y delivery_agent solo tienen nivel 2', () {
      expect(levelsForRole('delivery'), [2]);
      expect(levelsForRole('delivery_agent'), [2]);
    });

    test('delivery_company solo tiene nivel 3', () {
      expect(levelsForRole('delivery_company'), [3]);
    });

    test('admin solo tiene nivel 4', () {
      expect(levelsForRole('admin'), [4]);
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

    test('guardar y leer índice por rol commerce', () async {
      final prefs = await SharedPreferences.getInstance();
      final key = bottomNavStorageKey('commerce');
      await prefs.setInt(key, 2);
      expect(prefs.getInt(key), 2);
    });

    test('guardar índices distintos por rol no se pisan', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(bottomNavStorageKey('users'), 0);
      await prefs.setInt(bottomNavStorageKey('commerce'), 1);
      expect(prefs.getInt(bottomNavStorageKey('users')), 0);
      expect(prefs.getInt(bottomNavStorageKey('commerce')), 1);
    });

    test('clave inexistente devuelve null (app usará 0 por defecto)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(bottomNavStorageKey('commerce')), isNull);
    });
  });
}
