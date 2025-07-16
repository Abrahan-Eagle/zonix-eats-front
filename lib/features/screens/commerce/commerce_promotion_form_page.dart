import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../features/services/commerce_promotion_service.dart';

class CommercePromotionFormPage extends StatefulWidget {
  final Map<String, dynamic>? promotion;
  const CommercePromotionFormPage({Key? key, this.promotion}) : super(key: key);

  @override
  State<CommercePromotionFormPage> createState() => _CommercePromotionFormPageState();
}

class _CommercePromotionFormPageState extends State<CommercePromotionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _priorityController = TextEditingController();
  final _termsController = TextEditingController();
  
  String _discountType = 'percentage';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  bool _loading = false;
  String? _error;
  File? _imageFile;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.promotion != null) {
      _loadPromotionData();
    }
  }

  void _loadPromotionData() {
    final promotion = widget.promotion!;
    _titleController.text = promotion['title'] ?? '';
    _descController.text = promotion['description'] ?? '';
    _discountValueController.text = (promotion['discount_value'] ?? 0.0).toString();
    _minOrderController.text = (promotion['minimum_order'] ?? 0.0).toString();
    _maxDiscountController.text = (promotion['maximum_discount'] ?? 0.0).toString();
    _priorityController.text = (promotion['priority'] ?? 1).toString();
    _termsController.text = promotion['terms_conditions'] ?? '';
    _discountType = promotion['discount_type'] ?? 'percentage';
    _startDate = DateTime.parse(promotion['start_date'] ?? DateTime.now().toIso8601String());
    _endDate = DateTime.parse(promotion['end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String());
    _isActive = promotion['is_active'] ?? true;
    _currentImageUrl = promotion['image_url'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _discountValueController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _priorityController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _savePromotion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _loading = true; _error = null; });

    try {
      final data = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'discount_type': _discountType,
        'discount_value': double.parse(_discountValueController.text),
        'minimum_order': double.parse(_minOrderController.text),
        'maximum_discount': double.parse(_maxDiscountController.text),
        'priority': int.parse(_priorityController.text),
        'terms_conditions': _termsController.text.trim(),
        'start_date': _startDate.toIso8601String(),
        'end_date': _endDate.toIso8601String(),
        'is_active': _isActive,
      };

      if (widget.promotion != null) {
        await CommercePromotionService.updatePromotion(
          widget.promotion!['id'],
          data,
          imageFile: _imageFile,
        );
      } else {
        await CommercePromotionService.createPromotion(
          data,
          imageFile: _imageFile,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.promotion != null 
              ? 'Promoción actualizada correctamente' 
              : 'Promoción creada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar promoción: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Widget _buildImageSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Imagen de la Promoción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _imageFile!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _currentImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _currentImageUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey,
                            ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Seleccionar Imagen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Básica',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título de la promoción *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El título es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de descuento *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.discount),
                    ),
                    value: _discountType,
                    items: const [
                      DropdownMenuItem(value: 'percentage', child: Text('Porcentaje (%)')),
                      DropdownMenuItem(value: 'fixed', child: Text('Monto fijo (\$)')),
                    ],
                    onChanged: (value) {
                      setState(() { _discountType = value!; });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _discountValueController,
                    decoration: InputDecoration(
                      labelText: _discountType == 'percentage' ? 'Porcentaje (%) *' : 'Monto (\$) *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El valor es requerido';
                      }
                      final num = double.tryParse(value);
                      if (num == null || num <= 0) {
                        return 'El valor debe ser mayor a 0';
                      }
                      if (_discountType == 'percentage' && num > 100) {
                        return 'El porcentaje no puede ser mayor a 100%';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Condiciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minOrderController,
                    decoration: const InputDecoration(
                      labelText: 'Pedido mínimo (\$)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_cart),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final num = double.tryParse(value);
                        if (num == null || num < 0) {
                          return 'El valor debe ser mayor o igual a 0';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxDiscountController,
                    decoration: const InputDecoration(
                      labelText: 'Descuento máximo (\$)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.trending_up),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final num = double.tryParse(value);
                        if (num == null || num < 0) {
                          return 'El valor debe ser mayor o igual a 0';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priorityController,
              decoration: const InputDecoration(
                labelText: 'Prioridad (1-10)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.priority_high),
                helperText: 'Las promociones con mayor prioridad se muestran primero',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final num = int.tryParse(value);
                  if (num == null || num < 1 || num > 10) {
                    return 'La prioridad debe estar entre 1 y 10';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fechas de Vigencia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Fecha de inicio'),
                    subtitle: Text(_formatDate(_startDate)),
                    onTap: () => _selectDate(true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Fecha de fin'),
                    subtitle: Text(_formatDate(_endDate)),
                    onTap: () => _selectDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Promoción activa'),
              subtitle: const Text('La promoción estará disponible para los clientes'),
              value: _isActive,
              onChanged: (value) {
                setState(() { _isActive = value; });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Términos y Condiciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _termsController,
              decoration: const InputDecoration(
                labelText: 'Términos y condiciones',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                helperText: 'Opcional: Términos específicos de esta promoción',
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.promotion != null ? 'Editar Promoción' : 'Crear Promoción'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            ListView(
              children: [
                _buildImageSection(),
                _buildBasicInfoSection(),
                _buildConditionsSection(),
                _buildDateSection(),
                _buildTermsSection(),
                const SizedBox(height: 100), // Espacio para el botón flotante
              ],
            ),
            if (_loading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _savePromotion,
        icon: const Icon(Icons.save),
        label: Text(widget.promotion != null ? 'Actualizar' : 'Crear'),
        tooltip: widget.promotion != null ? 'Actualizar promoción' : 'Crear promoción',
      ),
    );
  }
} 