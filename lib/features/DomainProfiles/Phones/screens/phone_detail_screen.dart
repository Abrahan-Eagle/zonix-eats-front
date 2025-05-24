import 'package:flutter/material.dart';
import 'package:zonix_eats/features/DomainProfiles/GasCylinder/models/gas_cylinder.dart';

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem(context, 'Código: ${cylinder.gasCylinderCode}', isHeader: true),
                _buildDetailItem(context, 'Cantidad: ${cylinder.cylinderQuantity ?? 'N/A'}'),
                _buildDetailItem(
                  context,
                  'Estado: ${cylinder.approved ? 'Aprobada' : 'No Aprobada'}',
                  textColor: cylinder.approved ? Colors.green : Colors.red,
                ),
                _buildDetailItem(context, 'Tipo de cilindro: ${cylinder.cylinderType ?? 'N/A'}'),
                _buildDetailItem(context, 'Tamaño de cilindro: ${cylinder.cylinderWeight ?? 'N/A'}'),
                _buildDetailItem(context, 'Fecha de producción: ${_formatDate(cylinder.manufacturingDate)}'),
                _buildDetailItem(context, 'Fecha de Creación: ${_formatDate(cylinder.createdAt)}'),
                const SizedBox(height: 20),
                _buildImageButton(context), // Botón de imagen
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageButton(BuildContext context) {
    return Center(
      child: IconButton(
        iconSize: 100,
        icon: const Icon(Icons.image, color: Colors.blue),
        onPressed: () => _showImageDialog(context),
      ),
    );
  }


 void _showImageDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(10), // Reduce los márgenes del diálogo
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9, // 90% del ancho de la pantalla
          height: MediaQuery.of(context).size.height * 0.7, // 70% de la altura
          child: Column(
            children: [
              Expanded(
                child: Image.network(
                  cylinder.photoGasCylinder ?? '', // URL de la imagen
                  fit: BoxFit.contain, // Ajusta la imagen sin recortarla
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('Imagen no disponible'),
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      );
    },
  );
}



  Widget _buildDetailItem(BuildContext context, String text,
      {bool isHeader = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 20 : 16,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: textColor ?? Theme.of(context).textTheme.bodyMedium?.color,
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return date.toLocal().toString().split(' ')[0];
  }
}


// import 'package:flutter/material.dart';
// import 'package:zonix_eats/features/DomainProfiles/GasCylinder/models/gas_cylinder.dart';

// class GasCylinderDetailScreen extends StatelessWidget {
//   final GasCylinder cylinder;

//   const GasCylinderDetailScreen({super.key, required this.cylinder});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Detalle de Bombona'),
//       ),
//       body: _buildCylinderDetails(context),
//     );
//   }

//   Widget _buildCylinderDetails(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       height: double.infinity, // Asegura que ocupe toda la pantalla
//       child: Stack(
//         children: [
//           _buildBackgroundImage(context), // Imagen de fondo
//           Padding(
//             padding: const EdgeInsets.all(16.0), // Ajuste del padding
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildDetailItem(context, 
//                   'Código: ${cylinder.gasCylinderCode}', 
//                   isHeader: true,
//                 ),
//                 _buildDetailItem(context, 
//                   'Cantidad: ${cylinder.cylinderQuantity ?? 'N/A'}'),
//                 _buildDetailItem(
//                   context,
//                   'Estado: ${cylinder.approved ? 'Aprobada' : 'No Aprobada'}',
//                   textColor: cylinder.approved ? Colors.green : Colors.red,
//                 ),
//                 _buildDetailItem(context, 
//                   'Tipo de cilindro: ${cylinder.cylinderType ?? 'N/A'}'),
//                 _buildDetailItem(context, 
//                   'Tamaño de cilindro: ${cylinder.cylinderWeight ?? 'N/A'}'),
//                 _buildDetailItem(context, 
//                   'Fecha de producción: ${_formatDate(cylinder.manufacturingDate)}'),
//                 _buildDetailItem(context, 
//                   'Fecha de Creación: ${_formatDate(cylinder.createdAt)}'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailItem(BuildContext context, String text, 
//       {bool isHeader = false, Color? textColor}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10.0),
//       child: Text(
//         text,
//         style: TextStyle(
//           fontSize: isHeader ? 20 : 16,
//           fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
//           color: textColor ?? Theme.of(context).textTheme.bodyMedium?.color,
//         ),
//       ),
//     );
//   }

//   Widget _buildBackgroundImage(BuildContext context) {
//     // Define el color basado en el tema actual
//     Color logoColor = Theme.of(context).brightness == Brightness.dark
//         ? Colors.white
//         : Colors.black;

//     return Positioned(
//       right: -110,
//       bottom: -30,
//       child: SizedBox(
//         width: 425,
//         height: 425,
//         child: Opacity(
//           opacity: 0.3,
//           child: Image.asset(
//             'assets/images/splash_logo_dark.png',
//             fit: BoxFit.cover,
//             color: logoColor,
//             colorBlendMode: BlendMode.modulate,
//           ),
//         ),
//       ),
//     );
//   }

//   String _formatDate(DateTime? date) {
//     if (date == null) return 'N/A';
//     return date.toLocal().toString().split(' ')[0]; // Formato: YYYY-MM-DD
//   }
// }
