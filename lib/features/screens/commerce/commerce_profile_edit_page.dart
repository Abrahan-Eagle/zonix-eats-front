import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zonix/features/services/commerce_data_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommerceProfileEditPage extends StatefulWidget {
  const CommerceProfileEditPage({
    Key? key,
    required this.initialData,
  }) : super(key: key);

  final Map<String, dynamic> initialData;

  @override
  State<CommerceProfileEditPage> createState() => _CommerceProfileEditPageState();
}

class _CommerceProfileEditPageState extends State<CommerceProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _addressController = TextEditingController();
  final _scheduleController = TextEditingController();

  bool _saving = false;
  String? _imagePath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.text = (widget.initialData['business_name'] ?? '').toString();
    _typeController.text = (widget.initialData['business_type'] ?? '').toString();
    _addressController.text = (widget.initialData['address'] ?? '').toString();
    final s = widget.initialData['schedule'];
    _scheduleController.text = s is Map
        ? (s['raw'] ?? '').toString()
        : (s ?? '').toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _addressController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: ImageSource.gallery);
      if (x != null && mounted) {
        setState(() => _imagePath = x.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_imagePath != null && _imagePath!.isNotEmpty) {
        await CommerceDataService.uploadCommerceImage(_imagePath!);
      }

      await CommerceDataService.updateCommerceData({
        'business_name': _nameController.text.trim(),
        'business_type': _typeController.text.trim(),
        'address': _addressController.text.trim(),
        'schedule': _scheduleController.text.trim().isEmpty
            ? null
            : _scheduleController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos guardados correctamente'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.initialData['image']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.red))),
                    ],
                  ),
                ),
              ],
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _imagePath != null
                          ? FileImage(File(_imagePath!))
                          : (imageUrl != null && imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null),
                      child: _imagePath == null &&
                              (imageUrl == null || imageUrl.isEmpty)
                          ? const Icon(Icons.store, size: 48, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        backgroundColor: AppColors.blue,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del negocio',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Tipo de negocio',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scheduleController,
                decoration: const InputDecoration(
                  labelText: 'Horarios',
                  hintText: 'Ej: Lun-Vie 9:00-18:00, Sáb 10:00-14:00',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
