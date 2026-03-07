import 'package:zonix/features/utils/rif_formatter.dart';

class Document {
  final int id;
  final String? type;
  final String? numberCi; // CI: número de cédula (solo dígitos)
  /// RIF completo Venezuela: X-NNNNNNNN-N (ej. J-19217553-0)
  final String? rifNumber;
  final String? taxDomicile;
  final String? frontImage;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final bool approved;
  final bool status;

  /// RIF formateado para mostrar: J-19217553-0, V-19217553-0, etc.
  String? get formattedRifNumber => formatRifDisplay(rifNumber);

  Document({
    required this.id,
    this.type,
    this.numberCi,
    this.rifNumber,
    this.taxDomicile,
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
      rifNumber: json['rif_number']?.toString(),
      taxDomicile: json['taxDomicile'],
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

