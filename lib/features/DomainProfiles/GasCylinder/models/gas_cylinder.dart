class GasCylinder {
  final String gasCylinderCode;
  final int? cylinderQuantity;
  final String? cylinderType;
  final String? cylinderWeight;
  final DateTime? manufacturingDate;
  final bool approved;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? companySupplierId;
  final String? photoGasCylinder; // Nuevo campo agregado

  GasCylinder({
    required this.gasCylinderCode,
    this.cylinderQuantity,
    this.cylinderType,
    this.cylinderWeight,
    this.manufacturingDate,
    this.approved = false,
    this.createdAt,
    this.updatedAt,
    this.companySupplierId,
    this.photoGasCylinder, // Inicialización del nuevo campo
  });

  // Método para crear una instancia desde JSON
  factory GasCylinder.fromJson(Map<String, dynamic> json) {
    return GasCylinder(
      gasCylinderCode: json['gas_cylinder_code'],
      cylinderQuantity: json['cylinder_quantity'],
      cylinderType: json['cylinder_type'],
      cylinderWeight: json['cylinder_weight'],
      manufacturingDate: json['manufacturing_date'] != null
          ? DateTime.parse(json['manufacturing_date'])
          : null,
      approved: json['approved'] == 1 || json['approved'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      companySupplierId: json['company_supplier_id'],
      photoGasCylinder: json['photo_gas_cylinder'], // Asignación del nuevo campo
    );
  }

  // Método para convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'gas_cylinder_code': gasCylinderCode,
      'cylinder_quantity': cylinderQuantity,
      'cylinder_type': cylinderType,
      'cylinder_weight': cylinderWeight,
      'manufacturing_date': manufacturingDate?.toIso8601String(),
      'approved': approved ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'company_supplier_id': companySupplierId,
      'photo_gas_cylinder': photoGasCylinder, // Conversión del nuevo campo
    };
  }
}
