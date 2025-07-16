import 'package:flutter/material.dart';

class CommerceDataPage extends StatefulWidget {
  const CommerceDataPage({Key? key}) : super(key: key);

  @override
  State<CommerceDataPage> createState() => _CommerceDataPageState();
}

class _CommerceDataPageState extends State<CommerceDataPage> {
  final _formKey = GlobalKey<FormState>();
  String _businessName = '';
  String _businessType = '';
  String _taxId = '';
  String _address = '';
  String _phone = '';
  String? _logoUrl;
  bool _open = false;
  String? _schedule;
  bool _loading = false;
  String? _error;
  String? _success;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _success = null; });
    _formKey.currentState!.save();
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _loading = false;
      _success = 'Datos del comercio actualizados correctamente.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos del comercio')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre comercial'),
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                onSaved: (v) => _businessName = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Tipo de negocio'),
                onSaved: (v) => _businessType = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'RIF / Tax ID'),
                onSaved: (v) => _taxId = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                onSaved: (v) => _address = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                onSaved: (v) => _phone = v ?? '',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('¿Comercio abierto?'),
                  Switch(
                    value: _open,
                    onChanged: (v) => setState(() => _open = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Horario (JSON o texto)'),
                onSaved: (v) => _schedule = v,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Logo:'),
                  const SizedBox(width: 12),
                  _logoUrl != null
                      ? Image.network(_logoUrl!, width: 48, height: 48)
                      : const Icon(Icons.image, size: 48, color: Colors.grey),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Subir logo'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_success != null) Text(_success!, style: const TextStyle(color: Colors.green)),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator() : const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 