// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:http/http.dart' as http;
// import '../api/profile_service.dart';
// import 'package:zonix/features/GasTicket/gas_button/api/gas_ticket_service.dart';

// class SelectStationModal extends StatefulWidget {
//   final int userId;

//   const SelectStationModal({super.key, required this.userId});

//   @override
//   SelectStationModalState createState() => SelectStationModalState();
// }

// class SelectStationModalState extends State<SelectStationModal> {
//   final GasTicketService _ticketService = GasTicketService();
//   final _formKey = GlobalKey<FormState>();
//   List<Map<String, dynamic>> _stations = [];
//   int? _selectedStationId;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadStations();
//   }

//   Future<void> _loadStations() async {
//     setState(() {
//       _isLoading = true;
//     });
//     try {
//       final stations = await _ticketService.fetchStations();
//       setState(() {
//         _stations = stations.map((station) {
//           return {
//             'id': station['id'],
//             'code': station['code'] ?? 'Sin nombre',
//           };
//         }).toList();
//       });
//     } catch (e) {
//       _showCustomSnackBar(
//         'Error loading stations: $e',
//         Colors.red,
//         Icons.error,
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   void _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });
//       try {
//         await ProfileService().updateStatusCheckScanner(widget.userId, _selectedStationId!);
//         _showCustomSnackBar(
//           'Ticket created successfully!',
//           Colors.green,
//           Icons.check_circle,
//         );
//         Navigator.pop(context);
//       } catch (e) {
//         _showCustomSnackBar(
//           'Failed to create ticket: $e',
//           Colors.red,
//           Icons.error,
//         );
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   void _showCustomSnackBar(String message, Color backgroundColor, IconData icon) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(icon, color: Colors.white),
//             const SizedBox(width: 8),
//             Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
//           ],
//         ),
//         backgroundColor: backgroundColor,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isLargeScreen = screenWidth > 600;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Generar Ticket de Gas')),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.symmetric(
//           horizontal: screenWidth * 0.05,
//           vertical: 16.0,
//         ),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Center(
//                 child: SvgPicture.asset(
//                   'assets/images/undraw_date_picker_re_r0p8.svg',
//                   height: isLargeScreen ? 250 : 200,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 '¡Listo para comprar gas sin complicaciones?\n'
//                 'Te daremos una cita con fecha y hora para recoger tu pedido. '
//                 'Sin filas ni demoras, ¡todo más fácil!\n\n'
//                 '⏳ Ojo: Tu ticket es válido solo por un día, así que asegúrate de ir a tiempo. '
//                 '¿No puedes asistir? No pasa nada, cancela y reprograma cuando quieras.',
//                 style: TextStyle(fontSize: 16),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 24),
//               if (_stations.isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                   child: DropdownButtonFormField<int>(
//                     decoration: const InputDecoration(labelText: 'Selecciona una estación'),
//                     isExpanded: true,
//                     items: _stations.map((station) {
//                       return DropdownMenuItem<int>(
//                         value: station['id'],
//                         child: Text(station['code']),
//                       );
//                     }).toList(),
//                     onChanged: (value) {
//                       setState(() {
//                         _selectedStationId = value;
//                       });
//                     },
//                     validator: (value) =>
//                         value == null ? 'Por favor, selecciona una estación' : null,
//                   ),
//                 ),
//               if (_stations.isEmpty && !_isLoading)
//                 const Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 8.0),
//                   child: Text(
//                     'No se encontraron estaciones disponibles.',
//                     style: TextStyle(color: Colors.red),
//                   ),
//                 ),
//               const SizedBox(height: 24),
//               if (_isLoading)
//                 const Center(
//                   child: CircularProgressIndicator(),
//                 ),
//               if (!_isLoading)
//                 Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Center(
//                       child: SizedBox(
//                         width: screenWidth * 0.8,
//                         child: ElevatedButton.icon(
//                           onPressed: _submitForm,
//                           icon: const Icon(Icons.add_circle_outline),
//                           label: const Text('Activar Status'),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16.0),
//                   ],
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import '../api/profile_service.dart'; // Cambia el path si es necesario

import 'package:flutter/material.dart';
import '../api/profile_service.dart';
import 'package:zonix/features/GasTicket/gas_button/api/gas_ticket_service.dart';



class SelectStationModal extends StatefulWidget {
  final int userId;

  const SelectStationModal({super.key, required this.userId});

  @override
  State<SelectStationModal> createState() => _SelectStationModalState();
}

class _SelectStationModalState extends State<SelectStationModal> {
   final GasTicketService _ticketService = GasTicketService();
  List<Map<String, dynamic>> _stations = [];
  int? _selectedStationId; // Puede ser null inicialmente
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stations = await _ticketService.fetchStations();
       logger.i('Estaciones cargadas: $stations');
      setState(() {
        _stations = stations;
      });
    } catch (e) {
       setState(() {
          _error = 'Error al cargar las estaciones: ${e.toString()}';
        });
         logger.e('Error al cargar estaciones: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmSelection() async {
    if (_selectedStationId == null) { // Verifica que no sea null
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una estación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ProfileService().updateStatusCheckScanner(widget.userId, _selectedStationId!); // Usa '!' para confirmar que no es null
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado actualizado con éxito'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Cierra el modal
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar estación'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Text(_error!, style: const TextStyle(color: Colors.red))
              : DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Estación'),
                  isExpanded: true,
                  items: _stations.map((station) {
                    return DropdownMenuItem<int>(
                      value: station['id'],
                      child: Text(station['code']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStationId = value;
                    });
                  },
                   validator: (value) =>
                            value == null ? 'Por favor, selecciona una estación' : null,
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _confirmSelection,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}