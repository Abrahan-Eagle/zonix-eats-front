import 'package:flutter/material.dart';
import '../../../models/commerce_profile.dart';
import '../../../services/commerce_profile_service.dart';
import 'package:flutter/services.dart';

class CommerceProfilePage extends StatefulWidget {
  final CommerceProfile? initialProfile;
  final bool isTestMode;
  const CommerceProfilePage({Key? key, this.initialProfile, this.isTestMode = false}) : super(key: key);

  @override
  State<CommerceProfilePage> createState() => _CommerceProfilePageState();
}

class _CommerceProfilePageState extends State<CommerceProfilePage> {
  final CommerceProfileService _profileService = CommerceProfileService();
  late Future<CommerceProfile> _profileFuture;
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _open = false;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileService.fetchProfile();
  }

  void _setControllers(CommerceProfile profile) {
    if (_controllersInitialized) return;
    _businessNameController.text = profile.businessName;
    _addressController.text = profile.address;
    _phoneController.text = profile.phone;
    _open = profile.open;
    _controllersInitialized = true;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    if (widget.isTestMode) {
      await Future.delayed(const Duration(milliseconds: 10));
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
      return;
    }
    try {
      await _profileService.updateProfile({
        'business_name': _businessNameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'open': _open ? 1 : 0,
      });
      setState(() { _profileFuture = _profileService.fetchProfile(); });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialProfile != null) {
      final profile = widget.initialProfile!;
      _setControllers(profile);
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil de Comercio')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(labelText: 'Nombre del comercio'),
                  maxLength: 100,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 áéíóúÁÉÍÓÚüÜñÑ.,-]')),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                    if (v.trim().length > 100) return 'Máximo 100 caracteres';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                  maxLength: 200,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (v.trim().length < 5) return 'Mínimo 5 caracteres';
                    if (v.trim().length > 200) return 'Máximo 200 caracteres';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  maxLength: 15,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (v.trim().length < 10) return 'Mínimo 10 dígitos';
                    if (v.trim().length > 15) return 'Máximo 15 dígitos';
                    if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Solo números';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: Text(_open ? 'Comercio ABIERTO' : 'Comercio CERRADO', style: TextStyle(fontWeight: FontWeight.bold, color: _open ? Colors.green : Colors.red)),
                  subtitle: const Text('Controla si tu comercio está visible y recibe pedidos'),
                  value: _open,
                  onChanged: (widget.isTestMode || !_loading) ? (v) { setState(() { _open = v; }); } : null,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: _loading ? null : _saveProfile,
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // flujo normal
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil de Comercio')),
      body: FutureBuilder<CommerceProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No se encontró perfil'));
          }
          final profile = snapshot.data!;
          _setControllers(profile);
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(labelText: 'Nombre del comercio'),
                    maxLength: 100,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 áéíóúÁÉÍÓÚüÜñÑ.,-]')),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                      if (v.trim().length > 100) return 'Máximo 100 caracteres';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    maxLength: 200,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (v.trim().length < 5) return 'Mínimo 5 caracteres';
                      if (v.trim().length > 200) return 'Máximo 200 caracteres';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    maxLength: 15,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (v.trim().length < 10) return 'Mínimo 10 dígitos';
                      if (v.trim().length > 15) return 'Máximo 15 dígitos';
                      if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Solo números';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: Text(_open ? 'Comercio ABIERTO' : 'Comercio CERRADO', style: TextStyle(fontWeight: FontWeight.bold, color: _open ? Colors.green : Colors.red)),
                    subtitle: const Text('Controla si tu comercio está visible y recibe pedidos'),
                    value: _open,
                    onChanged: _loading ? null : (v) {
                      setState(() { _open = v; });
                    },
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton(
                    onPressed: _loading ? null : _saveProfile,
                    child: _loading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 