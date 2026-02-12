import 'package:flutter/material.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommerceDeliveryZoneFormPage extends StatefulWidget {
  const CommerceDeliveryZoneFormPage({
    Key? key,
    this.zoneId,
  }) : super(key: key);

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 64, color: AppColors.blue),
              const SizedBox(height: 24),
              const Text(
                'Zonas de delivery',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
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
