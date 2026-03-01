// profile_model.dart
class Profile {
  int id;
  int userId; // Clave foránea
  String firstName;
  String middleName;
  String lastName;
  String secondLastName;
  String? photo; // Cambiado a nullable
  String dateOfBirth;
  String maritalStatus;
  String sex;
  String status; // Estado del perfil
  String? phone; // Teléfono
  String? address; // Dirección
  
  // Campos específicos para comercios
  String? businessName; // Nombre del negocio
  String? businessType; // Tipo de negocio
  String? taxId; // RFC
  
  // Campos específicos para delivery
  String? vehicleType; // Tipo de vehículo
  String? licenseNumber; // Número de licencia

  // Constructor
  Profile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.secondLastName,
    this.photo,
    required this.dateOfBirth,
    required this.maritalStatus,
    required this.sex,
    this.status = 'notverified', // Valor por defecto
    this.phone,
    this.address,
    this.businessName,
    this.businessType,
    this.taxId,
    this.vehicleType,
    this.licenseNumber,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    // Backend puede devolver { success, data } o el perfil directo; normalizar.
    final map = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    String safeStr(dynamic v) => v?.toString() ?? '';
    return Profile(
      id: map['id'] as int? ?? 0,
      userId: map['user_id'] as int? ?? 0,
      firstName: safeStr(map['firstName']),
      middleName: safeStr(map['middleName']),
      lastName: safeStr(map['lastName']),
      secondLastName: safeStr(map['secondLastName']),
      photo: map['photo_users'] ?? map['photo'],
      dateOfBirth: safeStr(map['date_of_birth']).isEmpty ? '' : safeStr(map['date_of_birth']),
      maritalStatus: safeStr(map['maritalStatus']).isEmpty ? 'single' : safeStr(map['maritalStatus']),
      sex: safeStr(map['sex']).isEmpty ? 'M' : safeStr(map['sex']),
      status: safeStr(map['status']).isEmpty ? 'notverified' : safeStr(map['status']),
      phone: map['phone']?.toString(),
      address: map['address']?.toString(),
      businessName: map['business_name']?.toString(),
      businessType: map['business_type']?.toString(),
      taxId: map['tax_id']?.toString(),
      vehicleType: map['vehicle_type']?.toString(),
      licenseNumber: map['license_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'secondLastName': secondLastName,
      'photo_users': photo,
      'date_of_birth': dateOfBirth,
      'maritalStatus': maritalStatus,
      'sex': sex,
      'status': status,
      'phone': phone,
      'address': address,
      'business_name': businessName,
      'business_type': businessType,
      'tax_id': taxId,
      'vehicle_type': vehicleType,
      'license_number': licenseNumber,
    };
  }

  // Método para crear una copia con algunos campos modificados
  Profile copyWith({
    int? id,
    int? userId,
    String? firstName,
    String? middleName,
    String? lastName,
    String? secondLastName,
    String? photo,
    String? dateOfBirth,
    String? maritalStatus,
    String? sex,
    String? status,
    String? phone,
    String? address,
    String? businessName,
    String? businessType,
    String? taxId,
    String? vehicleType,
    String? licenseNumber,
  }) {
    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      secondLastName: secondLastName ?? this.secondLastName,
      photo: photo ?? this.photo,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      sex: sex ?? this.sex,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      taxId: taxId ?? this.taxId,
      vehicleType: vehicleType ?? this.vehicleType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
    );
  }
}
