import 'package:flutter/material.dart';

class CommerceSchedulePage extends StatefulWidget {
  const CommerceSchedulePage({Key? key}) : super(key: key);

  @override
  State<CommerceSchedulePage> createState() => _CommerceSchedulePageState();
}

class _CommerceSchedulePageState extends State<CommerceSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  String _schedule = '';
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
      _success = 'Horario actualizado correctamente.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horario de atención')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Horario',
                  hintText: 'Ejemplo:\nL-V 8:00-18:00\nS 9:00-14:00\nD cerrado',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                onSaved: (v) => _schedule = v ?? '',
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