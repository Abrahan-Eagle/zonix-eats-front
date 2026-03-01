import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:zonix/models/order.dart';
import 'package:zonix/l10n/app_strings.dart';

/// Genera el PDF del recibo siguiendo el template Zonix Eats (code.html).
/// Archivo separado para no mezclar lógica de PDF con la pantalla de detalle de orden.
class ReceiptPdfBuilder {
  ReceiptPdfBuilder._();

  static const PdfColor _zonixDark = PdfColor.fromInt(0xFF1A2E46);
  static const PdfColor _zonixBlue = PdfColor.fromInt(0xFF3299FF);
  static const PdfColor _zonixOrange = PdfColor.fromInt(0xFFFFC107);
  /// Color para EATS (marca): rojo/coral según diseño.
  static const PdfColor _zonixEats = PdfColor.fromInt(0xFFFF3D40);

  /// Genera los bytes del PDF del recibo para la orden dada.
  /// [logoImageBytes]: opcional, bytes del logo (PNG/JPEG) para el header; si es null se usa "ZE" como fallback.
  /// Retorna null si ocurre un error.
  static Future<Uint8List?> build(Order order, {Uint8List? logoImageBytes}) async {
    try {
      final orderIdDisplay = order.orderNumber.isNotEmpty ? order.orderNumber : '${order.id}';
      final dateStr = _formatDate(order.createdAt);
      final commerceAddress = order.commerce?['address']?.toString() ?? '';

      const double headerHeight = 140;
      const double footerHeight = 95;

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // Header fijo arriba
                pw.Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildHeader(orderIdDisplay, dateStr, commerceAddress, logoImageBytes),
                ),
                // Footer fijo al final de la hoja
                pw.Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildFooter(orderIdDisplay, logoImageBytes),
                ),
                // Cuerpo en el medio (entre header y footer)
                pw.Positioned(
                  top: headerHeight,
                  left: 0,
                  right: 0,
                  bottom: footerHeight,
                  child: _buildBody(order, context),
                ),
              ],
            );
          },
        ),
      );
      return await pdf.save();
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _buildHeader(String orderIdDisplay, String dateStr, String commerceAddress, Uint8List? logoImageBytes) {
    const double headerHeight = 140;
    return pw.Container(
                height: headerHeight,
                width: double.infinity,
                color: _zonixDark,
                padding: const pw.EdgeInsets.fromLTRB(32, 32, 32, 32),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(
                          width: 56,
                          height: 56,
                          child: logoImageBytes != null && logoImageBytes.isNotEmpty
                              ? pw.Image(
                                  pw.MemoryImage(logoImageBytes),
                                  width: 56,
                                  height: 56,
                                  fit: pw.BoxFit.contain,
                                )
                              : pw.Align(
                                  alignment: pw.Alignment.center,
                                  child: pw.Text('ZE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _zonixEats)),
                                ),
                        ),
                        pw.SizedBox(width: 16),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Row(
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Text('Zonix', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                                pw.Text(' EATS', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _zonixEats)),
                              ],
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(AppStrings.zonixEatsTagline, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey300, fontWeight: pw.FontWeight.bold)),
                            if (commerceAddress.isNotEmpty) pw.Text(commerceAddress, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey400)),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(AppStrings.receiptTitle, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        pw.SizedBox(height: 12),
                        pw.Text(AppStrings.receiptNumberLabel, style: pw.TextStyle(fontSize: 9, color: _zonixBlue, fontWeight: pw.FontWeight.bold)),
                        pw.Text('#ZX-$orderIdDisplay', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        pw.SizedBox(height: 6),
                        pw.Text(AppStrings.issueDateLabel, style: pw.TextStyle(fontSize: 9, color: _zonixBlue, fontWeight: pw.FontWeight.bold)),
                        pw.Text(dateStr, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      ],
                    ),
                  ],
                ),
              );
  }

  static pw.Widget _buildBody(Order order, pw.Context context) {
    final paymentLabel = _paymentMethodLabel(order.paymentMethod);
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [pw.Container(width: 4, height: 4, decoration: const pw.BoxDecoration(color: _zonixBlue, shape: pw.BoxShape.circle)), pw.SizedBox(width: 6), pw.Text(AppStrings.clientDataLabel, style: pw.TextStyle(fontSize: 9, color: _zonixBlue, fontWeight: pw.FontWeight.bold))]),
                    pw.SizedBox(height: 6),
                    pw.Text(AppStrings.clientLabel, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _zonixDark)),
                    pw.SizedBox(height: 4),
                    pw.Text(order.deliveryAddress.isEmpty ? '—' : order.deliveryAddress, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600), maxLines: 4),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Text(AppStrings.paymentMethodLabelPdf, style: pw.TextStyle(fontSize: 9, color: _zonixBlue, fontWeight: pw.FontWeight.bold)), pw.SizedBox(width: 6), pw.Container(width: 4, height: 4, decoration: const pw.BoxDecoration(color: _zonixBlue, shape: pw.BoxShape.circle))]),
                    pw.SizedBox(height: 6),
                    pw.Text(paymentLabel, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _zonixDark)),
                    if (order.referenceNumber != null && order.referenceNumber!.isNotEmpty)
                      pw.Text('Ref: ${order.referenceNumber}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Container(height: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 20),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(0.8),
              1: pw.FlexColumnWidth(2.5),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1),
            },
            border: const pw.TableBorder(horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300), bottom: pw.BorderSide(width: 1, color: PdfColors.grey400)),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12), child: pw.Text(AppStrings.quantityCol, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12), child: pw.Text(AppStrings.descriptionCol, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12), child: pw.Text(AppStrings.unitPriceCol, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
                  pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12), child: pw.Text(AppStrings.subtotalCol, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
                ],
              ),
              ...order.items.map((item) {
                return pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 12), child: pw.Center(child: pw.Text('${item.quantity}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _zonixDark)))),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text(item.productName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _zonixDark)),
                          if (item.specialInstructions != null && item.specialInstructions!.isNotEmpty)
                            pw.Text(item.specialInstructions!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 12), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('\$${item.price.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)))),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 12), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('\$${item.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _zonixDark)))),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 200,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _summaryRow(AppStrings.subtotal, order.subtotal),
                  pw.SizedBox(height: 8),
                  _summaryRow(AppStrings.shippingCostLabel, order.deliveryFee),
                  pw.SizedBox(height: 8),
                  _summaryRow(AppStrings.taxLabelIva, order.tax),
                  pw.SizedBox(height: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: pw.BoxDecoration(color: _zonixDark, borderRadius: pw.BorderRadius.circular(8)),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(AppStrings.totalFinalLabel, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(color: _zonixOrange, borderRadius: pw.BorderRadius.circular(4)),
                          child: pw.Text('\$${order.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _zonixDark)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footerLogo(Uint8List? logoImageBytes) {
    if (logoImageBytes == null || logoImageBytes.isEmpty) {
      return pw.SizedBox(width: 22, height: 22);
    }
    return pw.SizedBox(
      width: 22,
      height: 22,
      child: pw.Image(
        pw.MemoryImage(logoImageBytes),
        fit: pw.BoxFit.contain,
      ),
    );
  }

  static pw.Widget _buildFooter(String orderIdDisplay, Uint8List? logoImageBytes) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(32, 20, 32, 24),
      decoration: const pw.BoxDecoration(color: PdfColors.grey100, border: pw.Border(top: pw.BorderSide(width: 1, color: PdfColors.grey300))),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Row(
            children: [
              _footerLogo(logoImageBytes),
              pw.SizedBox(width: 8),
              pw.Text(AppStrings.thanksZonixEats, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _zonixDark)),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(AppStrings.footerSupportText, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.SizedBox(height: 12),
          pw.Container(height: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('Zonix', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              pw.Text('EATS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _zonixEats)),
              pw.Text(' - ${AppStrings.receiptHashLabel}$orderIdDisplay', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text('${AppStrings.scanToVerify}: #$orderIdDisplay', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _zonixEats)),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(String label, double value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.Text('\$${value.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _zonixDark)),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return '${d.day} de ${months[d.month - 1]} de ${d.year}';
  }

  static String _paymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'efectivo':
      case 'cash':
        return AppStrings.paymentCash;
      case 'transferencia':
        return AppStrings.paymentTransfer;
      case 'tarjeta':
        return AppStrings.paymentCard;
      case 'pago_movil':
        return AppStrings.paymentMobile;
      default:
        return method.isEmpty ? '' : method;
    }
  }
}
