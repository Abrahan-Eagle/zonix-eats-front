import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Asegúrate de añadir esto a tu pubspec.yaml
import 'package:zonix_eats/features/DomainProfiles/Documents/models/document.dart';

class DocumentDetailScreen extends StatelessWidget {
  final Document document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('Detalle del Documento'),
      ),
      body: _buildDocumentDetails(context),
      floatingActionButton: Stack(
        children: [
          // Botón para foto frontal
          Positioned(
            right: 18,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () {
                _showImageDialog(context, document.frontImage ?? '');
              },
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.blueAccent
                  : Colors.orange,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildDocumentDetails(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          _buildBackgroundImage(context), // Imagen de fondo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomDocumentCard(
                  context,
                  title: 'Documento N.º',
                  // value: document.numberCi ?? 'N/A', // Número del documento
                  value: getDocumentNumber(document) ?? 'N/A', // Número del documento
                  icon: Icons.assignment,
                  valueColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black, // Color adaptado al tema
                  title2: 'Estado',
                  value2: getStatusSpanish(document.getApprovedStatus()), // Estado del documento en español
                  icon2: getStatusIcon(document.getApprovedStatus()), // Icono dinámico basado en el estado
                  valueColor2: getStatusColor(document.getApprovedStatus()), // Color dinámico basado en el estado
                ),
                
                const SizedBox(height: 20),
                
                _buildCustomDocumentCard2(
                  context,
                  title: 'Tipo Documento',
                  value: translateDocumentType(document.type ?? 'Desconocido'),
                  icon: Icons.description,
                  valueColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  title1: 'Fecha de Creación',
                  value1: _formatDate(document.issuedAt),
                  icon1: Icons.calendar_today,
                  valueColor1: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  title2: 'Fecha de Expiración',
                  value2: _formatDate(document.expiresAt),
                  icon2: Icons.timer_off,
                  valueColor2: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                
                const SizedBox(height: 20),

                _buildSpecificFields(context), // Campos específicos según el tipo
                const SizedBox(height: 10), // Espacio antes de la fecha de creación
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage(BuildContext context) {
    Color logoColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Positioned(
      right: -110,
      bottom: -30,
      child: SizedBox(
        width: 425,
        height: 425,
        child: Opacity(
          opacity: 0.3,
          child: Image.asset(
            'assets/images/splash_logo_dark.png',
            fit: BoxFit.cover,
            color: logoColor,
            colorBlendMode: BlendMode.modulate,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return date.toLocal().toString().split(' ')[0];
  }

  String translateDocumentType(String type) {
    switch (type) {
      case 'ci':
        return 'DOCUMENTO NACIONAL DE IDENTIDAD';
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

  Color getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusSpanish(String status) {
    switch (status) {
      case 'approved':
        return 'Aprobado';
      case 'pending':
        return 'Pendiente';
      case 'rejected':
        return 'Rechazado';
      default:
        return 'Desconocido';
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.verified; // Icono para aprobado
      case 'pending':
        return Icons.hourglass_empty; // Icono para pendiente
      case 'rejected':
        return Icons.cancel; // Icono para rechazado
      default:
        return Icons.help_outline; // Icono para estados desconocidos
    }
  }

    String getDocumentNumber(Document document) {
  switch (document.type) {
    case 'ci':
      return document.numberCi ?? 'N/A';
    case 'passport':
      return document.receiptN?.toString() ?? 'N/A';
    case 'rif':
      return document.sky?.toString() ?? 'N/A';
    case 'neighborhood_association':
      return document.communeRegister ?? 'N/A';
    default:
      return 'Desconocido';
  }
}


  Widget _buildSpecificFields(BuildContext context) {
    List<Widget> fields = [];

    switch (document.type) {
      case 'ci':
      case 'passport':
      case 'rif':
      case 'neighborhood_association':
        if (document.type == 'rif') {
            fields.add(_buildTaxDomicileCard(context, document.taxDomicile ?? 'N/A', isHeader: true, rifUrl: document.rifUrl ?? '',),);
        }

        if (document.type == 'neighborhood_association') {
          fields.add(_buildCommunityRifCard(context,  document.communityRif ?? 'N/A', isHeader: true, ), );
        }
        break;

      default:
        fields.add(const Text('No hay campos disponibles para este tipo de documento.'));
        break;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: fields);
  }



Widget _buildTaxDomicileCard(BuildContext context, String text,
    {bool isHeader = false, Color? textColor, required String rifUrl}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Material(
    color: Colors.transparent,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado opcional
            if (isHeader)
              Text(
                'Domicilio Fiscal',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor ??
                      (isDarkMode ? const Color(0xFF9E9E9E) : const Color(0xFF333333)),
                  letterSpacing: 0.0,
                ),
              ),
            if (isHeader) const SizedBox(height: 16),

            // Texto principal
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor ??
                    (isDarkMode ? Colors.white : const Color(0xFF000000)),
                letterSpacing: 0.0,
              ),
            ),

            const SizedBox(height: 16), // Espaciado entre texto principal y nuevo contenedor

            // Nuevo contenedor con QR
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF333333) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            color: isDarkMode
                                ? const Color(0xFF9E9E9E)
                                : const Color(0xFF666666),
                            letterSpacing: 0.0,
                          ),
                        ),
                        Text(
                          rifUrl.isNotEmpty ? 'QR RIF' : 'Sin QR',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:  Color(0xFFFFA500),
                            letterSpacing: 0.0,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          if (rifUrl.isNotEmpty) {
                            _launchURL(rifUrl);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No hay URL disponible')),
                            );
                          }
                        },
                        child: Icon(
                          rifUrl.isNotEmpty ? Icons.qr_code : Icons.error_outline,
                          color: const Color(0xFFFFA500),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  
Widget _buildCustomDocumentCard(
  BuildContext context, {
  required String title,
  required String value,
  required IconData icon,
  Color? valueColor,
  required String title2,
  required String value2,
  required IconData icon2,
  Color? valueColor2,
}) {
  // Detectar si el modo es oscuro o claro
  bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Material(
    color: Colors.transparent,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Container(
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        // Cambiar el color de fondo según el modo
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Primera sección
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Manrope',
                color: isDarkMode ? const Color(0xFF9E9E9E) : const Color(0xFF000000),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: valueColor ?? (isDarkMode ? Colors.white : Colors.black),
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Segunda sección
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF333333) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title2,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            color: isDarkMode ? const Color(0xFF9E9E9E) : const Color(0xFF000000),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          value2,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            color: valueColor2 ?? (isDarkMode ? Colors.white : Colors.black),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        icon2,
                        color: valueColor2 ?? (isDarkMode ? Colors.white : Colors.black),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildCustomDocumentCard2(
  BuildContext context, {
  required String title,
  required String value,
  required IconData icon,
  Color? valueColor,

  // Campos adicionales
  String? title1,
  String? value1,
  IconData? icon1,
  Color? valueColor1,

  String? title2,
  String? value2,
  IconData? icon2,
  Color? valueColor2,
}) {
  // Detectar si el modo es oscuro o claro
  bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Material(
    color: Colors.transparent,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Container(
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Título y valor principal
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Manrope',
                    color: isDarkMode ? const Color(0xFF9E9E9E) : const Color(0xFF000000),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.0,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Outfit',
                    color: valueColor ?? (isDarkMode ? Colors.white : Colors.black),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.0,
                  ),
            ),
            const SizedBox(height: 16),
            // Filas para título1 y título2
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (title1 != null && value1 != null)
                  _buildDetailColumn(context, title1, value1, isDarkMode),
                if (title2 != null && value2 != null)
                  _buildDetailColumn(context, title2, value2, isDarkMode),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildDetailColumn(
  BuildContext context,
  String title,
  String value,
  bool isDarkMode, // Pasar el modo oscuro como argumento
) {
  return Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'Manrope',
                color: isDarkMode ? const Color(0xFF9E9E9E) : const Color(0xFF000000),
                letterSpacing: 0.0,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontFamily: 'Manrope',
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.0,
              ),
        ),
      ],
    ),
  );
}

Widget _buildCommunityRifCard(BuildContext context, String communityRif,
    {bool isHeader = false, Color? textColor}) {
  return Material(
    color: Colors.transparent,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isHeader)
              Text(
                'Rif de la Comunidad',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? const Color(0xFF9E9E9E),
                  letterSpacing: 0.0,
                ),
              ),
            if (isHeader) const SizedBox(height: 16),
            Text(
              communityRif,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor ?? Colors.white,
                letterSpacing: 0.0,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'No se pudo abrir el enlace: $url';
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay imagen disponible')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(0), // Elimina el espaciado
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
