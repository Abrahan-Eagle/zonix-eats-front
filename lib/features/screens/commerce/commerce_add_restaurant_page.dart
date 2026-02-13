import 'package:flutter/material.dart';
import 'package:zonix/features/services/commerce_list_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

/// Formulario para agregar un nuevo restaurante (multi-restaurante).
class CommerceAddRestaurantPage extends StatefulWidget {
  const CommerceAddRestaurantPage({super.key});

  @override
  State<CommerceAddRestaurantPage> createState() => _CommerceAddRestaurantPageState();
}

class _CommerceAddRestaurantPageState extends State<CommerceAddRestaurantPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _scheduleController = TextEditingController();

  String _selectedBusinessType = 'restaurant';
  bool _open = false;
  bool _loading = false;
  String? _error;

  static const _businessTypes = ['restaurant', 'cafe', 'bakery', 'fast_food', 'pizzeria', 'bar', 'food_truck'];

  @override
  void dispose() {
    _businessNameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await CommerceListService.createCommerce(
        businessName: _businessNameController.text.trim(),
        businessType: _selectedBusinessType,
        taxId: _taxIdController.text.trim(),
        address: _addressController.text.trim(),
        open: _open,
        schedule: _scheduleController.text.trim().isEmpty ? null : _scheduleController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar restaurante'),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del negocio',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedBusinessType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de negocio',
                  border: OutlineInputBorder(),
                ),
                items: _businessTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _selectedBusinessType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taxIdController,
                decoration: const InputDecoration(
                  labelText: 'RIF / NIT / RUC',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección / Ubicación',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scheduleController,
                decoration: const InputDecoration(
                  labelText: 'Horario (opcional)',
                  hintText: 'Ej: Lun-Vie 8:00-22:00',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Abierto'),
                value: _open,
                onChanged: (v) => setState(() => _open = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Crear restaurante'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
