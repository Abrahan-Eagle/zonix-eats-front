import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:zonix/models/order.dart';

/// Genera el PDF del recibo siguiendo el template Zonix Eats (code.html).
/// Archivo separado para no mezclar lógica de PDF con la pantalla de detalle de orden.
class ReceiptPdfBuilder {
  ReceiptPdfBuilder._();

  static const PdfColor _zonixDark = PdfColor.fromInt(0xFF1A2E46);
  static const PdfColor _zonixBlue = PdfColor.fromInt(0xFF3299FF);
  static const PdfColor _zonixOrange = PdfColor.fromInt(0xFFFFC107);

  /// Genera los bytes del PDF del recibo para la orden dada.
  /// Retorna null si ocurre un error.
  static Future<Uint8List?> build(Order order) async {
    try {
      final orderIdDisplay = order.orderNumber.isNotEmpty ? order.orderNumber : '${order.id}';
      final dateStr = _formatDate(order.createdAt);
      final paymentLabel = _paymentMethodLabel(order.paymentMethod);
      final commerceAddress = order.commerce?['address']?.toString() ?? '';

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return [
              // Header (template: bg-zonixDark, logo ZE, Zonix Eats, INTERSTELLAR GOURMET DELIVERY, address | RECEIPT, Receipt No., Date Issued)
              pw.Container(
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
                        pw.Container(
                          width: 56,
                          height: 56,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.Text('ZE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _zonixBlue)),
                        ),
                        pw.SizedBox(width: 16),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text('Zonix Eats', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                            pw.SizedBox(height: 2),
                            pw.Text('INTERSTELLAR GOURMET DELIVERY', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey300, fontWeight: pw.FontWeight.bold)),
                            if (commerceAddress.isNotEmpty) pw.Text(commerceAddress, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey400)),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('RECEIPT', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        pw.SizedBox(height: 12),
                        pw.Text('Receipt No.', style: pw.TextStyle(fontSize: 8, color: _zonixBlue, fontWeight: pw.FontWeight.bold)),
                        pw.Text('#ZX-$orderIdDisplay', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        pw.SizedBox(height: 6),
                        pw.Text('Date Issued', style: pw.TextStyle(fontSize: 8, color: _zonixBlue, fontWeight: pw.FontWeight.bold)),
                        pw.Text(dateStr, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      ],
                    ),
                  ],
                ),
              ),
              // Body (template: Customer Details | Payment Method, tabla, resumen)
              pw.Container(
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
                              pw.Row(children: [pw.Container(width: 4, height: 4, decoration: const pw.BoxDecoration(color: _zonixBlue, shape: pw.BoxShape.circle)), pw.SizedBox(width: 6), pw.Text('Customer Details', style: pw.TextStyle(fontSize: 9, color: _zonixBlue, fontWeight: pw.FontWeight.bold))]),
                              pw.SizedBox(height: 6),
                              pw.Text('Cliente', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _zonixDark)),
                              pw.SizedBox(height: 4),
                              pw.Text(order.deliveryAddress.isEmpty ? '—' : order.deliveryAddress, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600), maxLines: 4),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Text('Payment Method', style: pw.TextStyle(fontSize: 9, color: _zonixBlue, fontWeight: pw.FontWeight.bold)), pw.SizedBox(width: 6), pw.Container(width: 4, height: 4, decoration: const pw.BoxDecoration(color: _zonixBlue, shape: pw.BoxShape.circle))]),
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
                    // Tabla (template: thead bg-slate-50, Qty | Description | Unit Price | Subtotal)
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
                            pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12), child: pw.Text('Qty', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
                            pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12), child: pw.Text('Description', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
                            pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12), child: pw.Text('Unit Price', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
                            pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12), child: pw.Text('Subtotal', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
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
                    // Resumen (template: Subtotal, Delivery Fee, Taxes (IVA 16%), TOTAL FINAL bar con monto en zonixOrange)
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Container(
                        width: 200,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            _summaryRow('Subtotal', order.subtotal),
                            pw.SizedBox(height: 8),
                            _summaryRow('Delivery Fee', order.deliveryFee),
                            pw.SizedBox(height: 8),
                            _summaryRow('Taxes (IVA 16%)', order.tax),
                            pw.SizedBox(height: 16),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: pw.BoxDecoration(color: _zonixDark, borderRadius: pw.BorderRadius.circular(8)),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('TOTAL FINAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
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
              ),
              // Footer (template: Thank you for choosing Zonix!, support, Receipt #, Scan to verify)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.fromLTRB(32, 20, 32, 24),
                decoration: const pw.BoxDecoration(color: PdfColors.grey100, border: pw.Border(top: pw.BorderSide(width: 1, color: PdfColors.grey300))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [pw.Text('✓', style: pw.TextStyle(fontSize: 14, color: _zonixBlue, fontWeight: pw.FontWeight.bold)), pw.SizedBox(width: 8), pw.Text('Thank you for choosing Zonix!', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _zonixDark))]),
                    pw.SizedBox(height: 6),
                    pw.Text('We hope you enjoy your meal. Please keep this receipt for your records. For support, visit zonixeats.com/support.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.SizedBox(height: 12),
                    pw.Container(height: 1, color: PdfColors.grey300),
                    pw.SizedBox(height: 10),
                    pw.Text('Zonix Eats • Receipt #$orderIdDisplay', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                    pw.SizedBox(height: 4),
                    pw.Text('Scan to verify: #$orderIdDisplay', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _zonixDark)),
                  ],
                ),
              ),
            ];
          },
        ),
      );
      return await pdf.save();
    } catch (_) {
      return null;
    }
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
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String _paymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return 'Transferencia';
      case 'tarjeta':
        return 'Tarjeta';
      case 'pago_movil':
        return 'Pago móvil';
      default:
        return method.isEmpty ? '' : method;
    }
  }
}
