import 'package:flutter/material.dart';
import '../models/phone.dart';
import '../api/phone_service.dart';
import '../screens/create_phone_screen.dart';

class PhoneScreen extends StatefulWidget {
  final int userId;
  final bool statusId;

  
  const PhoneScreen({super.key, required this.userId, this.statusId = false});

  @override
  PhoneScreenState createState() => PhoneScreenState();
}

class PhoneScreenState extends State<PhoneScreen> {
  final PhoneService _phoneService = PhoneService();
  List<Phone> _phones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhones();
  }

  Future<void> _loadPhones() async {
    try {
      final phones = await _phoneService.fetchPhones(widget.userId);
      setState(() {
        _phones = phones;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      _showErrorSnackBar('Error al cargar teléfonos: $e');
    }
  }

  Future<void> _updatePhone(Phone phone, bool isPrimary) async {
    try {
      // Solo un teléfono puede ser principal, así que actualizamos la lista
      if (isPrimary) {
        _phones = _phones.map((p) {
          return p.id == phone.id ? p.copyWith(isPrimary: true) : p.copyWith(isPrimary: false);
        }).toList();
      } else {
        // Si se desactiva el switch, solo se actualiza el teléfono actual
        _phones = _phones.map((p) {
          return p.id == phone.id ? p.copyWith(isPrimary: false) : p;
        }).toList();
      }

      await _phoneService.updatePhone(phone.id, isPrimary);
      setState(() {}); // Actualizar la UI
    } catch (e) {
      _showErrorSnackBar('Error al actualizar teléfono: $e');
    }
  }

  Future<void> _deletePhone(int id) async {
    try {
      await _phoneService.deletePhone(id);
      _loadPhones();
    } catch (e) {
      _showErrorSnackBar('Error al eliminar teléfono: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teléfonos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _phones.isEmpty
              ? const Center(child: Text('No hay teléfonos disponibles.'))
              : ListView.builder(
                  itemCount: _phones.length,
                  itemBuilder: (context, index) {
                    final phone = _phones[index];
                    return ListTile(
                      title: Text('${phone.operatorCodeName} - ${phone.number}'),
                      subtitle: Text(
                        phone.isPrimary ? 'Principal' : 'Secundario',
                      ),
                      trailing: Switch(
                        value: phone.isPrimary,
                        onChanged: (value) async {
                          await _updatePhone(phone, value);
                        },
                      ),
                      onLongPress: () => _deletePhone(phone.id),
                    );
                  },
                ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     // Navegar al formulario para agregar un teléfono.
      //     final result = await Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => CreatePhoneScreen(userId: widget.userId),
      //       ),
      //     );

      //     // Opcional: Puedes manejar el resultado aquí si es necesario
      //     if (result == true) {
      //       _loadPhones(); // Recargar teléfonos si se ha creado uno nuevo
      //     }
      //   },
      //   child: const Icon(Icons.add),
      // ),





  floatingActionButton: Stack(
        children: [
          // El botón de creación de documentos
          Positioned(
            right: 10,
            bottom: 20,
            child: FloatingActionButton(
              // onPressed: () => _navigateToCreateDocument(context),


  onPressed: () async {
          // Navegar al formulario para agregar un teléfono.
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePhoneScreen(userId: widget.userId),
            ),
          );

          // Opcional: Puedes manejar el resultado aquí si es necesario
          if (result == true) {
            _loadPhones(); // Recargar teléfonos si se ha creado uno nuevo
          }
        },

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
                      await PhoneService().updateStatusCheckScanner(widget.userId);

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
