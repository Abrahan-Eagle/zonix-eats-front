import 'package:flutter/material.dart';
import '../../services/commerce_delivery_zone_service.dart';

class CommerceDeliveryZoneFormPage extends StatefulWidget {
  final Map<String, dynamic>? zone;

  const CommerceDeliveryZoneFormPage({Key? key, this.zone}) : super(key: key);

  @override
  State<CommerceDeliveryZoneFormPage> createState() => _CommerceDeliveryZoneFormPageState();
}

class _CommerceDeliveryZoneFormPageState extends State<CommerceDeliveryZoneFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _feeController = TextEditingController();
  final _radiusController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.zone != null) {
      _nameController.text = widget.zone!['name'] ?? '';
      _descriptionController.text = widget.zone!['description'] ?? '';
      _feeController.text = widget.zone!['fee']?.toString() ?? '';
      _radiusController.text = widget.zone!['radius']?.toString() ?? '';
      _isActive = widget.zone!['is_active'] ?? true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _feeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'fee': double.tryParse(_feeController.text) ?? 0.0,
        'radius': double.tryParse(_radiusController.text) ?? 0.0,
        'is_active': _isActive,
      };

      if (widget.zone != null) {
        await CommerceDeliveryZoneService.updateDeliveryZone(
          widget.zone!['id'],
          data,
        );
      } else {
        await CommerceDeliveryZoneService.createDeliveryZone(data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.zone != null 
                ? 'Zona actualizada exitosamente' 
                : 'Zona creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.zone != null ? 'Editar Zona' : 'Nueva Zona'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la zona',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _feeController,
              decoration: const InputDecoration(
                labelText: 'Tarifa de envío',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La tarifa es requerida';
                }
                if (double.tryParse(value) == null) {
                  return 'Ingrese un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _radiusController,
              decoration: const InputDecoration(
                labelText: 'Radio (km)',
                border: OutlineInputBorder(),
                suffixText: 'km',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El radio es requerido';
                }
                if (double.tryParse(value) == null) {
                  return 'Ingrese un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Zona activa'),
              subtitle: const Text('La zona estará disponible para delivery'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.zone != null ? 'Actualizar Zona' : 'Crear Zona',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
