import 'package:flutter/material.dart';

class EmailDetailScreen extends StatelessWidget {
  final Map<String, dynamic> email;

  const EmailDetailScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Email'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con información principal
            _buildDetailItem(context, 'Email: ${email['email']}', isHeader: true),
            
            const SizedBox(height: 20),
            
            // Información del email
            _buildDetailItem(context, 'Tipo: ${email['type'] ?? 'N/A'}'),
            _buildDetailItem(context, 'Verificado: ${email['verified'] ? 'Sí' : 'No'}'),
            _buildDetailItem(context, 'Principal: ${email['primary'] ? 'Sí' : 'No'}'),
            
            if (email['verified_at'] != null)
              _buildDetailItem(context, 'Verificado el: ${email['verified_at']}'),
            
            const SizedBox(height: 20),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Acción para editar email
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Acción para eliminar email
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Imagen del email (si existe)
            if (email['photoEmail'] != null && email['photoEmail'].isNotEmpty)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    email['photoEmail'] ?? '', // URL de la imagen
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.email,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String text, {bool isHeader = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: isHeader ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHeader ? Colors.blue.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 18 : 16,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.blue.shade800 : Colors.black87,
        ),
      ),
    );
  }
}

// Código comentado para referencia futura
// import 'package:zonix/features/DomainProfiles/Email/models/email.dart';
// 
// class EmailDetailScreen extends StatelessWidget {
//   final Email email;
// 
//   const EmailDetailScreen({super.key, required this.email});
// 
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Detalle de Email'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header con información principal
//             _buildDetailItem(context, 'Email: ${email.email}', isHeader: true),
//             
//             const SizedBox(height: 20),
//             
//             // Información del email
//             _buildDetailItem(context, 'Tipo: ${email.type ?? 'N/A'}'),
//             _buildDetailItem(context, 'Verificado: ${email.verified ? 'Sí' : 'No'}'),
//             _buildDetailItem(context, 'Principal: ${email.primary ? 'Sí' : 'No'}'),
//             
//             if (email.verifiedAt != null)
//               _buildDetailItem(context, 'Verificado el: ${email.verifiedAt}'),
//           ],
//         ),
//       ),
//     );
//   }
// 
//   Widget _buildDetailItem(BuildContext context, String text, {bool isHeader = false}) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16.0),
//       margin: const EdgeInsets.only(bottom: 8.0),
//       decoration: BoxDecoration(
//         color: isHeader ? Colors.blue.shade50 : Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: isHeader ? Colors.blue.shade200 : Colors.grey.shade300,
//         ),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           fontSize: isHeader ? 18 : 16,
//           fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
//           color: isHeader ? Colors.blue.shade800 : Colors.black87,
//         ),
//       ),
//     );
//   }
// }
