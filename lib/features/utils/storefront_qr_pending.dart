import 'package:shared_preferences/shared_preferences.dart';

/// Persiste el [commerceId] escaneado cuando aún no hay sesión buyer para abrir el catálogo.
class StorefrontQrPending {
  static const String _key = 'pending_storefront_commerce_id';

  static Future<void> save(int commerceId) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_key, commerceId);
  }

  static Future<int?> consume() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getInt(_key);
    if (id != null) {
      await p.remove(_key);
    }
    return id;
  }

  static Future<int?> peek() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_key);
  }
}
