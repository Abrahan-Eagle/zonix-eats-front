class Address {
  final int? id;
  final String street;
  final String houseNumber;
  final String postalCode;
  final double latitude;
  final double longitude;
  final String status;
  final int profileId;
  final int cityId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Address({
    this.id,
    required this.street,
    required this.houseNumber,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.profileId,
    required this.cityId,
    this.createdAt,
    this.updatedAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      street: json['street'] ?? '',
      houseNumber: json['house_number'] ?? '',
      postalCode: json['postal_code'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      status: json['status'] ?? 'notverified',
      profileId: json['profile_id'] ?? 0,
      cityId: json['city_id'] ?? 0,
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
      'id': id,
      'street': street,
      'house_number': houseNumber,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'profile_id': profileId,
      'city_id': cityId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Address copyWith({
    int? id,
    String? street,
    String? houseNumber,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? status,
    int? profileId,
    int? cityId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      street: street ?? this.street,
      houseNumber: houseNumber ?? this.houseNumber,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      profileId: profileId ?? this.profileId,
      cityId: cityId ?? this.cityId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Métodos útiles
  String get fullAddress => '$street, $houseNumber';
  
  String get coordinates => '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  
  bool get isValidCoordinates => 
      latitude >= -90 && latitude <= 90 && 
      longitude >= -180 && longitude <= 180;
  
  bool get isComplete => 
      street.isNotEmpty && 
      houseNumber.isNotEmpty && 
      postalCode.isNotEmpty && 
      isValidCoordinates;
  
  bool get isVerified => status == 'completeData';
  
  bool get isIncomplete => status == 'incompleteData';
  
  bool get isNotVerified => status == 'notverified';
  
  String get statusDisplayText {
    switch (status) {
      case 'completeData':
        return 'Datos Completos';
      case 'incompleteData':
        return 'Datos Incompletos';
      case 'notverified':
        return 'No Verificado';
      default:
        return 'Estado Desconocido';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        other.id == id &&
        other.street == street &&
        other.houseNumber == houseNumber &&
        other.postalCode == postalCode &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.status == status &&
        other.profileId == profileId &&
        other.cityId == cityId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      street,
      houseNumber,
      postalCode,
      latitude,
      longitude,
      status,
      profileId,
      cityId,
    );
  }

  @override
  String toString() {
    return 'Address(id: $id, street: $street, houseNumber: $houseNumber, postalCode: $postalCode, latitude: $latitude, longitude: $longitude, status: $status, profileId: $profileId, cityId: $cityId)';
  }
}
