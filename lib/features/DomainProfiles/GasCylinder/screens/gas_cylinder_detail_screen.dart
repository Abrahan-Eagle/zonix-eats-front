import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:zonix/features/DomainProfiles/GasCylinder/models/gas_cylinder.dart';
import 'package:zonix/features/DomainProfiles/GasCylinder/providers/qr_gas_cylinder.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

final logger = Logger();

class GasCylinderDetailScreen extends StatelessWidget {
  final GasCylinder cylinder;

  const GasCylinderDetailScreen({super.key, required this.cylinder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Bombona'),
      ),
      body: _buildCylinderDetails(context),
      floatingActionButton: Stack(
        children: [
          // Botón de Generar PDF solo si está aprobado
          if (cylinder.approved)
            Positioned(
              right: 10,
              bottom: 10,
              child: FloatingActionButton(
                onPressed: () async {
                  try {
                    // Generar el PDF con el QR
                    final pdfBytes =
                        await generatePDFWithQR(cylinder.gasCylinderCode);

                    // Mostrar el PDF en una vista previa
                    await Printing.layoutPdf(
                      onLayout: (PdfPageFormat format) async => pdfBytes,
                    );
                  } catch (e) {
                    // Manejar errores
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                backgroundColor: Colors.green, // Color distintivo para el botón
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code, size: 40), // Ícono de QR
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCylinderDetails(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          _buildBackgroundImage(context), // Imagen de fondo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              // Agregado para scroll en pantallas pequeñas
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      cylinder.photoGasCylinder ?? '',
                      width:
                          double.infinity, // Se ajusta al ancho de la pantalla
                      height: MediaQuery.of(context).size.height *
                          0.3, // 30% de la altura de la pantalla
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('Imagen no disponible'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(
                      height:
                          16), // Espacio entre la imagen y el siguiente item
                  _buildDetailItemList(
                    context,
                    value: cylinder.gasCylinderCode ??
                        'N/A', // Número del documento
                    value2: cylinder.cylinderQuantity?.toString() ??
                        'N/A', // Convertir a String
                    value3: cylinder.approved
                        ? 'Aprobada'
                        : 'No Aprobada', // Número del documento
                    textColor3: cylinder.approved ? Colors.green : Colors.red,
                    value4:
                        cylinder.cylinderType ?? 'N/A', // Número del documento
                    value5: cylinder.cylinderWeight ??
                        'N/A', // Número del documento
                    value6: cylinder.manufacturingDate != null
                        ? DateFormat("d 'de' MMMM 'de' yyyy")
                            .format(cylinder.manufacturingDate!)
                        : '',
                  ),
                  const SizedBox(height: 16),
                  _buildAdditionalInformation(
                    context,
                    value: cylinder.createdAt != null
                        ? DateFormat("d 'de' MMMM 'de' yyyy")
                            .format(cylinder.createdAt!)
                        : '',
                    value2: cylinder.updatedAt != null
                        ? DateFormat("d 'de' MMMM 'de' yyyy")
                            .format(cylinder.updatedAt!)
                        : '',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItemList(
    BuildContext context, {
    required String value,
    required String value2,
    required String value3,
    required Color textColor3,
    required String value4,
    required String value5,
    required String value6,
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
          // padding: const EdgeInsets.all(20),
          padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Título 1

              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Código',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? const Color(0xFF9E9E9E)
                              : const Color(0xFF000000),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          fontFamily: 'Inter Tight',
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (value3.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(8, 16, 8, 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: textColor3,
                            size: 20,
                          ),
                          const SizedBox(width: 8), // Separador dinámico
                          Text(
                            value3,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16), // Espaciado entre filas

              // Divider
              Container(
                width: MediaQuery.sizeOf(context).width,
                height: 1,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF424242)
                      : const Color(0xFFE0E0E0),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cantidad',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          letterSpacing: 0.0,
                          fontSize: 14,
                          color: isDarkMode
                              ? const Color(0xFF9E9E9E)
                              : const Color(0xFF000000),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        '$value2 unidades',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          letterSpacing: 0.0,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Peso',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? const Color(0xFF9E9E9E)
                              : const Color(0xFF000000),
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Inter',
                          letterSpacing: 0.0,
                        ),
                      ),
                      Text(
                        value5,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontFamily: 'Inter',
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Divider

              const SizedBox(height: 16),

              Container(
                width: MediaQuery.sizeOf(context).width,
                height: 1,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF424242)
                      : const Color(0xFFE0E0E0),
                ),
              ),
              // Título 4

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment
                    .center, // Centra la columna horizontalmente
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // Centra los elementos dentro de la columna
                    children: [
                      Text(
                        'Tipo de Boquilla',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? const Color(0xFF9E9E9E)
                              : const Color(0xFF000000),
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Inter',
                          letterSpacing: 0.0,
                        ),
                      ),
                      const SizedBox(
                          height: 8), // Espaciado entre texto y contenedor
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(8, 16, 8, 16),
                        child: Text(
                          translateValue(value4),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1565C0),
                            fontFamily: 'Inter',
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Divider
              Container(
                width: MediaQuery.sizeOf(context).width,
                height: 1,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF424242)
                      : const Color(0xFFE0E0E0),
                ),
              ),

              const SizedBox(height: 16),

              // Título 6
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha de Fabricación',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? const Color(0xFF9E9E9E)
                              : const Color(0xFF000000),
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Inter',
                          letterSpacing: 0.0,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: isDarkMode
                                ? const Color(0xFF9E9E9E)
                                : const Color(0xFF000000),
                            size: 20,
                          ),
                          const SizedBox(
                              width:
                                  8), // Añade una separación horizontal de 8 píxeles
                          Text(
                            value6, // Formatea la fecha
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontFamily: 'Inter',
                              letterSpacing: 0.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalInformation(
    BuildContext context, {
    required String value,
    required String value2,
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
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          // Cambiar el color de fondo según el modo
          color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                'Información Adicional',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontFamily: 'Inter Tight',
                      color: isDarkMode
                          ? const Color(0xFF9E9E9E)
                          : const Color(0xFF000000),
                      letterSpacing: 0.0,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF424242)
                          : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.safety_check,
                      color: Color(0xFF1565C0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Certificación de Seguridad',
                          style:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    fontFamily: 'Inter',
                                    color: isDarkMode
                                        ? const Color(0xFF9E9E9E)
                                        : const Color(0xFF000000),
                                    letterSpacing: 0.0,
                                  ),
                        ),
                        Text(
                          value,
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    fontFamily: 'Inter',
                                    color: isDarkMode
                                        ? Colors.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                    letterSpacing: 0.0,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF424242)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Color(0xFF2E7D32),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Última Inspección',
                          style:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    fontFamily: 'Inter',
                                    color: isDarkMode
                                        ? const Color(0xFF9E9E9E)
                                        : const Color(0xFF000000),
                                    letterSpacing: 0.0,
                                  ),
                        ),
                        Text(
                          value2,
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    fontFamily: 'Inter',
                                    color: isDarkMode
                                        ? Colors.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                    letterSpacing: 0.0,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
}
