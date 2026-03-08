/// Contextos de uso del teléfono (backend: personal, commerce, delivery_company, admin).
class PhoneContext {
  static const String personal = 'personal';
  static const String commerce = 'commerce';
  static const String deliveryCompany = 'delivery_company';
  static const String admin = 'admin';

  static List<String> get values => [personal, commerce, deliveryCompany, admin];

  static String label(String context) {
    switch (context) {
      case personal:
        return 'Personal';
      case commerce:
        return 'Comercio';
      case deliveryCompany:
        return 'Empresa de delivery';
      case admin:
        return 'Admin';
      default:
        return context;
    }
  }

  /// Contextos permitidos según el rol del usuario (tabla users.role).
  /// users: solo personal (no se muestra selector). commerce: personal + comercio. etc.
  static List<String> contextsForRole(String role) {
    switch (role) {
      case 'commerce':
        return [personal, commerce];
      case 'delivery_company':
        return [personal, deliveryCompany];
      case 'admin':
        return [personal, admin];
      case 'users':
      case 'delivery_agent':
      case 'delivery':
      default:
        return [personal];
    }
  }

  /// Si el rol debe ver el selector "Uso del teléfono". users/delivery_agent/delivery no.
  static bool showContextDropdownForRole(String role) {
    return role.isNotEmpty &&
        ['commerce', 'delivery_company', 'admin'].contains(role);
  }
}

class Phone {
  final int id;
  final int profileId;
  /// Uso del número: personal, commerce, delivery_company, admin.
  final String context;
  final int? commerceId;
  final int? deliveryCompanyId;
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
    this.commerceId,
    this.deliveryCompanyId,
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
    final commerceIdVal = json['commerce_id'];
    final deliveryCompanyIdVal = json['delivery_company_id'];
    return Phone(
      id: json['id'] ?? 0,
      profileId: json['profile_id'] ?? 0,
      context: (json['context'] ?? PhoneContext.personal).toString(),
      commerceId: commerceIdVal != null ? int.tryParse(commerceIdVal.toString()) : null,
      deliveryCompanyId: deliveryCompanyIdVal != null ? int.tryParse(deliveryCompanyIdVal.toString()) : null,
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
    final map = <String, dynamic>{
      'context': context,
      'operator_code_id': operatorCodeId,
      'number': number,
      'is_primary': isPrimary ? 1 : 0,
      'status': status ? 1 : 0,
    };
    if (commerceId != null) map['commerce_id'] = commerceId;
    if (deliveryCompanyId != null) map['delivery_company_id'] = deliveryCompanyId;
    return map;
  }

  Phone copyWith({
    int? id,
    int? profileId,
    String? context,
    int? commerceId,
    int? deliveryCompanyId,
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
      commerceId: commerceId ?? this.commerceId,
      deliveryCompanyId: deliveryCompanyId ?? this.deliveryCompanyId,
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

  /// Número completo para mostrar (ej. 0412 123 4567).
  String get fullNumberDisplay {
    final n = number.replaceAll(RegExp(r'\D'), '');
    if (n.length == 7) return '$operatorCode ${n.substring(0, 3)} ${n.substring(3, 5)} ${n.substring(5)}';
    return '$operatorCode$number';
  }

  /// Número sin espacios para marcar (tel:).
  String get fullNumberForDialing => '$operatorCode${number.replaceAll(RegExp(r'\D'), '')}';

  /// Número para WhatsApp (Venezuela: 58 + código sin 0 + 7 dígitos).
  String get fullNumberForWhatsApp {
    final code = operatorCode.replaceFirst(RegExp(r'^0'), '');
    final n = number.replaceAll(RegExp(r'\D'), '');
    return '58$code$n';
  }

  @Deprecated('Use fullNumberDisplay')
  String get fullNumber => '$operatorCodeName $number';

  // Método para validar el formato del número
  bool get isValidNumber => number.length == 7 && int.tryParse(number) != null;

  // Método para obtener el estado como texto
  String get statusText => status ? 'Activo' : 'Inactivo';

  // Método para obtener el tipo como texto
  String get typeText => isPrimary ? 'Principal' : 'Secundario';

  /// Etiqueta del contexto (Personal, Comercio, etc.)
  String get contextLabel => PhoneContext.label(context);

  // Colores vía Theme/AppColors en UI; estos getters se mantienen por compatibilidad pero evítalos en vistas nuevas.
  int get statusColor => status ? 0xFF4CAF50 : 0xFFF44336;
  int get typeColor => isPrimary ? 0xFF2196F3 : 0xFF9E9E9E;

  // Método para formatear la fecha de creación
  String get formattedCreatedAt {
    if (createdAt == null) return 'N/A';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  // Método para formatear la fecha de actualización
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
