import 'package:flutter/material.dart';
import 'package:zonix/features/GasTicket/gas_button/models/gas_ticket.dart';
import 'package:zonix/features/GasTicket/gas_button/providers/status_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class TicketDetailsScreen extends StatelessWidget {
  final GasTicket? selectedTicket;

  const TicketDetailsScreen({super.key, required this.selectedTicket});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ticket: Información Detallada'),
          backgroundColor:
              isDarkMode ? const Color(0xFF4B39EF) : const Color(0xFF0078FF),
          foregroundColor: Colors.white, // Esto asegura que el texto sea blanco
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body:
            selectedTicket == null
                ? const Center(child: Text('No hay ticket seleccionado.'))
                : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Stack(
                        children: [
                          _buildTicketDetails(context, selectedTicket!),
                          _buildAdditionalTicketInfo(context, selectedTicket!),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildGasCylinder(context, selectedTicket!),
                      const SizedBox(height: 14),
                      _buildTimeline(context, selectedTicket!),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildTicketDetails(BuildContext context, GasTicket ticket) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF4B39EF) : const Color(0xFF0078FF),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Posición: ${ticket.queuePosition}',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: isDarkMode ? Colors.white : Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          StatusProvider()
                              .getStatusSpanish(ticket.status)
                              .toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: StatusProvider().getStatusColor(
                              ticket.status,
                            ),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildQRCode(ticket),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 32),
              child: Text(
                ticket.timePosition,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: isDarkMode ? Colors.white : Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                _formatDate(ticket.appointmentDate),
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: isDarkMode ? Colors.white70 : Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDecorativeContainer(true, isDarkMode),
                _buildProgressIndicator(isDarkMode),
                _buildProgressIndicator(isDarkMode),
                _buildProgressIndicator(isDarkMode),
                _buildDecorativeContainer(false, isDarkMode),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeContainer(bool isLeft, bool isDarkMode) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 50,
        height: 70,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFFF1F4F8) : const Color(0xFFF1F4F8),
          borderRadius:
              isLeft
                  ? const BorderRadius.only(
                    bottomRight: Radius.circular(50),
                    topRight: Radius.circular(50),
                  )
                  : const BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    topLeft: Radius.circular(50),
                  ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDarkMode) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 40,
        height: 8,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[600] : const Color(0xFFE0E3E7),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildQRCode(GasTicket ticket) {
    return QrImageView(
      data: ticket.id.toString(),
      version: QrVersions.auto,
      size: 110.0,
      foregroundColor: Colors.white,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildAdditionalTicketInfo(BuildContext context, GasTicket ticket) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 275, 16, 0),
      child: Align(
        alignment: AlignmentDirectional.center,
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              // color: isDarkMode ? Colors.grey[850] : Colors.white,
              color: isDarkMode ? theme.colorScheme.surface : Colors.white,

              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  color: isDarkMode ? Colors.black26 : const Color(0x33000000),
                  offset: const Offset(0, 5),
                ),
              ],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${ticket.firstName} ${ticket.lastName}',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF101213),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ticket.stationCode,
                        // ${ticket.stationCode}');
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color:
                              isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF57636C),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '📞 Teléfono:',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF57636C)
                                  : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        // '${ticket.operatorName} - ${ticket.phoneNumbers.join(', ')}',
                       '${ticket.operatorName.join(', ')} - ${ticket.phoneNumbers.join(', ')}',

                       
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color:
                              isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF101213),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '📍 Dirección:',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF57636C)
                                  : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ticket.addresses.join(', '),
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color:
                                isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF101213),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGasCylinder(BuildContext context, GasTicket ticket) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              'Datos de Cilindro de Gas',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'Inter Tight',
                letterSpacing: 0.0,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
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
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.primary, // Color del indicador
                          ),
                        ),
                        Image.network(
                          ticket.gasCylinderPhoto,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child; // Imagen cargada
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
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
                              (context, error, stackTrace) => const Icon(
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
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.gasCylinderCode,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontFamily: 'Inter Tight',
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tipo de boquilla: ${ticket.cylinderType == 'small' ? 'Boca Pequeña' : 'Boca Ancha'}',

                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Inter',
                          letterSpacing: 0.0,
                        ),
                      ),
                      // const SizedBox(height: 1),
                      Text(
                        'Peso: ${ticket.cylinderWeight}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Inter',
                          letterSpacing: 0.0,
                        ),
                      ),
                      // const SizedBox(height: 1),
                      Text(
                        'Cantidad: ${ticket.cylinderQuantity}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Inter',
                          letterSpacing: 0.0,
                        ),
                      ),

                      Text(
                        'Fabricación: ${_formatDate(ticket.manufacturingDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'Inter',
                          color: theme.colorScheme.secondary,
                          letterSpacing: 0.0,
                        ),
                      ),

                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      // Inicializar configuración en español
      initializeDateFormatting('es', null);

      final parsedDate = DateTime.parse(date);
      // Formato de fecha en español
      return DateFormat("d 'de' MMMM 'de' yyyy", 'es').format(parsedDate);
    } catch (e) {
      return date; // Retorna la cadena original si ocurre un error
    }
  }

  Widget _buildTimeline(BuildContext context, GasTicket ticket) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4, // Sombra para resaltar la tarjeta
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Bordes redondeados
      ),
      color: theme.colorScheme.surface, // Fondo de la tarjeta
      child: Padding(
        padding: const EdgeInsets.all(24), // Espaciado interno
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              'Línea de Tiempo',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'Inter Tight',
                letterSpacing: 0.0,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimelineRow(
              context,
              'Cita Programada:',
              _formatDate(ticket.appointmentDate),
              Icons.event,
              success: true,
            ),
            const SizedBox(height: 16),
            _buildTimelineRow(
              context,
              'Fecha Reservada:',
              _formatDate(ticket.reservedDate),
              Icons.event_available,
              success: true,
            ),
            const SizedBox(height: 16),
            _buildTimelineRow(
              context,
              'Fecha de Vencimiento:',
              _formatDate(ticket.expiryDate),
              Icons.event_busy,
              success: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool success = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          color: success ? theme.colorScheme.primary : theme.colorScheme.error,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.0,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'Inter',
                  color: theme.colorScheme.secondary,
                  letterSpacing: 0.0,
                ),
              ),
            ],
          ),
        ),
        if (success)
          Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 24),
      ],
    );
  }
}