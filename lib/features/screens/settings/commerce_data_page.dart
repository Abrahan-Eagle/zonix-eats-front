import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zonix/features/services/commerce_data_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:flutter/services.dart'; // Added for FilteringTextInputFormatter

class CommerceDataPage extends StatefulWidget {
  const CommerceDataPage({super.key});

  @override
  State<CommerceDataPage> createState() => _CommerceDataPageState();
}

class _CommerceDataPageState extends State<CommerceDataPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String? _logoUrl;
  bool _open = false;
  String _schedule = '';
  bool _loading = false;
  bool _initialLoading = true;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadCommerceData();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessTypeController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCommerceData() async {
    try {
      setState(() {
        _initialLoading = true;
        _error = null;
      });

      final data = await CommerceDataService.getCommerceData();
      
      setState(() {
        _businessNameController.text = data['business_name'] ?? '';
        _businessTypeController.text = data['business_type'] ?? '';
        _taxIdController.text = data['tax_id'] ?? '';
        _addressController.text = data['address'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _logoUrl = data['image'];
        _open = data['open'] ?? false;
        _schedule = data['schedule'] ?? '';
        _initialLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
        _initialLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { 
      _loading = true; 
      _error = null; 
      _success = null; 
    });

    try {
      final data = {
        'business_name': _businessNameController.text,
        'business_type': _businessTypeController.text,
        'tax_id': _taxIdController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'image': _logoUrl,
        'open': _open,
        'schedule': _schedule,
      };

      final result = await CommerceDataService.updateCommerceData(data);
      
      setState(() {
        _loading = false;
        _success = result['message'] ?? 'Datos del comercio actualizados correctamente.';
      });

      // Limpiar mensaje de éxito después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _success = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error al actualizar datos: $e';
      });
    }
  }

  Future<void> _uploadLogo() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galería'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Cámara'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
              ],
            ),
          ),
        ),
      );
      if (source == null || !mounted) return;

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) return;

      setState(() {
        _loading = true;
        _error = null;
        _success = null;
      });

      final imageUrl = await CommerceDataService.uploadCommerceImage(pickedFile.path);

      if (!mounted) return;
      setState(() {
        _logoUrl = imageUrl;
        _loading = false;
        _success = 'Logo subido correctamente.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
      });
      final message = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir logo: $message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Datos del comercio'),
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos del comercio'),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Logo del comercio
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Logo del Comercio',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _logoUrl != null ? NetworkImage(_logoUrl!) : null,
                        child: _logoUrl == null 
                          ? const Icon(Icons.store, size: 50, color: Colors.grey)
                          : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _uploadLogo,
                        icon: const Icon(Icons.upload),
                        label: const Text('Subir logo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Información básica
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información Básica',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre comercial *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.store),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _businessTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de negocio',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _taxIdController,
                        decoration: const InputDecoration(
                          labelText: 'Cédula de Identidad (CI)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^[vVeE0-9]+')),
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Campo requerido';
                          if (!RegExp(r'^[vVeE][0-9]{7,9}$').hasMatch(v.trim())) return 'Formato válido: V12345678 o E12345678';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Información de contacto
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información de Contacto',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Campo requerido';
                          if (v.trim().length < 5) return 'Mínimo 5 caracteres';
                          if (v.trim().length > 200) return 'Máximo 200 caracteres';
                          return null;
                        },
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Campo requerido';
                          if (v.trim().length < 10) return 'Mínimo 10 dígitos';
                          if (v.trim().length > 15) return 'Máximo 15 dígitos';
                          if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Solo números';
                          return null;
                        },
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Estado del comercio
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado del Comercio',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.power_settings_new, color: AppColors.blue),
                          const SizedBox(width: 12),
                          const Text('Comercio abierto', style: TextStyle(fontSize: 16)),
                          const Spacer(),
                          Switch(
                            value: _open,
                            onChanged: (v) => setState(() => _open = v),
                            activeThumbColor: AppColors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _schedule,
                        onChanged: (v) => _schedule = v,
                        decoration: const InputDecoration(
                          labelText: 'Horario de atención',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                          hintText: 'Ej: Lunes a Viernes 8:00 AM - 6:00 PM',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Mensajes de estado
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              
              if (_success != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_success!, style: const TextStyle(color: Colors.green))),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Botón de guardar
              Container(
                width: double.infinity,
                height: 50,
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _loading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Guardar cambios',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
              
              // Espacio adicional para evitar overflow
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
} 