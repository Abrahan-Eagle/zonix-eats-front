class Phone {
  final int id;
  final int profileId;
  final int operatorCodeId;
  final String operatorCodeName;
  final String number;
  final bool isPrimary;
  final bool status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Phone({
    required this.id,
    required this.profileId,
    required this.operatorCodeId,
    required this.operatorCodeName,
    required this.number,
    required this.isPrimary,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Phone.fromJson(Map<String, dynamic> json) {
    final operatorCode = json['operator_code'] ?? {};
    return Phone(
      id: json['id'] ?? 0,
      profileId: json['profile_id'] ?? 0,
      operatorCodeId: operatorCode['id'] ?? 0,
      operatorCodeName: operatorCode['name'] ?? '',
      number: json['number'] ?? '',
      isPrimary: json['is_primary'] == 1 || json['is_primary'] == true,
      status: json['status'] == 1 || json['status'] == true,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'operator_code_id': operatorCodeId,
      'number': number,
      'is_primary': isPrimary ? 1 : 0,
      'status': status ? 1 : 0,
    };
  }

  // Método copyWith para facilitar la modificación de propiedades
  Phone copyWith({
    int? id,
    int? profileId,
    int? operatorCodeId,
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
      operatorCodeId: operatorCodeId ?? this.operatorCodeId,
      operatorCodeName: operatorCodeName ?? this.operatorCodeName,
      number: number ?? this.number,
      isPrimary: isPrimary ?? this.isPrimary,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Método para obtener el número completo con código de operador
  String get fullNumber => '$operatorCodeName $number';

  // Método para validar el formato del número
  bool get isValidNumber => number.length == 7 && int.tryParse(number) != null;

  // Método para obtener el estado como texto
  String get statusText => status ? 'Activo' : 'Inactivo';

  // Método para obtener el tipo como texto
  String get typeText => isPrimary ? 'Principal' : 'Secundario';

  // Método para obtener el color del estado
  int get statusColor => status ? 0xFF4CAF50 : 0xFFF44336;

  // Método para obtener el color del tipo
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
    return 'Phone(id: $id, number: $fullNumber, isPrimary: $isPrimary, status: $status)';
  }
}
