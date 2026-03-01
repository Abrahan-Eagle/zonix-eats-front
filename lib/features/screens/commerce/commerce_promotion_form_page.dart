import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zonix/features/services/commerce_promotion_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommercePromotionFormPage extends StatefulWidget {
  const CommercePromotionFormPage({super.key, this.promotionId, this.initialData});

  final int? promotionId;
  final Map<String, dynamic>? initialData;

  @override
  State<CommercePromotionFormPage> createState() =>
      _CommercePromotionFormPageState();
}

class _CommercePromotionFormPageState extends State<CommercePromotionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _minOrderController = TextEditingController(text: '0');
  final _maxDiscountController = TextEditingController();
  final _termsController = TextEditingController();
  final _discountValueController = TextEditingController(text: '0');

  String _discountType = 'percentage';
  DateTime? _startDate;
  DateTime? _endDate;
  int _priority = 0;
  bool _isActive = true;
  String? _imagePath;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _loadInitial();
    }
  }

  void _loadInitial() {
    final d = widget.initialData!;
    _titleController.text = (d['title'] ?? '').toString();
    _descController.text = (d['description'] ?? '').toString();
    _discountType = (d['discount_type'] ?? 'percentage').toString();
    _discountValueController.text = (d['discount_value'] ?? 0).toString();
    _minOrderController.text = (d['minimum_order'] ?? 0).toString();
    _maxDiscountController.text = (d['maximum_discount'] ?? '').toString();
    _termsController.text = (d['terms_conditions'] ?? '').toString();
    _priority = (d['priority'] ?? 0) as int;
    _isActive = d['is_active'] != false;
    if (d['start_date'] != null) {
      try {
        _startDate = DateTime.parse(d['start_date'].toString());
      } catch (_) {}
    }
    if (d['end_date'] != null) {
      try {
        _endDate = DateTime.parse(d['end_date'].toString());
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _termsController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x != null && mounted) setState(() => _imagePath = x.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _startDate = d);
  }

  Future<void> _pickEndDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 7)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (d != null) setState(() => _endDate = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona fechas de inicio y fin'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final discountVal = double.tryParse(_discountValueController.text) ?? 0;
      final data = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'discount_type': _discountType,
        'discount_value': discountVal,
        'minimum_order': double.tryParse(_minOrderController.text) ?? 0,
        'maximum_discount': double.tryParse(_maxDiscountController.text),
        'start_date': _startDate!.toIso8601String().split('T')[0],
        'end_date': _endDate!.toIso8601String().split('T')[0],
        'terms_conditions': _termsController.text.trim().isEmpty ? null : _termsController.text.trim(),
        'priority': _priority,
        'is_active': _isActive,
      };

      if (widget.promotionId != null) {
        await CommercePromotionService.updatePromotion(
          widget.promotionId!,
          data,
          imageFile: _imagePath != null ? File(_imagePath!) : null,
        );
      } else {
        await CommercePromotionService.createPromotion(
          data,
          imageFile: _imagePath != null ? File(_imagePath!) : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Promoción guardada'),
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
    final imageUrl = widget.initialData?['image_url']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.promotionId == null ? 'Nueva promoción' : 'Editar promoción'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: const TextStyle(color: AppColors.red)),
              ),
            ],
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                        )
                      : (imageUrl != null && imageUrl.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(imageUrl, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                                Text('Imagen', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
              maxLines: 2,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _discountType,
              decoration: const InputDecoration(labelText: 'Tipo de descuento', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'percentage', child: Text('Porcentaje')),
                DropdownMenuItem(value: 'fixed', child: Text('Monto fijo')),
              ],
              onChanged: (v) => setState(() => _discountType = v ?? 'percentage'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _discountValueController,
              decoration: const InputDecoration(labelText: 'Valor del descuento', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Ingresa un valor mayor a 0';
                if (_discountType == 'percentage' && n > 100) return 'Máximo 100%';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minOrderController,
              decoration: const InputDecoration(labelText: 'Pedido mínimo', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maxDiscountController,
              decoration: const InputDecoration(labelText: 'Descuento máximo (opcional)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(_startDate == null ? 'Fecha inicio' : 'Inicio: ${_startDate!.toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickStartDate,
            ),
            ListTile(
              title: Text(_endDate == null ? 'Fecha fin' : 'Fin: ${_endDate!.toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickEndDate,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _termsController,
              decoration: const InputDecoration(labelText: 'Términos y condiciones', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Prioridad:'),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _priority.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: '$_priority',
                    onChanged: (v) => setState(() => _priority = v.round()),
                  ),
                ),
                Text('$_priority'),
              ],
            ),
            SwitchListTile(
              title: const Text('Activa'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Guardando...' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
