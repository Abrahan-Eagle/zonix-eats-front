import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zonix/features/services/restaurant_service.dart';
import 'package:zonix/features/screens/restaurants/restaurant_details_page.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/storefront_qr_parser.dart';
import 'package:zonix/features/utils/storefront_qr_pending.dart';
import 'package:zonix/helpers/auth_helper.dart';

/// Escáner de QR de escaparate (catálogo del comercio). Independiente del [QrScannerPage] de delivery.
class StorefrontQrScannerPage extends StatefulWidget {
  const StorefrontQrScannerPage({super.key});

  @override
  State<StorefrontQrScannerPage> createState() => _StorefrontQrScannerPageState();
}

class _StorefrontQrScannerPageState extends State<StorefrontQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final raw = barcode!.rawValue!;
    final parsed = StorefrontQrParser.parse(raw);

    if (parsed.kind == StorefrontQrKind.invalid) {
      setState(() => _error = 'QR no reconocido. Usa el código del restaurante en Zonix.');
      return;
    }
    if (parsed.kind == StorefrontQrKind.orderPickupOrDelivery) {
      setState(() => _error =
          'Este QR es de una orden (repartidor). Escanea el QR del local.');
      return;
    }

    final id = parsed.commerceId;
    if (id == null) return;

    setState(() {
      _processing = true;
      _error = null;
    });
    await _controller.stop();

    await _openCommerce(id);
  }

  Future<void> _openCommerce(int commerceId) async {
    final token = await AuthHelper.getToken();
    final hasSession = token != null && token.isNotEmpty;

    if (!hasSession) {
      await StorefrontQrPending.save(commerceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para ver el menú de este restaurante.'),
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    try {
      final restaurant =
          await RestaurantService().fetchRestaurantDetails(commerceId);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RestaurantDetailsPage.fromRestaurant(restaurant),
        ),
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        setState(() {
          _processing = false;
          _error = 'No se pudo cargar el restaurante: $msg';
        });
        await _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.white,
      appBar: AppBar(
        title: const Text('Escanear restaurante'),
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.white,
        foregroundColor: isDark ? AppColors.white : AppColors.stitchTextDark,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_processing)
            ColoredBox(
              color: AppColors.black.withValues(alpha: 0.45),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.white),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null)
                  Material(
                    color: AppColors.red.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.white),
                      ),
                    ),
                  ),
                if (_error != null) const SizedBox(height: 12),
                Text(
                  'Apunta al QR del comercio (menú / escaparate).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppColors.white70 : AppColors.gray,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
