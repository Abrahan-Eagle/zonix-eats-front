class CommerceProfile {
  final int id;
  final String businessName;
  final String address;
  final String phone;
  final String? logoUrl;
  final String? mobilePaymentBank;
  final String? mobilePaymentId;
  final String? mobilePaymentPhone;
  final bool open;
  final Map<String, dynamic>? schedule;

  CommerceProfile({
    required this.id,
    required this.businessName,
    required this.address,
    required this.phone,
    this.logoUrl,
    this.mobilePaymentBank,
    this.mobilePaymentId,
    this.mobilePaymentPhone,
    required this.open,
    this.schedule,
  });

  factory CommerceProfile.fromJson(Map<String, dynamic> json) {
    return CommerceProfile(
      id: json['id'] ?? 0,
      businessName: json['business_name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      logoUrl: json['image'],
      mobilePaymentBank: json['mobile_payment_bank'],
      mobilePaymentId: json['mobile_payment_id'],
      mobilePaymentPhone: json['mobile_payment_phone'],
      open: json['open'] == 1 || json['open'] == true || json['open'] == '1',
      schedule: json['schedule'],
    );
  }
} 