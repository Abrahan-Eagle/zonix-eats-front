/// Modelo para comercios del usuario (respuesta de GET /api/commerce/commerces)
class MyCommerce {
  final int id;
  final int profileId;
  final bool isPrimary;
  final String businessName;
  final String? businessType;
  final String? taxId;
  final String? image;
  final String? address;
  final bool open;
  final dynamic schedule;

  MyCommerce({
    required this.id,
    required this.profileId,
    required this.isPrimary,
    required this.businessName,
    this.businessType,
    this.taxId,
    this.image,
    this.address,
    this.open = false,
    this.schedule,
  });

  factory MyCommerce.fromJson(Map<String, dynamic> json) {
    return MyCommerce(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      profileId: json['profile_id'] is int ? json['profile_id'] : int.tryParse(json['profile_id']?.toString() ?? '0') ?? 0,
      isPrimary: json['is_primary'] == true || json['is_primary'] == 1,
      businessName: json['business_name']?.toString() ?? '',
      businessType: json['business_type']?.toString(),
      taxId: json['tax_id']?.toString(),
      image: json['image']?.toString(),
      address: json['address']?.toString(),
      open: json['open'] == true || json['open'] == 1,
      schedule: json['schedule'],
    );
  }
}
