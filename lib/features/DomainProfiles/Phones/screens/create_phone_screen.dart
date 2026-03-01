import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/phone.dart';
import '../api/phone_service.dart';
import 'package:zonix/features/utils/user_provider.dart';
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
  
  List<Map<String, dynamic>> _operatorCodes = [];
  int? _selectedOperatorCodeId;
  bool _isLoading = false;
  bool _isPrimary = true;

  @override
  void initState() {
    super.initState();
    _loadOperatorCodes();
  }

  Future<void> _loadOperatorCodes() async {
    try {
      final codes = await _phoneService.fetchOperatorCodes();
      setState(() {
        _operatorCodes = codes;
      });
    } catch (e) {
      _showErrorSnackBar('Error al cargar códigos de operador: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _createPhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final phone = Phone(
        id: 0,
        profileId: widget.userId,
        operatorCodeId: _selectedOperatorCodeId!,
        operatorCodeName: _operatorCodes
            .firstWhere((code) => code['id'] == _selectedOperatorCodeId)['name'],
        number: _numberController.text,
        isPrimary: _isPrimary,
        status: true,
      );

      await _phoneService.createPhone(phone, widget.userId);

      if (!context.mounted) return;
      final c = context;
      c.read<UserProvider>().setPhoneCreated(true);
      _showSuccessSnackBar('Teléfono creado exitosamente');
      Navigator.pop(c, true);
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar('Error al crear teléfono: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Teléfono'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 24.0),

                  // Formulario
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildPhoneForm(),
                        const SizedBox(height: 24.0),
                        _buildOptionsSection(),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.add_call,
              size: 48,
              color: Colors.blue,
            ),
            SizedBox(height: 12),
            Text(
              'Registra tu nuevo número de teléfono',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Completa la información para agregar un nuevo teléfono a tu perfil',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      children: [
        // En pantallas pequeñas, apilar verticalmente
        if (MediaQuery.of(context).size.width < 400)
          Column(
            children: [
              DropdownButtonFormField<int>(
                initialValue: _selectedOperatorCodeId,
                decoration: const InputDecoration(
                  labelText: 'Código de Operador',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_android),
                ),
                items: _operatorCodes.map((code) {
                  return DropdownMenuItem<int>(
                    value: code['id'],
                    child: Text(
                      code['name'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedOperatorCodeId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecciona un código de operador';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Teléfono',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '1234567',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un número de teléfono';
                  } else if (value.length != 7) {
                    return 'El número debe tener exactamente 7 dígitos';
                  }
                  return null;
                },
              ),
            ],
          )
        else
          // En pantallas más grandes, usar Row
          Row(
            children: [
              Flexible(
                flex: 1,
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedOperatorCodeId,
                  decoration: const InputDecoration(
                    labelText: 'Código de Operador',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                  items: _operatorCodes.map((code) {
                    return DropdownMenuItem<int>(
                      value: code['id'],
                      child: Text(
                        code['name'],
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedOperatorCodeId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecciona un código de operador';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16.0),
              Flexible(
                flex: 2,
                child: TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                    labelText: 'Número de Teléfono',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: '1234567',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(7),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa un número de teléfono';
                    } else if (value.length != 7) {
                      return 'El número debe tener exactamente 7 dígitos';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Opciones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Teléfono Principal'),
              subtitle: const Text('Marcar como número principal'),
              value: _isPrimary,
              onChanged: (value) {
                setState(() {
                  _isPrimary = value;
                });
              },
              secondary: Icon(
                Icons.star,
                color: _isPrimary ? Colors.amber : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: FloatingActionButton.extended(
            heroTag: 'create_phone_save',
            onPressed: _isLoading ? null : _createPhone,
            tooltip: 'Registrar Teléfono',
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.phone),
            label: Text(_isLoading ? 'Creando...' : 'Registrar Teléfono'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }
}
