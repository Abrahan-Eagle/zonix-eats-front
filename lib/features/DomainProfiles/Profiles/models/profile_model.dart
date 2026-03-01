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
    return Profile(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['firstName'],
      middleName: json['middleName'],
      lastName: json['lastName'],
      secondLastName: json['secondLastName'],
      photo: json['photo_users'] ?? json['photo'],
      dateOfBirth: json['date_of_birth'],
      maritalStatus: json['maritalStatus'],
      sex: json['sex'],
      status: json['status'] ?? 'notverified',
      phone: json['phone'],
      address: json['address'],
      businessName: json['business_name'],
      businessType: json['business_type'],
      taxId: json['tax_id'],
      vehicleType: json['vehicle_type'],
      licenseNumber: json['license_number'],
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
