import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart'; 
import 'package:intl/intl.dart'; 
 
  // Método para generar el QR con el gasCylinderCode
  Future<Uint8List> _generateQRImage(String data) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.Q,
    );
    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw Exception('Error generando QR');
    }

    final qrCode = qrValidationResult.qrCode!;
    final painter = QrPainter.withQr(
      qr: qrCode,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    );

    final picData = await painter.toImageData(200, format: ui.ImageByteFormat.png);
    return picData!.buffer.asUint8List();
  }
 
 
 
 // Método para generar el PDF con el QR
  Future<Uint8List> generatePDFWithQR(String data) async {
    final pdf = pw.Document();

    // Obtener el QR como imagen
    final qrBytes = await _generateQRImage(data);

    // Convertir los bytes del QR en imagen para el PDF
    final qrImagePDF = pw.MemoryImage(qrBytes);

    // Crear el PDF
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('Código QR generado', style: const pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 20),
              // Cambiar el tamaño de la imagen a 1024x1024
              pw.Image(qrImagePDF, width: 512, height: 512),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }


// Función para formatear la fecha
String formatDate(String dateValue) {
  try {
    // Convierte la cadena a un objeto DateTime
    final date = DateTime.parse(dateValue);
    // Formatea la fecha en el formato deseado
    return DateFormat("d 'de' MMMM 'de' yyyy", 'es').format(date);
  } catch (e) {
    // Si hay un error, devuelve el valor original o un mensaje de error
    return dateValue;
  }
}

String translateValue(String value) {
  switch (value.toLowerCase()) {
    case 'small':
      return 'Boca Pequeña';
    case 'wide':
      return 'Boca Ancha';
    default:
      return value; // Devuelve el valor original si no está en el switch
  }
}
