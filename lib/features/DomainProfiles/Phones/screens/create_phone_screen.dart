import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importar para usar FilteringTextInputFormatter
import '../models/phone.dart';
import '../api/phone_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zonix_eats/features/utils/user_provider.dart';
import 'package:provider/provider.dart';

class CreatePhoneScreen extends StatefulWidget {
  final int userId;

  const CreatePhoneScreen({super.key, required this.userId});

  @override
  CreatePhoneScreenState createState() => CreatePhoneScreenState();
}

class CreatePhoneScreenState extends State<CreatePhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final PhoneService _phoneService = PhoneService();
  List<Map<String, dynamic>> _operatorCodes = []; // Lista para los códigos de operador
  int? _selectedOperatorCodeId; // Almacena el ID del código seleccionado

  @override
  void initState() {
    super.initState();
    _loadOperatorCodes(); // Cargar códigos de operador al iniciar
  }

  Future<void> _loadOperatorCodes() async {
    try {
      final codes = await _phoneService.fetchOperatorCodes(); // Método para obtener los códigos de operador
      setState(() {
        _operatorCodes = codes; // Almacenar la lista de códigos
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los códigos de operador: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos las dimensiones de la pantalla
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Teléfono'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Registra tu nuevo número de teléfono aquí:',
                      style: TextStyle(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),

                    // Imagen SVG responsiva
                    SvgPicture.asset(
                      'assets/images/undraw_insert_re_s97w.svg',
                      height: size.height * 0.3,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24.0),

                    // Formulario de creación
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // DropdownButtonFormField primero
                              Flexible(
                                flex: 1, // Menos espacio para el DropdownButtonFormField
                                child: DropdownButtonFormField<int>(
                                  value: _selectedOperatorCodeId,
                                  decoration: const InputDecoration(
                                    labelText: 'Código',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _operatorCodes.map((code) {
                                    return DropdownMenuItem<int>(
                                      value: code['id'],
                                      child: Text(code['name']),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedOperatorCodeId = value; // Guardar el ID seleccionado
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Por favor selecciona un código de operador';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16.0), // Espacio entre los campos
                              Flexible(
                                flex: 2, // Más espacio para el TextFormField
                                child: TextFormField(
                                  controller: _numberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Número de Teléfono',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number, // Solo permite números
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly, // Solo dígitos
                                    LengthLimitingTextInputFormatter(7), // Limitar a 7 dígitos
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingresa un número de teléfono';
                                    } else if (value.length != 7) {
                                      return 'El número debe tener exactamente 7 dígitos';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24.0),
                        ],
                      ),
                    ),

                    // Botón de creación con ícono, separado del formulario
                    const SizedBox(height: 150.0),
                    // ElevatedButton.icon(
                    //   onPressed: _createPhone,
                    //   icon: const Icon(Icons.phone),
                    //   label: const Text('Registrar Teléfono'),
                    //   style: ElevatedButton.styleFrom(
                    //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    //     minimumSize: const Size(double.infinity, 48),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      // FloatingActionButton
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min, // Minimiza el espacio ocupado por la columna
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8, // 80% del ancho de la pantalla
            child: FloatingActionButton.extended(
              onPressed: _createPhone,
              tooltip: 'Registrar Teléfono',
              icon: const Icon(Icons.phone),
              label: const Text('Registrar Teléfono'),
            ),
          ),
          const SizedBox(height: 16.0), // Espaciador
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Future<void> _createPhone() async {
  //   if (_formKey.currentState!.validate()) {
  //     final phone = Phone(
  //       id: 0, // Se generará en el backend
  //       profileId: widget.userId,
  //       operatorCodeId: _selectedOperatorCodeId!, // Usar el ID seleccionado
  //       operatorCodeName: '', // Puedes cambiar esto si tienes un método para obtener el nombre
  //       number: _numberController.text,
  //       isPrimary: true, // Establecer is_primary como true al crear
  //       status: true,
  //     );

  //     try {
  //       await _phoneService.createPhone(phone, widget.userId); // Suponiendo que tienes este método en el servicio
  //       context.read<UserProvider>().setPhoneCreated(true);
  //       Navigator.pop(context, true); // Devolver true para indicar éxito
  //     } catch (e) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error al crear el teléfono: $e')),
  //       );
  //     }
  //   }
  // }


Future<void> _createPhone() async {
  if (_formKey.currentState!.validate()) {
    final phone = Phone(
      id: 0, // Generado en el backend
      profileId: widget.userId,
      operatorCodeId: _selectedOperatorCodeId!,
      operatorCodeName: '', // Puedes modificarlo según tu lógica
      number: _numberController.text,
      isPrimary: true,
      status: true,
    );

    try {
      await _phoneService.createPhone(phone, widget.userId);
      context.read<UserProvider>().setPhoneCreated(true); // Actualiza el estado
      Navigator.pop(context, true); // Devuelve `true` para indicar éxito
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear el teléfono: $e')),
      );
    }
  }
}



}
