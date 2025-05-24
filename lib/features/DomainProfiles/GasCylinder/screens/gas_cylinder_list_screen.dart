import 'package:flutter/material.dart';
import 'package:zonix_eats/features/DomainProfiles/GasCylinder/api/gas_cylinder_service.dart';
import 'package:zonix_eats/features/DomainProfiles/GasCylinder/models/gas_cylinder.dart';
import 'package:zonix_eats/features/DomainProfiles/GasCylinder/screens/create_gas_cylinder_screen.dart';
import 'package:zonix_eats/features/DomainProfiles/GasCylinder/screens/gas_cylinder_detail_screen.dart'; // Importar la pantalla de detalles
import 'package:zonix_eats/features/DomainProfiles/GasCylinder/providers/qr_gas_cylinder.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
class GasCylinderListScreen extends StatefulWidget {
  final int userId;
  final bool statusId;

  const GasCylinderListScreen({super.key, required this.userId, this.statusId = false});

  @override
  State<GasCylinderListScreen> createState() => _GasCylinderListScreenState();
}

class _GasCylinderListScreenState extends State<GasCylinderListScreen> {
  final GasCylinderService _cylinderService = GasCylinderService();

  // Método que carga las bombonas desde la API.
  Future<List<GasCylinder>> _fetchCylinders() async {
    try {
      return await _cylinderService.fetchGasCylinders(widget.userId);
    } catch (e) {
      throw Exception('No tienes Bombonas cargadas.');
    }
  }

  // Navegar a la pantalla de creación de bombonas y recargar al regresar.
  Future<void> _navigateToCreateCylinder(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGasCylinderScreen(userId: widget.userId),
      ),
    );
    setState(() {}); // Recargar la lista al regresar.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bombonas de Gas'),
      ),
     body: LayoutBuilder(
        builder: (context, constraints) {
          return FutureBuilder<List<GasCylinder>>(
            future: _fetchCylinders(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No hay bombonas disponibles.'));
              }

              final cylinders = snapshot.data!;
              return ListView.builder(
                itemCount: cylinders.length,
                itemBuilder: (context, index) {
                  final cylinder = cylinders[index];
                  return ListTile(
                    leading: Icon(
                      cylinder.approved ? Icons.check_circle : Icons.cancel,
                      color: cylinder.approved ? Colors.green : Colors.red,
                    ),
                    title: Text(cylinder.gasCylinderCode),
                    subtitle: Text(
                      'Cantidad: ${cylinder.cylinderQuantity ?? 'N/A'}',
                    ),
                    onTap: () {
                      // Navegar a la pantalla de detalles al tocar un elemento
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GasCylinderDetailScreen(cylinder: cylinder),
                        ),
                      );
                    },
                    trailing: cylinder.approved
                        ? IconButton(
                            icon: const Icon(Icons.qr_code),
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
                          )
                        : null,
                  );
                },
              );
            },
          );
        },
      ),

      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _navigateToCreateCylinder(context),
      //   child: const Icon(Icons.add),
      // ),



floatingActionButton: Stack(
        children: [
          // El botón de creación de documentos
          Positioned(
            right: 10,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () => _navigateToCreateCylinder(context),
              child: const Icon(Icons.add),
            ),
          ),
          // El botón de confirmación solo si statusId es true
          if (widget.statusId)
            Positioned(
              right: 10,
              bottom: 85,
              child: FloatingActionButton(
                onPressed: () async {
                  // Mostrar el popup de confirmación antes de realizar la acción
                  bool? isConfirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Confirmar acción'),
                        content: const Text('¿Quieres aprobar esta solicitud?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);  // Retorna 'No'
                            },
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);  // Retorna 'Sí'
                            },
                            child: const Text('Sí'),
                          ),
                        ],
                      );
                    },
                  );

                  // Si el usuario confirma la acción, proceder con la lógica
                  if (isConfirmed == true) {
                    try {
                      // Llamar a la función updateStatusCheckScanner desde ApiServices
                      await GasCylinderService().updateStatusCheckScanner(widget.userId);

                      // Mostrar SnackBar de éxito
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Estado actualizado'),
                          backgroundColor: Colors.green,  // Color de fondo para éxito
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: 'Cerrar',
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                        ),
                      );

                      // Retroceder después de la confirmación y acción exitosa
                      Navigator.of(context).pop();  // Retrocede a la pantalla anterior

                    } catch (e) {
                      // Mostrar SnackBar de error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,  // Color de fondo para error
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: 'Cerrar',
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                        ),
                      );
                    }
                  }
                },
                backgroundColor: Colors.green,
                child: const Icon(Icons.check),
              ),
            ),
        ],
      ),


    );
  }
}