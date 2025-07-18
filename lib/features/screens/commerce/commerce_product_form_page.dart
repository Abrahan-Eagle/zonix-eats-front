import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../models/commerce_product.dart';
import '../../../features/services/commerce_product_service.dart';
import 'package:flutter/services.dart';

class CommerceProductFormPage extends StatefulWidget {
  final CommerceProduct? product;
  const CommerceProductFormPage({Key? key, this.product}) : super(key: key);

  @override
  State<CommerceProductFormPage> createState() => _CommerceProductFormPageState();
}

class _CommerceProductFormPageState extends State<CommerceProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  bool _available = true;
  bool _loading = false;
  String? _error;
  File? _selectedImage;
  String? _currentImageUrl;
  int? _selectedCategoryId;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _available = widget.product!.available;
      _currentImageUrl = widget.product!.image;
      _stockController.text = widget.product!.stock?.toString() ?? '';
      _selectedCategoryId = widget.product!.categoryId;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() { _loadingCategories = true; });
    try {
      _categories = await CommerceProductService.getProductCategories();
    } catch (e) {
      _categories = [];
    } finally {
      setState(() { _loadingCategories = false; });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
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

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al tomar foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Imagen del Producto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: _showImagePickerDialog,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _currentImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _currentImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.fastfood,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: Colors.grey,
                            ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _showImagePickerDialog,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Seleccionar Imagen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Limpiar el campo de precio de símbolos y espacios
    String priceRaw = _priceController.text.trim().replaceAll(RegExp(r'[^0-9\.]'), '');
    double? priceValue = double.tryParse(priceRaw);
    if (priceValue == null) {
      setState(() { _error = 'El precio no es válido'; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El precio no es válido'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validar imagen si es obligatoria
    if (widget.product == null && _selectedImage == null) {
      setState(() { _error = 'Debes seleccionar una imagen para el producto.'; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar una imagen para el producto.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { 
      _loading = true; 
      _error = null; 
    });
    try {
      final data = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': priceValue,
        'available': _available,
        'stock': _stockController.text.isNotEmpty ? int.tryParse(_stockController.text) : null,
        'category_id': _selectedCategoryId,
      };

      if (widget.product == null) {
        // Crear nuevo producto
        await CommerceProductService.createProduct(data, imageFile: _selectedImage);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto creado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Actualizar producto existente
        await CommerceProductService.updateProduct(
          widget.product!.id, 
          data, 
          imageFile: _selectedImage
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
      // Mostrar error detallado del backend si existe
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error ?? 'Error desconocido'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Nuevo Producto' : 'Editar Producto'),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImageSection(),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Información del Producto',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Producto *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.fastfood),
                        counterText: '',
                      ),
                      maxLength: 100,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 áéíóúÁÉÍÓÚüÜñÑ.,-]')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        if (value.trim().length < 3) {
                          return 'El nombre debe tener al menos 3 caracteres';
                        }
                        if (value.trim().length > 100) {
                          return 'El nombre no puede exceder 100 caracteres';
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
                        counterText: '',
                      ),
                      maxLength: 500,
                      maxLines: 3,
                      validator: (value) {
                        if (value != null && value.trim().length > 500) {
                          return 'La descripción no puede exceder 500 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        suffixText: 'USD',
                        counterText: '',
                      ),
                      maxLength: 9,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^[0-9]{0,6}(\.[0-9]{0,2})?')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El precio es requerido';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Ingrese un precio válido mayor a 0';
                        }
                        if (value.contains('.') && value.split('.')[1].length > 2) {
                          return 'Máximo 2 decimales';
                        }
                        if (value.split('.')[0].length > 6) {
                          return 'Máximo 6 dígitos antes del punto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: _available,
                      onChanged: (value) => setState(() => _available = value),
                      title: const Text('Disponible'),
                      subtitle: const Text('El producto estará visible para los clientes'),
                      secondary: Icon(
                        _available ? Icons.check_circle : Icons.cancel,
                        color: _available ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                        counterText: '',
                      ),
                      maxLength: 5,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final stock = int.tryParse(value);
                          if (stock == null || stock < 0) {
                            return 'El stock debe ser un número entero positivo';
                          }
                          if (value.length > 5) {
                            return 'Máximo 5 dígitos';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _loadingCategories
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<int>(
                            value: _selectedCategoryId,
                            items: _categories.map((cat) => DropdownMenuItem<int>(
                              value: cat['id'],
                              child: Text(cat['name']),
                            )).toList(),
                            onChanged: (value) {
                              setState(() { _selectedCategoryId = value; });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            validator: (value) => value == null ? 'Selecciona una categoría' : null,
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.product == null ? 'Crear Producto' : 'Guardar Cambios',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 