/// Formato RIF Venezuela: X-NNNNNNNN-N (ej. J-19217553-0, V-19217553-0).
/// Acepta entrada con o sin guiones y devuelve siempre el formato estándar.
String? formatRifDisplay(String? value) {
  if (value == null) return null;
  final raw = value.trim().toUpperCase();
  if (raw.isEmpty) return null;
  // Una letra (V,E,J,G,P) + 8 dígitos + 1 dígito (opcionalmente con guiones/espacios)
  final match = RegExp(r'^([VEJGP])[\s\-]*(\d{8})[\s\-]*(\d)$').firstMatch(raw);
  if (match != null) {
    return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
  }
  return raw;
}
