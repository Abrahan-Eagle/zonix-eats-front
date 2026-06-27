/// Persistencia del índice de bottom nav por rol (Zonix Glasses).
library bottom_nav_persistence;

String bottomNavStorageKey(String role) {
  final keyRole = role.isEmpty ? 'user' : role;
  return 'bottomNavIndex_$keyRole';
}

int defaultLevelForRole(String role) {
  switch (role) {
    case 'admin':
      return 1;
    case 'user':
    default:
      return 0;
  }
}

List<int> levelsForRole(String role) {
  switch (role) {
    case 'admin':
      return [1];
    case 'user':
    default:
      return [0];
  }
}
