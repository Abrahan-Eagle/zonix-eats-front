import 'package:flutter/material.dart';

class CommercePaymentPage extends StatefulWidget {
  const CommercePaymentPage({Key? key}) : super(key: key);

  @override
  State<CommercePaymentPage> createState() => _CommercePaymentPageState();
}

class _CommercePaymentPageState extends State<CommercePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  String? _bank;
  String _paymentId = '';
  String _paymentPhone = '';
  bool _loading = false;
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
    'Otro',
  ];

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _success = null; });
    _formKey.currentState!.save();
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _loading = false;
      _success = 'Datos de pago móvil actualizados correctamente.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos de pago móvil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Banco'),
                value: _bank,
                items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => _bank = v),
                validator: (v) => v == null || v.isEmpty ? 'Seleccione un banco' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'ID de pago móvil'),
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                onSaved: (v) => _paymentId = v ?? '',
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Teléfono de pago móvil'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo requerido';
                  final regex = RegExp(r'^\d{11} ?$');
                  if (!regex.hasMatch(v)) return 'Debe tener 11 dígitos';
                  return null;
                },
                onSaved: (v) => _paymentPhone = v ?? '',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_success != null) Text(_success!, style: const TextStyle(color: Colors.green)),
              ElevatedButton.icon(
                icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                label: const Text('Guardar cambios'),
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 