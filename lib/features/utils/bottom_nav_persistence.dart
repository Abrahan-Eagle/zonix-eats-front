/// Helpers para persistencia del índice de la bottom nav por rol.
/// Usado por [MainRouter] en main.dart.
/// level 0 = users, 1 = commerce, 2 = delivery/delivery_agent, 3 = delivery_company, 4 = admin.

/// Clave de SharedPreferences para guardar el índice de la bottom nav de un rol.
/// Rol vacío se normaliza a 'users'.
String bottomNavStorageKey(String role) {
  final keyRole = role.isEmpty ? 'users' : role;
  return 'bottomNavIndex_$keyRole';
}

/// Nivel por defecto para el selector de rol en la app bar.
/// users = 0, commerce = 1, delivery/delivery_agent = 2, delivery_company = 3, admin = 4.
int defaultLevelForRole(String role) {
  switch (role) {
    case 'commerce':
      return 1;
    case 'delivery_agent':
    case 'delivery':
      return 2;
    case 'delivery_company':
      return 3;
    case 'admin':
      return 4;
    case 'users':
    default:
      return 0;
  }
}

/// Niveles permitidos para el selector según rol (cada rol solo ve su nivel).
List<int> levelsForRole(String role) {
  switch (role) {
    case 'commerce':
      return [1];
    case 'delivery_agent':
    case 'delivery':
      return [2];
    case 'delivery_company':
      return [3];
    case 'admin':
      return [4];
    case 'users':
    default:
      return [0];
  }
}
