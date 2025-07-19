import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/phone.dart';
import '../api/phone_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditPhoneScreen extends StatefulWidget {
  final Phone phone;
  final int userId;

  const EditPhoneScreen({
    super.key, 
    required this.phone, 
    required this.userId,
  });

  @override
  EditPhoneScreenState createState() => EditPhoneScreenState();
}

class EditPhoneScreenState extends State<EditPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final PhoneService _phoneService = PhoneService();
  
  List<Map<String, dynamic>> _operatorCodes = [];
  int? _selectedOperatorCodeId;
  bool _isPrimary = false;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadOperatorCodes();
  }

  void _initializeData() {
    _numberController.text = widget.phone.number;
    _selectedOperatorCodeId = widget.phone.operatorCodeId;
    _isPrimary = widget.phone.isPrimary;
    _isActive = widget.phone.status;
    
    print('DEBUG: Initializing data for phone: ${widget.phone.id}');
    print('DEBUG: Original number: ${widget.phone.number}');
    print('DEBUG: Original operator code ID: ${widget.phone.operatorCodeId}');
    print('DEBUG: Original is primary: ${widget.phone.isPrimary}');
    print('DEBUG: Original status: ${widget.phone.status}');
    print('DEBUG: Controller text: ${_numberController.text}');
    print('DEBUG: Selected operator code: $_selectedOperatorCodeId');
    print('DEBUG: Is primary: $_isPrimary');
    print('DEBUG: Is active: $_isActive');
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

  Future<void> _updatePhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updates = {
        'operator_code_id': _selectedOperatorCodeId,
        'number': _numberController.text,
        'is_primary': _isPrimary ? 1 : 0,
        'status': _isActive ? 1 : 0,
      };

      print('DEBUG: Phone ID: ${widget.phone.id}');
      print('DEBUG: Updates: $updates');
      print('DEBUG: Selected operator code: $_selectedOperatorCodeId');
      print('DEBUG: Number: ${_numberController.text}');
      print('DEBUG: Is primary: $_isPrimary');
      print('DEBUG: Is active: $_isActive');

      await _phoneService.updatePhone(widget.phone.id, updates);
      
      _showSuccessSnackBar('Teléfono actualizado exitosamente');
      Navigator.pop(context, true);
    } catch (e) {
      print('DEBUG: Error updating phone: $e');
      _showErrorSnackBar('Error al actualizar teléfono: $e');
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
        title: const Text('Editar Teléfono'),
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
                  // Header con información actual
                  _buildCurrentPhoneCard(),
                  const SizedBox(height: 24.0),

                  // Formulario de edición
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                                                        // Código de operador y número
                                // En pantallas pequeñas, apilar verticalmente
                                if (MediaQuery.of(context).size.width < 400)
                                  Column(
                                    children: [
                                      DropdownButtonFormField<int>(
                                        value: _selectedOperatorCodeId,
                                        decoration: const InputDecoration(
                                          labelText: 'Código',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.phone_android),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                        ),
                                        items: _operatorCodes.map((code) {
                                          return DropdownMenuItem<int>(
                                            value: code['id'],
                                            child: Text(
                                              code['name'],
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 14),
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
                                            return 'Selecciona un código';
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
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(7),
                                        ],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Ingresa un número';
                                          } else if (value.length != 7) {
                                            return 'Debe tener 7 dígitos';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  )
                                else
                                  // En pantallas más grandes, usar Row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        flex: 1,
                                        child: DropdownButtonFormField<int>(
                                          value: _selectedOperatorCodeId,
                                          decoration: const InputDecoration(
                                            labelText: 'Código',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.phone_android),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                          ),
                                          isExpanded: true,
                                          items: _operatorCodes.map((code) {
                                            return DropdownMenuItem<int>(
                                              value: code['id'],
                                              child: Text(
                                                code['name'],
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 14),
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
                                              return 'Selecciona un código';
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
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(7),
                                          ],
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Ingresa un número';
                                            } else if (value.length != 7) {
                                              return 'Debe tener 7 dígitos';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                        const SizedBox(height: 24.0),

                        // Switches para estado principal y activo
                        _buildSwitchRow(),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: FloatingActionButton.extended(
              onPressed: _isLoading ? null : _updatePhone,
              tooltip: 'Actualizar Teléfono',
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Actualizando...' : 'Actualizar Teléfono'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildCurrentPhoneCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Teléfono Actual',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.phone.fullNumber,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(
                  widget.phone.typeText,
                  Color(widget.phone.typeColor),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  widget.phone.statusText,
                  Color(widget.phone.statusColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSwitchRow() {
    return Column(
      children: [
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
        const Divider(),
        SwitchListTile(
          title: const Text('Teléfono Activo'),
          subtitle: const Text('Habilitar o deshabilitar'),
          value: _isActive,
          onChanged: (value) {
            setState(() {
              _isActive = value;
            });
          },
          secondary: Icon(
            Icons.check_circle,
            color: _isActive ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }
} 