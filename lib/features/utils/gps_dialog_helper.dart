import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zonix/features/utils/app_colors.dart';

bool _dialogShownThisSession = false;

/// Muestra un AlertDialog pidiendo al usuario activar la ubicación.
/// Solo se muestra una vez por sesión para no ser invasivo.
/// Retorna `true` si el usuario eligió abrir ajustes.
Future<bool> showGpsDisabledDialog(BuildContext context, {bool force = false}) async {
  if (_dialogShownThisSession && !force) return false;
  _dialogShownThisSession = true;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.location_off, size: 48, color: AppColors.orange),
      title: const Text('Ubicación desactivada'),
      content: const Text(
        'Activa la ubicación para ver los comercios cercanos a ti.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx, true);
            await Geolocator.openLocationSettings();
          },
          child: const Text('Abrir ajustes'),
        ),
      ],
    ),
  );
  return result ?? false;
}
