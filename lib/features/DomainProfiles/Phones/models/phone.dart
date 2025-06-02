class Phone {
  final int id;
  final int profileId;
  final int operatorCodeId;
  final String operatorCodeName;
  final String number;
  final bool isPrimary;
  final bool status;

  Phone({
    required this.id,
    required this.profileId,
    required this.operatorCodeId,
    required this.operatorCodeName,
    required this.number,
    required this.isPrimary,
    required this.status,
  });

  factory Phone.fromJson(Map<String, dynamic> json) {
    final operatorCode = json['operator_code'] ?? {};
    return Phone(
      id: json['id'] ?? 0,
      profileId: json['profile_id'] ?? 0,
      operatorCodeId: operatorCode['id'] ?? 0,
      operatorCodeName: operatorCode['name'] ?? '',
      number: json['number'] ?? '',
      isPrimary: json['is_primary'] == 1,
      status: json['status'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'operator_code_id': operatorCodeId,
      'operator_code_name': operatorCodeName,
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
  }) {
    return Phone(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      operatorCodeId: operatorCodeId ?? this.operatorCodeId,
      operatorCodeName: operatorCodeName ?? this.operatorCodeName,
      number: number ?? this.number,
      isPrimary: isPrimary ?? this.isPrimary,
      status: status ?? this.status,
    );
  }
}
