import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/delivery_company_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

/// Formulario para que la delivery_company cree una cuenta de repartidor.
class DeliveryCompanyAddAgentPage extends StatefulWidget {
  const DeliveryCompanyAddAgentPage({super.key});

  @override
  State<DeliveryCompanyAddAgentPage> createState() => _DeliveryCompanyAddAgentPageState();
}

class _DeliveryCompanyAddAgentPageState extends State<DeliveryCompanyAddAgentPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  final _phone = TextEditingController();
  final _vehicleType = TextEditingController();
  final _licenseNumber = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    _phone.dispose();
    _vehicleType.dispose();
    _licenseNumber.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final service = context.read<DeliveryCompanyService>();
    final result = await service.createAgent(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      passwordConfirmation: _passwordConfirmation.text,
      phone: _phone.text.trim(),
      vehicleType: _vehicleType.text.trim(),
      licenseNumber: _licenseNumber.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agente creado. Puede iniciar sesión con su email y contraseña.')),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'No se pudo crear el agente. Revisa los datos.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar agente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.red)),
                ),
              ],
              TextFormField(
                controller: _firstName,
                decoration: const InputDecoration(labelText: 'Nombre'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastName,
                decoration: const InputDecoration(labelText: 'Apellido'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Correo (login)'),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Contraseña (mín. 8)'),
                obscureText: true,
                validator: (v) => (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordConfirmation,
                decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
                obscureText: true,
                validator: (v) => v != _password.text ? 'No coincide' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vehicleType,
                decoration: const InputDecoration(labelText: 'Tipo de vehículo (ej. moto)'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _licenseNumber,
                decoration: const InputDecoration(labelText: 'Número de licencia'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear agente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
