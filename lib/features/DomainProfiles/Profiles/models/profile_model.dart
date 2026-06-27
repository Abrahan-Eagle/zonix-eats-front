// profile_model.dart
import 'package:zonix_glasses/features/utils/safe_parse.dart';

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
  List<Map<String, dynamic>>?
      addressesData; // Direcciones estructuradas desde la API

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
    this.addressesData,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    // Backend puede devolver { success, data } o el perfil directo; normalizar.
    final map = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    String safeStr(dynamic v) => v?.toString() ?? '';

    List<Map<String, dynamic>>? parsedAddresses;
    if (map['addresses'] is List) {
      parsedAddresses = List<Map<String, dynamic>>.from(
          map['addresses'].map((e) => e as Map<String, dynamic>));
    }

    return Profile(
      id: safeInt(map['id']),
      userId: safeInt(map['user_id']),
      firstName: safeStr(map['firstName']),
      middleName: safeStr(map['middleName']),
      lastName: safeStr(map['lastName']),
      secondLastName: safeStr(map['secondLastName']),
      photo: map['photo_users'] ?? map['photo'],
      dateOfBirth: safeStr(map['date_of_birth']).isEmpty
          ? ''
          : safeStr(map['date_of_birth']),
      maritalStatus: safeStr(map['maritalStatus']).isEmpty
          ? 'single'
          : safeStr(map['maritalStatus']),
      sex: safeStr(map['sex']).isEmpty ? 'M' : safeStr(map['sex']),
      status: safeStr(map['status']).isEmpty
          ? 'notverified'
          : safeStr(map['status']),
      phone: map['phone']?.toString(),
      address: map['address']?.toString(),
      addressesData: parsedAddresses,
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
      'addresses': addressesData,
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
    List<Map<String, dynamic>>? addressesData,
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
      addressesData: addressesData ?? this.addressesData,
    );
  }
}
