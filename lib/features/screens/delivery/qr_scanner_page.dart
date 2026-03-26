import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/delivery_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

/// QR scanner for delivery agents.
/// [scanType] is either 'pickup' or 'delivery'.
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({
    super.key,
    required this.orderId,
    required this.scanType,
  });

  final int orderId;
  final String scanType;

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
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
    if (barcode == null || barcode.rawValue == null) return;

    final raw = barcode.rawValue!;
    final prefix = 'zonix://${widget.scanType}/';
    if (!raw.startsWith(prefix)) {
      setState(() => _error = 'QR no válido para esta operación');
      return;
    }

    final parts = raw.substring(prefix.length).split('/');
    if (parts.length < 2) {
      setState(() => _error = 'QR con formato incorrecto');
      return;
    }

    final orderId = int.tryParse(parts[0]) ?? -1;
    final token = parts[1];

    if (orderId != widget.orderId) {
      setState(() => _error = 'Este QR es de otra orden');
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });
    _controller.stop();

    try {
      final service = context.read<DeliveryService>();
      if (widget.scanType == 'pickup') {
        await service.scanPickup(orderId, token);
      } else {
        await service.scanDelivery(orderId, token);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      final errMsg = e.toString();
      final isNetworkError = errMsg.contains('SocketException') ||
          errMsg.contains('TimeoutException') ||
          errMsg.contains('Connection refused');

      if (isNetworkError) {
        if (mounted) {
          setState(() {
            _processing = false;
            _error =
                'Sin conexión. No se pudo confirmar el escaneo en el servidor. Conéctate a internet e intenta de nuevo.';
          });
          _controller.start();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _processing = false;
          _error = errMsg.replaceFirst('Exception: ', '');
        });
        _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.scanType == 'pickup'
        ? 'Escanear recogida'
        : 'Escanear entrega';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: AppColors.black54,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_processing)
                    const CircularProgressIndicator(color: AppColors.white)
                  else
                    Text(
                      widget.scanType == 'pickup'
                          ? 'Apunta al QR del comercio'
                          : 'Apunta al QR del cliente',
                      style: const TextStyle(color: AppColors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
