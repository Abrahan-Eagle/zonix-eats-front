import 'dart:convert';

class Restaurant {
  final int id;
  final int profileId;
  final String businessName;
  final String? address;
  final String? phone;
  final String? description;
  final String? image;
  final String? mobilePaymentBank;
  final String? mobilePaymentId;
  final String? mobilePaymentPhone;
  final bool open;
  final Map<String, dynamic>? schedule;
  final Map<String, dynamic>? profile;

  Restaurant({
    required this.id,
    required this.profileId,
    required this.businessName,
    required this.address,
    required this.phone,
    this.description,
    this.image,
    required this.mobilePaymentBank,
    required this.mobilePaymentId,
    required this.mobilePaymentPhone,
    required this.open,
    this.schedule,
    this.profile,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    // Manejo seguro del campo schedule (que puede venir como String JSON o como Map)
    Map<String, dynamic>? parsedSchedule;
    if (json['schedule'] != null) {
      if (json['schedule'] is String) {
        try {
          parsedSchedule = Map<String, dynamic>.from(
            jsonDecode(json['schedule'] as String)
          );
        } catch (e) {
          print('Error parsing schedule JSON: $e');
          parsedSchedule = null;
        }
      } else if (json['schedule'] is Map) {
        parsedSchedule = Map<String, dynamic>.from(json['schedule'] as Map);
      }
    }

    return Restaurant(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      profileId: json['profile_id'] is int ? json['profile_id'] : int.tryParse(json['profile_id'].toString()) ?? 0,
      businessName: json['business_name']?.toString() ?? '',
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      mobilePaymentBank: json['mobile_payment_bank']?.toString() ?? '',
      mobilePaymentId: json['mobile_payment_id']?.toString() ?? '',
      mobilePaymentPhone: json['mobile_payment_phone']?.toString() ?? '',
      open: json['open'] == 1 || json['open'] == true || json['open'] == '1',
      schedule: parsedSchedule,
      profile: json['profile'] is Map ? Map<String, dynamic>.from(json['profile'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'business_name': businessName,
      'address': address,
      'phone': phone,
      'description': description,
      'image': image,
      'mobile_payment_bank': mobilePaymentBank,
      'mobile_payment_id': mobilePaymentId,
      'mobile_payment_phone': mobilePaymentPhone,
      'open': open,
      'schedule': schedule,
      'profile': profile,
    };
  }

  // Getters para compatibilidad con el código existente
  String get nombreLocal => businessName;
  String get direccion => address ?? '';
  String get telefono => phone ?? '';
  String get descripcion => description ?? '';
  String get logoUrl => image ?? '';
  String get pagoMovilBanco => mobilePaymentBank ?? '';
  String get pagoMovilCedula => mobilePaymentId ?? '';
  String get pagoMovilTelefono => mobilePaymentPhone ?? '';
  bool get abierto => open;
  Map<String, dynamic>? get horario => schedule;

  @override
  String toString() {
    return 'Restaurant(id: $id, businessName: $businessName, open: $open)';
  }
}