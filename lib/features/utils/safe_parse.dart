/// Helpers de parseo defensivo para valores JSON que pueden llegar como
/// num, String o null desde el backend Laravel (DECIMAL → string, etc.).
///
/// Usar en vez de `as int`, `as num`, `as double` sobre datos de API.
library safe_parse;

double safeDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

int safeInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String safeString(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  if (v is String) return v;
  return v.toString();
}

/// Convierte una List<dynamic> de valores numericos (num o String) a List<double>.
List<double> safeDoubleList(dynamic v) {
  if (v is! List) return [];
  return v.map((e) => safeDouble(e)).toList();
}

/// Convierte una List<dynamic> a List<String> de forma segura.
List<String> safeStringList(dynamic v) {
  if (v is! List) return [];
  return v.map((e) => safeString(e)).toList();
}
