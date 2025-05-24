import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zonix_eats/features/GasTicket/sales_admin/order_tracking/api/sales_admin_service.dart';
import 'package:zonix_eats/features/GasTicket/gas_button/models/gas_ticket.dart';
import 'package:zonix_eats/features/GasTicket/sales_admin/order_tracking/screens/cylinder_gas_ticket_scanner_screen.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

class TicketScannerScreen extends StatefulWidget {
  const TicketScannerScreen({super.key});

  @override
  TicketScannerScreenState createState() => TicketScannerScreenState();
}

class TicketScannerScreenState extends State<TicketScannerScreen> {
  late ApiService apiService;
  String scannedData = '';
  GasTicket? ticketData;
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
  }

  void _onScan(Barcode barcode) async {
    setState(() {
      scannedData = barcode.rawValue ?? 'Unknown';
    });

    try {
      var result = await apiService.verifyTicket(int.parse(scannedData));
      setState(() {
        ticketData = GasTicket.fromJson(result['data']); // Mapea al modelo
      });
    } catch (e) {
      _showMessage('Error al verificar el ticket');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _markAsWaiting() async {
    if (ticketData != null) {
      try {
        var result = await apiService.markAsWaiting(ticketData!.id);
        _showMessage(result['message']);
        setState(() {
          ticketData = null;
        });
      } catch (e) {
        _showMessage('Error al marcar como esperando');
      }
    }
  }

  void _cancelTicket() async {
    if (ticketData != null) {
      try {
        var result = await apiService.cancelTicket(ticketData!.id);
        _showMessage(result['message']);
        setState(() {
          ticketData = null;
        });
      } catch (e) {
        _showMessage('Error al cancelar el ticket');
      }
    }
  }

    void showPopup(BuildContext context, bool isMatch, String gasCylinderCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  color: Color(0x33000000),
                  offset: Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      isMatch
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      color: isMatch ? Colors.green : Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMatch
                          ? '¡Coincidencia Encontrada!'
                          : '¡Alerta! No hay coincidencia.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.interTight(
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMatch
                          ? 'La bombona con el código $gasCylinderCode coincide con el ticket. ¡Ahora puedes cobrar!'
                          : 'El código de la bombona $gasCylinderCode no corresponde con el ticket. Verifica los datos e intenta nuevamente.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        letterSpacing: 0.0,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Cierra el popup
                      if (isMatch) {
                        _markAsWaiting(); // Acción cuando hay coincidencia
                      } else {
                        _cancelTicket(); // Acción cuando no hay coincidencia
                      }
                    },
                    icon: Icon(
                      isMatch
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: Text(
                      isMatch ? 'Pagado' : 'Cerrar',
                      style: GoogleFonts.interTight(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMatch ? Colors.green : Colors.red,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: ticketData == null
          ? MobileScanner(
              onDetect: (BarcodeCapture barcodeCapture) {
                if (barcodeCapture.barcodes.isNotEmpty) {
                  final Barcode barcode = barcodeCapture.barcodes.first;
                  _onScan(barcode);
                }
              },
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: screenWidth,
                    decoration: BoxDecoration(
                      color:
                          isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: screenWidth * 0.05,
                        horizontal: screenWidth * 0.06,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: screenWidth * 0.25,
                                height: screenWidth * 0.25,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Image.network(
                                    ticketData?.photoUser ??
                                        'https://images.unsplash.com/photo-1580619265140-1671b43697ca?w=500&h=500',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.05),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${ticketData?.firstName ?? ''} ${ticketData?.lastName ?? ''}',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.w900,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${ticketData?.operatorName.join(', ') ?? ''} - ${ticketData?.phoneNumbers.join(', ') ?? ''}',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: screenWidth * 0.04,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    ticketData?.addresses.isNotEmpty ?? false
                                        ? ticketData!.addresses.first
                                        : 'Dirección no disponible',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: screenWidth * 0.04,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[800],
                                    ),
                                  ),

                                  Row(
                                    children: [
                                      Text(
                                        'Estación:',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          color:
                                              Theme.of(context).brightness == Brightness.dark
                                                  ? const Color(0xFF57636C)
                                                  : Colors.black,
                                          fontSize: screenWidth * 0.04,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    Text(
                                      ticketData?.stationCode ?? 'No station code available', // Proporcionar valor por defecto si es null
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: isDarkMode ? Colors.white : const Color(0xFF57636C),
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    ],
                                  ),
                               ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                1, 0, 1, 0),
                            child: Material(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                width: screenWidth,
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? const Color(0xFF2C2C2C)
                                      : Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 12,
                                      color: isDarkMode
                                          ? Colors.black26
                                          : const Color(0x33000000),
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16, 16, 16, 16),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Documento de Identidad',
                                        style: TextStyle(
                                          fontFamily: 'Inter Tight',
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Tipo:',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                            translateDocumentType(ticketData!
                                                    .documentType.isNotEmpty
                                                ? ticketData!.documentType.first
                                                : ''),
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Número:',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                            '${translateDocumentType2(ticketData!.documentType.isNotEmpty ? ticketData!.documentType.first : '')} '
                                             '${(ticketData?.documentNumberCi.isNotEmpty ?? false) ? ticketData?.documentNumberCi.join(', ') : 'No CI available'}',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        width: screenWidth,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            ticketData?.documentImages.isNotEmpty == true
                                                ? ticketData!.documentImages.first
                                                : 'https://images.unsplash.com/photo-1580619265140-1671b43697ca?w=500&h=500',
                                            width: MediaQuery.of(context).size.width,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                              Icons.broken_image,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                1, 0, 1, 0),
                            child: Material(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF2C2C2C)
                                      : Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 12,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.black26
                                          : const Color(0x33000000),
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16, 16, 16, 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Text(
                                        'Detalles del Ticket',
                                        style: TextStyle(
                                          fontFamily: 'Inter Tight',
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Posición:',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                            ticketData?.queuePosition ?? '',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Fecha de Reserva:',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                            ticketData?.reservedDate != null
                                                ? _formatDate(
                                                    ticketData!.reservedDate)
                                                : 'Fecha no disponible',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Fecha de Cita:',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                            ticketData?.appointmentDate != null
                                                ? _formatDate(
                                                    ticketData!.appointmentDate)
                                                : 'Fecha no disponible',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Fecha de Vencimiento:',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                            ticketData?.expiryDate != null
                                                ? _formatDate(
                                                    ticketData!.expiryDate)
                                                : 'Fecha no disponible',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                1, 0, 1, 0),
                            child: Material(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF2C2C2C)
                                      : Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 12,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.black26
                                          : const Color(0x33000000),
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16, 16, 16, 16),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Detalles de la Bombona',
                                        style: TextStyle(
                                          fontFamily: 'Inter Tight',
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 16), 
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Código:',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                           '${ticketData?.gasCylinderCode}',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Cantidad:',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                            '${ticketData?.cylinderQuantity ?? '0'} unidades',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Tipo de Boquilla:',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                            ticketData?.cylinderType == 'small'
                                                ? 'Boca Pequeña'
                                                : 'Boca Ancha',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Peso:',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                            '10 kg',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Fecha de Fabricación:',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                            ticketData?.manufacturingDate !=
                                                    null
                                                ? _formatDate(ticketData!
                                                    .manufacturingDate)
                                                : 'Fecha no disponible',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                          height:
                                              12), // Espaciado antes de la imagen
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            ticketData?.gasCylinderPhoto ??
                                                'https://images.unsplash.com/photo-1580619265140-1671b43697ca?w=500&h=500',
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null) return child; // Imagen cargada
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          (loadingProgress
                                                                  .expectedTotalBytes ??
                                                              1)
                                                      : null,
                                                ),
                                              ); // Indicador mientras se carga
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                              Icons.broken_image,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                          height: 12), // Espaciado final
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),





Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    ElevatedButton.icon(
      onPressed: _cancelTicket,
      icon: const Icon(
        Icons.cancel, // Icono del botón
        color: Colors.white, // Color del icono
        size: 24, // Tamaño del icono
      ),
      label: const Text(
        'Cancelar',
        style: TextStyle(
          fontFamily: 'Inter Tight', // Fuente personalizada
          color: Colors.white, // Color del texto
          letterSpacing: 0.0,
        ),
      ),
    
        style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red, // Color de fondo
        foregroundColor: Colors.white, // Color del texto
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 35,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28), // Borde redondeado
        ),
        elevation: 3, // Elevación para dar un poco de sombra
      ),
    ),
    const SizedBox(width: 10), // Espacio entre los botones
    ElevatedButton(
      onPressed: () async {
        // Abre el escáner y espera el resultado
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GasCylindersScreen(),
          ),
        );

        // Verifica si el resultado no es nulo
        if (result != null && result is Map<String, dynamic>) {
          final gasCylinderCode = result['gasCylinderCode']; // Ajusta según el formato esperado
          final localCode = ticketData?.gasCylinderCode;

          logger.w('gasCylinderCode: $gasCylinderCode, localCode: $localCode');

          // Verifica si los códigos coinciden
          if (gasCylinderCode == localCode) {
            // Mostrar popup para confirmar la compra
            showPopup(context, true, gasCylinderCode);
          } else {
            // Mostrar popup de alerta
            showPopup(context, false, gasCylinderCode);
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green, // Color de fondo
        foregroundColor: Colors.white, // Color del texto
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 35,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28), // Borde redondeado
        ),
        elevation: 3, // Elevación para dar un poco de sombra
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_gas_station, // Icono que aparece en el botón
            color: Colors.white, // Color del icono
            size: 24,
          ),
          SizedBox(width: 10), // Espacio entre el icono y el texto
          Text(
            'Validar',
            style: TextStyle(
              fontFamily: 'Inter Tight', // Fuente personalizada
            ),
          ),
        ],
      ),
    ),
  ],
)






                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),





    );
  }
}

String _formatDate(String date) {
  try {
    // Inicializar configuración en español
    initializeDateFormatting('es', null);

    final parsedDate = DateTime.parse(date);
    // Formato de fecha numérico
    return DateFormat('dd/MM/yyyy').format(parsedDate);
  } catch (e) {
    return date; // Retorna la cadena original si ocurre un error
  }
}

String translateDocumentType(String type) {
  switch (type) {
    case 'ci':
      return 'Cédula';
    case 'rif':
      return 'REGISTRO DE INFORMACIÓN FISCAL';
    case 'neighborhood_association':
      return 'ASOCIACIÓN DE VECINOS';
    case 'passport':
      return 'PASAPORTE';
    default:
      return 'DESCONOCIDO';
  }
}

String translateDocumentType2(String type) {
  switch (type) {
    case 'ci':
      return 'V';
    case 'rif':
      return 'RIF';
    case 'neighborhood_association':
      return 'AV';
    case 'passport':
      return 'P';
    default:
      return 'DESCONOCIDO';
  }
}
