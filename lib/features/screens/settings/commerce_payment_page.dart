import 'package:flutter/material.dart';
import 'package:zonix/features/services/commerce_data_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:flutter/services.dart'; // Added for FilteringTextInputFormatter

class CommercePaymentPage extends StatefulWidget {
  const CommercePaymentPage({Key? key}) : super(key: key);

  @override
  State<CommercePaymentPage> createState() => _CommercePaymentPageState();
}

class _CommercePaymentPageState extends State<CommercePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _paymentIdController = TextEditingController();
  final _paymentPhoneController = TextEditingController();
  
  String? _bank;
  bool _loading = false;
  bool _initialLoading = true;
  String? _error;
  String? _success;

  final List<String> _banks = [
    'Banco de Venezuela',
    'Banesco',
    'Mercantil',
    'BOD',
    'BNC',
    'Bancaribe',
    'Banco del Tesoro',
    'Banco Plaza',
    'BBVA Provincial',
    'Banco Exterior',
    'Banco Caroní',
    'Banco Sofitasa',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  @override
  void dispose() {
    _paymentIdController.dispose();
    _paymentPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentData() async {
    try {
      setState(() {
        _initialLoading = true;
        _error = null;
      });

      final data = await CommerceDataService.getCommerceData();
      
      setState(() {
        _bank = data['mobile_payment_bank'];
        _paymentIdController.text = data['mobile_payment_id'] ?? '';
        _paymentPhoneController.text = data['mobile_payment_phone'] ?? '';
        _initialLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
        _initialLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { 
      _loading = true; 
      _error = null; 
      _success = null; 
    });

    try {
      final data = {
        'bank': _bank,
        'payment_id': _paymentIdController.text,
        'payment_phone': _paymentPhoneController.text,
      };

      await CommerceDataService.updatePaymentData(data);
      
      setState(() {
        _loading = false;
        _success = 'Datos de pago móvil actualizados correctamente.';
      });

      // Limpiar mensaje de éxito después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _success = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error al actualizar datos: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Datos de pago móvil'),
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos de pago móvil'),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Información del banco
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información del Banco',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Banco *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                        value: _bank,
                        items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (v) => setState(() => _bank = v),
                        validator: (v) => v == null || v.isEmpty ? 'Seleccione un banco' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Información de pago móvil
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos de Pago Móvil',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _paymentIdController,
                        decoration: const InputDecoration(
                          labelText: 'ID de pago móvil *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.credit_card),
                          hintText: 'Ej: 12345678',
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _paymentPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono de pago móvil *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_android),
                          hintText: 'Ej: 04121234567',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Campo requerido';
                          final regex = RegExp(r'^\d{11}$');
                          if (!regex.hasMatch(v.replaceAll(RegExp(r'\D'), ''))) {
                            return 'Debe tener 11 dígitos';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Información adicional
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Información Importante',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• Los datos de pago móvil se utilizan para recibir pagos de los clientes\n'
                        '• Asegúrate de que el número de teléfono esté activo\n'
                        '• El ID de pago móvil debe ser el mismo registrado en tu banco\n'
                        '• Estos datos son confidenciales y seguros',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Mensajes de estado
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              
              if (_success != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_success!, style: const TextStyle(color: Colors.green))),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Botón de guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                  label: Text(
                    _loading ? 'Guardando...' : 'Guardar cambios',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ),
              
              // Espacio adicional para evitar overflow
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
} 