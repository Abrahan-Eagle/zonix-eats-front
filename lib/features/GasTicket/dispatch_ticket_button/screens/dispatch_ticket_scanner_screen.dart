import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zonix_eats/features/GasTicket/dispatch_ticket_button/api/dispatch_ticket_service.dart';
import 'package:zonix_eats/features/GasTicket/gas_button/models/gas_ticket.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:zonix_eats/features/GasTicket/gas_button/providers/status_provider.dart';

class DispatcherScreen extends StatefulWidget {
  const DispatcherScreen({super.key});

  @override
  DispatcherScreenState createState() => DispatcherScreenState();
}

class DispatcherScreenState extends State<DispatcherScreen> {
  late ApiService apiService;
  String scannedData = '';
  GasTicket? gasTicket; //CAMBIO
  bool isLoading = false;
  bool isUserScan = false;
  int? ticketId; // Cambia a tipo int


  @override
  void initState() {
    super.initState();
    apiService = ApiService();
  }

  void resetScreen() {
    setState(() {
      scannedData = '';
      gasTicket = null;
      isLoading = false;
      isUserScan = false;
    });
  }

  Future<void> _handleScan(Barcode barcode, {bool isCylinderScan = true}) async {
    setState(() {
      scannedData = barcode.rawValue?.trim() ?? 'Unknown';
      isLoading = true;
    });

    try {
      if (isCylinderScan) {
        var result = await apiService.scanCylinder(scannedData);

        setState(() {
          if (result['data'] is List && result['data'].isNotEmpty) {
            gasTicket = GasTicket.fromJson(result['data'][0]);
          } else if (result['data'] is Map<String, dynamic>) {
            gasTicket = GasTicket.fromJson(result['data']);
          } else {
            gasTicket = null;
          }

          ticketId = gasTicket?.id; // Asignamos ticketId desde cylinderData
          logger.i('Escaneo de bombona - ticketId: $ticketId');


        });

        if (gasTicket == null) {
          _showMessage('No se encontraron datos válidos para la bombona.');
        }
      } else {
        _showMessage('Código escaneado no es válido para un ticket.');
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleUserScan(Barcode barcode) async {
    setState(() {
      isLoading = true;
    });

    try {
      var scannedId = int.tryParse(barcode.rawValue?.trim() ?? '');
       logger.i('Ticket ID: $ticketId, Escaneado: $scannedId');

      
        if (ticketId != null && scannedId != null) {
        if (scannedId == ticketId) {
          _showMessage('QR de usuario válido');

          var result = await apiService.dispatchTicket(scannedId);
          _showMessage(result['message'] ?? 'Ticket procesado correctamente');
          resetScreen();
        } else {
          _showMessage('El ID de perfil no coincide con la bombona.');
        }
      } else {
        _showMessage('No se pudo obtener los datos para la comparación.');
      }
    } catch (e) {
      _showMessage('Error al escanear el QR de usuario: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            if (isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 100),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (gasTicket == null) ...[
              _buildMobileScanner(context),
            ] else ...[
              _buildCylinderInfo(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileScanner(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: MobileScanner(
          onDetect: (BarcodeCapture barcodeCapture) {
            if (barcodeCapture.barcodes.isNotEmpty) {
              final Barcode barcode = barcodeCapture.barcodes.first;
              if (isUserScan) {
                _handleUserScan(barcode);
              } else {
                _handleScan(barcode);
              }
            }
          },
        ),
      ),
    );
  }


  Widget _buildCylinderInfo(BuildContext context) {
  final theme = Theme.of(context);

  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Column(
      children: [
        CylinderInfoWidget(gasTicket: gasTicket!),
        const SizedBox(height: 16),
        // Botón estilizado
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            // onPressed: resetScreen,
               onPressed: () {
                setState(() {
                  gasTicket = null;
                  isUserScan = true; // Ahora se establece para escanear QR de usuario
                });
              },
            icon: Icon(
              Icons.qr_code_scanner,
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
            label: Text(
              'Escanear QR del Usuario',
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'Inter Tight',
                color: theme.colorScheme.onPrimary,
                letterSpacing: 0.0,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
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
  );
}

}

class CylinderInfoWidget extends StatelessWidget {
  final GasTicket gasTicket;
  const CylinderInfoWidget({super.key, required this.gasTicket});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildUsersDetailSection(context, gasTicket),
         const SizedBox(height: 16),
        _buildGasCylinder(context, gasTicket),
        const SizedBox(height: 16),
        _buildTimeline(context, gasTicket),
      ],
    );
  }

  Widget _buildUsersDetailSection(BuildContext context, GasTicket gasTicket) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: gasTicket.photoUser.isNotEmpty
                      ? Image.network(
                          gasTicket.photoUser,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.person,
                          size: 40,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${gasTicket.firstName} ${gasTicket.lastName}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      gasTicket.userEmail,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      gasTicket.phoneNumbers.isNotEmpty
                          ?  '${gasTicket.operatorName.join(', ')} - ${gasTicket.phoneNumbers.join(', ')}'
                          : 'Teléfono no disponible',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      gasTicket.addresses.isNotEmpty
                          ? gasTicket.addresses.first
                          : 'Dirección no disponible',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildGasCylinder(BuildContext context, GasTicket ticket) {
  final theme = Theme.of(context);

  return Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
    child: Material(
      color: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                'Detalles de la Bombona',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Inter Tight',
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Imagen del cilindro
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Center(
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Image.network(
                            ticket.gasCylinderPhoto,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes ?? 1)
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Detalles del cilindro
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Código:',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                              ),
                            ),
                            Text(
                              ticket.gasCylinderCode,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cantidad:',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                              ),
                            ),
                            Text(
                              '${ticket.cylinderQuantity} unidad(es)',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tipo:',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                              ),
                            ),
                            Text(
                              ticket.cylinderType == 'small' ? 'Boca Pequeña' : 'Boca Ancha',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Peso:',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                              ),
                            ),
                            Text(
                              '${ticket.cylinderWeight} kg',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Fabricación:',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                              ),
                            ),
                            Text(
                              _formatDate(ticket.manufacturingDate),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: 'Inter',
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Divide con espaciado
        ),
      ),
    ),
  );
}



Widget _buildTimeline(BuildContext context, GasTicket ticket) {
  final theme = Theme.of(context);

  return Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
    child: Material(
      color: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Título
            Text(
              'Línea de Tiempo',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'Inter Tight',
                fontWeight: FontWeight.w900,
                letterSpacing: 0.0,
              ),
            ),
            const SizedBox(height: 16),

            // Estado general
            Container(
              decoration: BoxDecoration(
                // color: theme.colorScheme.primaryContainer,
                color: StatusProvider().getStatusColor(ticket.status),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                 Text(
                    'Estado:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Inter',
                      color: Colors.white, // Cambiado a blanco
                      letterSpacing: 0.0,
                    ),
                  ),
                  Text(
                    StatusProvider().getStatusSpanish(ticket.status).toUpperCase(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: Colors.white, // Cambiado a blanco
                      letterSpacing: 0.0,
                    ),
                  ),

                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detalles de la línea de tiempo
            ...[
              {'label': 'Fecha de Reserva:', 'value': _formatDate(ticket.reservedDate)},
              {'label': 'Fecha de Cita:', 'value': _formatDate(ticket.appointmentDate)},
              {'label': 'Fecha de Vencimiento:', 'value': _formatDate(ticket.expiryDate)},
              {'label': 'Posición:', 'value': '#${ticket.queuePosition}'},
              {'label': 'Hora Asignada:', 'value': ticket.timePosition},
            ].map(
              (detail) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    detail['label']!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.0,
                    ),
                  ),
                  Text(
                    detail['value']!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Inter',
                      color: theme.colorScheme.secondary,
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
              ),
            ),
            // const SizedBox(height: 16),

    
          ],
        ),
      ),
    ),
  );
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

}

