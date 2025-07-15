import 'package:flutter/material.dart';
import '../../../models/commerce_product.dart';
import '../../../services/commerce_product_service.dart';

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
  bool _available = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _available = widget.product!.available;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final data = {
        'name': _nameController.text,
        'description': _descController.text,
        'price': _priceController.text,
        'available': _available.toString(),
      };
      final service = CommerceProductService();
      if (widget.product == null) {
        await service.createProduct(data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto creado')));
      } else {
        await service.updateProduct(widget.product!.id, data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto actualizado')));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? 'Nuevo Producto' : 'Editar Producto')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _available,
                onChanged: (v) => setState(() => _available = v),
                title: const Text('Disponible'),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(widget.product == null ? 'Crear' : 'Guardar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
} 