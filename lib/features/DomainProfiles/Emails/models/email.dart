class Email {
  final int id;
  final int profileId;
  final String email;
  final bool isPrimary;
  final bool status;

  Email({
    required this.id,
    required this.profileId,
    required this.email,
    required this.isPrimary,
    required this.status,
  });

  // Crear una instancia desde JSON
  factory Email.fromJson(Map<String, dynamic> json) {
    return Email(
      id: json['id'],
      profileId: json['profile_id'],
      email: json['email'],
      isPrimary: (json['is_primary'] == 1), // Conversión explícita
      status: (json['status'] == 1), // Conversión explícita
    );
  }

  // Convertir a JSON para enviar datos a la API
  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'email': email,
      'is_primary': isPrimary ? 1 : 0, // Enviar como 1 o 0
      'status': status ? 1 : 0, // Enviar como 1 o 0
    };
  }
}



extension EmailCopyWith on Email {
  Email copyWith({
    int? id,
    int? profileId,
    String? email,
    bool? isPrimary,
    bool? status,
  }) {
    return Email(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      email: email ?? this.email,
      isPrimary: isPrimary ?? this.isPrimary,
      status: status ?? this.status,
    );
  }
}
