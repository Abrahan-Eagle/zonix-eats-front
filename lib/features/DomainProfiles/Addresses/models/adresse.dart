class Address {
  final int? id; // Cambia a nullable

  final String street;
  final String houseNumber;
  final String postalCode;
  final double latitude;
  final double longitude;
  final String status;
  final int profileId;
  final int cityId;

  Address({
    this.id, // No requerido
    required this.street,
    required this.houseNumber,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.profileId,
    required this.cityId,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'], // Parsear id si está presente
      street: json['street'],
      houseNumber: json['house_number'],
      postalCode: json['postal_code'],
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      status: json['status'],
      profileId: json['profile_id'],
      cityId: json['city_id'],
    );
  }
}
