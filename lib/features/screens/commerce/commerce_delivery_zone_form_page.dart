import 'package:flutter/material.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommerceDeliveryZoneFormPage extends StatefulWidget {
  const CommerceDeliveryZoneFormPage({
    super.key,
    this.zoneId,
  });

  final int? zoneId;

  @override
  State<CommerceDeliveryZoneFormPage> createState() =>
      _CommerceDeliveryZoneFormPageState();
}

class _CommerceDeliveryZoneFormPageState
    extends State<CommerceDeliveryZoneFormPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.zoneId == null ? 'Nueva zona' : 'Editar zona',
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 64, color: AppColors.blue),
              SizedBox(height: 24),
              Text(
                'Zonas de delivery',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Las zonas de entrega son configuradas por el administrador de la plataforma. '
                'Para agregar o modificar zonas de delivery, contacta con soporte.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
