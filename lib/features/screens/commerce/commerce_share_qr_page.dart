import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/features/utils/app_colors.dart';

/// Logo en el centro del QR (misma ruta que [pubspec] assets).
const String _kZonixQrLogoAsset = 'assets/images/logo_login.png';

/// Pantalla comercio: tarjeta + QR (`zonix://restaurant/{id}` en el código). Enlaces http(s) al compartir.
class CommerceShareQrPage extends StatefulWidget {
  const CommerceShareQrPage({
    super.key,
    required this.commerceId,
    required this.businessName,
    this.commerceImageUrl,
  });

  final int commerceId;
  final String businessName;

  /// URL del logo del comercio (GET /api/commerce → `image`).
  final String? commerceImageUrl;

  @override
  State<CommerceShareQrPage> createState() => _CommerceShareQrPageState();
}

class _CommerceShareQrPageState extends State<CommerceShareQrPage> {
  final GlobalKey _cardKey = GlobalKey();

  bool _sharing = false;

  String get _deepLink => AppConfig.buildCommerceDeepLink(widget.commerceId);

  String get _webUrl =>
      AppConfig.appLinkBase.isNotEmpty
          ? AppConfig.buildCommerceShareUrl(widget.commerceId)
          : '';

  String get _cardTitleLine => '${widget.businessName} — Zonix Eats';

  String get _cardSubtitleLine => 'Tu restaurante en Zonix Eats';

  /// Pie al compartir imagen + texto: prioriza URL http(s) para WhatsApp.
  String get _shareText {
    final a = _cardTitleLine;
    final b = _cardSubtitleLine;
    if (_webUrl.isNotEmpty) {
      return '$a\n$b\n$_webUrl';
    }
    return '$a\n$b\n\nEscanea el QR de la imagen para abrir este comercio en Zonix Eats.';
  }

  String get _shareLinkOnlyText {
    final a = _cardTitleLine;
    final b = _cardSubtitleLine;
    if (_webUrl.isNotEmpty) {
      return '$a\n$b\n$_webUrl';
    }
    return '$a\n$b\n\nInstala Zonix Eats y escanea el QR del comercio para entrar.';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final u = widget.commerceImageUrl?.trim();
    if (u != null && u.isNotEmpty) {
      precacheImage(NetworkImage(u), context);
    }
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _shareLinkOnlyText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Descripción y enlace copiados')),
    );
  }

  Future<void> _shareLinkOnly() async {
    await SharePlus.instance.share(
      ShareParams(
        text: _shareLinkOnlyText,
        subject: '${widget.businessName} — Zonix Eats',
      ),
    );
  }

  Future<void> _openUrl(String urlString) async {
    final Uri? uri = Uri.tryParse(urlString);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      debugPrint('CommerceShareQrPage._openUrl: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el enlace: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareComercioCard() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;

      final BuildContext? ctx = _cardKey.currentContext;
      if (ctx == null || !ctx.mounted) {
        throw StateError('Vista no disponible');
      }
      final renderObject = ctx.findRenderObject();
      final boundary = renderObject as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize) {
        throw StateError('Vista no lista para capturar');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      try {
        final ByteData? bd =
            await image.toByteData(format: ui.ImageByteFormat.png);
        final Uint8List? bytes = bd?.buffer.asUint8List();
        if (bytes == null) {
          throw StateError('toByteData devolvió null');
        }
        final Directory dir = await getTemporaryDirectory();
        final File file = File(
          '${dir.path}/zonix_qr_card_${widget.commerceId}.png',
        );
        await file.writeAsBytes(bytes, flush: true);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'image/png')],
            text: _shareText,
            subject: '${widget.businessName} — Zonix Eats',
          ),
        );
      } finally {
        image.dispose();
      }
    } catch (e, st) {
      debugPrint('CommerceShareQrPage._shareComercioCard: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo compartir la imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Widget _buildAvatar() {
    const double r = 40;
    final u = widget.commerceImageUrl?.trim();
    final Widget child;
    if (u != null && u.isNotEmpty) {
      child = ClipOval(
        child: Image.network(
          u,
          width: r * 2,
          height: r * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarPlaceholder(r),
        ),
      );
    } else {
      child = _avatarPlaceholder(r);
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _avatarPlaceholder(double r) {
    return CircleAvatar(
      radius: r,
      backgroundColor: AppColors.stitchBgCard,
      child: Icon(Icons.storefront_rounded, size: r * 1.1, color: AppColors.stitchSlate),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B141A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('QR del comercio'),
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topCenter,
                            children: [
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 44),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.black.withValues(alpha: 0.18),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    22,
                                    56,
                                    22,
                                    24,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        widget.businessName,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.stitchTextDark,
                                          height: 1.25,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Tu restaurante en Zonix Eats',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.stitchSlate,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      QrImageView(
                                        data: _deepLink,
                                        version: QrVersions.auto,
                                        size: 228,
                                        padding: const EdgeInsets.all(10),
                                        backgroundColor: AppColors.white,
                                        gapless: true,
                                        errorCorrectionLevel: QrErrorCorrectLevel.Q,
                                        embeddedImage: const AssetImage(
                                          _kZonixQrLogoAsset,
                                        ),
                                        embeddedImageStyle: const QrEmbeddedImageStyle(
                                          size: Size(52, 52),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                child: _buildAvatar(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Escanea este código para ver tu restaurante y pedir en Zonix Eats.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_webUrl.isNotEmpty) ...[
                      const Text(
                        'Enlace web (tocar para abrir)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.white54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _TappableLinkRow(
                        label: _webUrl,
                        onTap: () => _openUrl(_webUrl),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.stitchTextDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: _sharing ? null : _shareComercioCard,
                    child: _sharing
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Compartir código',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _sharing ? null : _shareLinkOnly,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blueLight,
                      side: BorderSide(
                        color: AppColors.blueLight.withValues(alpha: 0.65),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: const Icon(Icons.link_rounded, size: 22),
                    label: const Text(
                      'Compartir enlace del restaurante',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _sharing ? null : () => _copy(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.white70,
                      side: const BorderSide(color: AppColors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copiar enlace'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TappableLinkRow extends StatelessWidget {
  const _TappableLinkRow({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.blueLight,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.blueLight,
            ),
          ),
        ),
      ),
    );
  }
}
