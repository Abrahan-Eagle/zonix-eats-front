/// Contextos de uso del teléfono (scaffold: personal + admin).
class PhoneContext {
  static const String personal = 'personal';
  static const String admin = 'admin';

  static List<String> get values => [personal, admin];

  static String label(String context) {
    switch (context) {
      case personal:
        return 'Personal';
      case admin:
        return 'Admin';
      default:
        return context;
    }
  }

  static List<String> contextsForRole(String role) {
    if (role == 'admin') return [personal, admin];
    return [personal];
  }

  static bool showContextDropdownForRole(String role) => role == 'admin';
}

class Phone {
  final int id;
  final int profileId;
  /// Uso del número: personal, admin.
  final String context;
  final int operatorCodeId;
  /// Código numérico del operador (ej. 0412) para marcar y WhatsApp.
  final String operatorCode;
  final String operatorCodeName;
  final String number;
  final bool isPrimary;
  final bool status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Phone({
    required this.id,
    required this.profileId,
    this.context = PhoneContext.personal,
    required this.operatorCodeId,
    String? operatorCode,
    required this.operatorCodeName,
    required this.number,
    required this.isPrimary,
    required this.status,
    this.createdAt,
    this.updatedAt,
  }) : operatorCode = operatorCode ?? '';

  factory Phone.fromJson(Map<String, dynamic> json) {
    final operatorCodeObj = json['operator_code'] ?? {};
    final code = (operatorCodeObj['code'] ?? '').toString();
    return Phone(
      id: json['id'] ?? 0,
      profileId: json['profile_id'] ?? 0,
      context: (json['context'] ?? PhoneContext.personal).toString(),
      operatorCodeId: operatorCodeObj['id'] ?? 0,
      operatorCode: code,
      operatorCodeName: operatorCodeObj['name'] ?? '',
      number: (json['number'] ?? '').toString(),
      isPrimary: json['is_primary'] == 1 || json['is_primary'] == true,
      status: json['status'] == 1 || json['status'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'context': context,
      'operator_code_id': operatorCodeId,
      'number': number,
      'is_primary': isPrimary ? 1 : 0,
      'status': status ? 1 : 0,
    };
  }

  Phone copyWith({
    int? id,
    int? profileId,
    String? context,
    int? operatorCodeId,
    String? operatorCode,
    String? operatorCodeName,
    String? number,
    bool? isPrimary,
    bool? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Phone(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      context: context ?? this.context,
      operatorCodeId: operatorCodeId ?? this.operatorCodeId,
      operatorCode: operatorCode ?? this.operatorCode,
      operatorCodeName: operatorCodeName ?? this.operatorCodeName,
      number: number ?? this.number,
      isPrimary: isPrimary ?? this.isPrimary,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullNumberDisplay {
    final n = number.replaceAll(RegExp(r'\D'), '');
    if (n.length == 7) return '$operatorCode ${n.substring(0, 3)} ${n.substring(3, 5)} ${n.substring(5)}';
    return '$operatorCode$number';
  }

  String get fullNumberForDialing => '$operatorCode${number.replaceAll(RegExp(r'\D'), '')}';

  String get fullNumberForWhatsApp {
    final code = operatorCode.replaceFirst(RegExp(r'^0'), '');
    final n = number.replaceAll(RegExp(r'\D'), '');
    return '58$code$n';
  }

  @Deprecated('Use fullNumberDisplay')
  String get fullNumber => '$operatorCodeName $number';

  bool get isValidNumber => number.length == 7 && int.tryParse(number) != null;

  String get statusText => status ? 'Activo' : 'Inactivo';

  String get typeText => isPrimary ? 'Principal' : 'Secundario';

  String get contextLabel => PhoneContext.label(context);

  int get statusColor => status ? 0xFF4CAF50 : 0xFFF44336;
  int get typeColor => isPrimary ? 0xFF2196F3 : 0xFF9E9E9E;

  String get formattedCreatedAt {
    if (createdAt == null) return 'N/A';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  String get formattedUpdatedAt {
    if (updatedAt == null) return 'N/A';
    return '${updatedAt!.day}/${updatedAt!.month}/${updatedAt!.year}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Phone && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Phone(id: $id, number: $fullNumberDisplay, isPrimary: $isPrimary, status: $status)';
  }
}
