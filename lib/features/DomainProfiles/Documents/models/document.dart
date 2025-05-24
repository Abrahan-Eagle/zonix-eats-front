class Document {
  final int id;
  final String? type;
  final String? numberCi; // Campo específico para 'ci'
  final int? receiptN;
  final String? rifUrl;
  final String? taxDomicile;
  final int? sky; // Campo específico para 'rif'
  final String? communeRegister; // Campo específico para 'neighborhood_association'
  final String? communityRif; // Campo específico para 'neighborhood_association'
  final String? frontImage;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final bool approved;
  final bool status;

  Document({
    required this.id,
    this.type,
    this.numberCi,
    this.receiptN,
    this.rifUrl,
    this.taxDomicile,
    this.sky,
    this.communeRegister,
    this.communityRif,
    this.frontImage,
    this.issuedAt,
    this.expiresAt,
    required this.approved,
    required this.status,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      type: json['type']?.toString(),
      numberCi: json['type'] == 'ci' ? json['number_ci']?.toString() : null,
      receiptN: json['RECEIPT_N'],
      rifUrl: json['rif_url'],
      taxDomicile: json['taxDomicile'],
      sky: json['sky'],
      communeRegister: json['commune_register'],
      communityRif: json['community_rif'],
      frontImage: json['front_image'],
      issuedAt: json['issued_at'] != null ? DateTime.parse(json['issued_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      approved: json['approved'] ?? false,
      status: json['status'] ?? false,
    );
  }

  // Método para obtener el estado en formato String
  String getApprovedStatus() {
    return approved ? 'approved' : 'pending';
  }
}








// class Document {
//   final int id;
//   final String? type;
//   final int? count;
//   final String? number;
//   final int? receiptN;
//   final String? rifUrl;
//   final String? taxDomicile;
//   final String? frontImage;
//   final String? backImage;
//   final DateTime? issuedAt;
//   final DateTime? expiresAt;
//   final bool approved;
//   final bool status;
//   // final Profile profile;

//   Document({
//     required this.id,
//     this.type,
//     this.count,
//     this.number,
//     this.receiptN,
//     this.rifUrl,
//     this.taxDomicile,
//     this.frontImage,
//     this.backImage,
//     this.issuedAt,
//     this.expiresAt,
//     required this.approved,
//     required this.status,
//     // required this.profile,
//   });

//   factory Document.fromJson(Map<String, dynamic> json) {
//     return Document(
//       id: json['id'],
//       type: json['type']?.toString(),
//       count: json['count'],
//       number: json['number']?.toString(),
//       receiptN: json['RECEIPT_N'],
//       rifUrl: json['rif_url'],
//       taxDomicile: json['taxDomicile'],
//       frontImage: json['front_image'],
//       backImage: json['back_image'],
//       issuedAt: json['issued_at'] != null ? DateTime.parse(json['issued_at']) : null,
//       expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
//       approved: json['approved'] ?? false,
//       status: json['status'] ?? false,
//       // profile: Profile.fromJson(json['profile']),
//     );
//   }

//   // Método para obtener el estado en formato String
//   String getApprovedStatus() {
//     return approved ? 'approved' : 'pending';
//   }
// }

