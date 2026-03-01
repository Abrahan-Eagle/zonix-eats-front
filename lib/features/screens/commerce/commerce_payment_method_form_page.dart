import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/services/payment_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommercePaymentMethodFormPage extends StatefulWidget {
  const CommercePaymentMethodFormPage({
    super.key,
    this.method,
  });

  final Map<String, dynamic>? method;

  @override
  State<CommercePaymentMethodFormPage> createState() =>
      _CommercePaymentMethodFormPageState();
}

class _CommercePaymentMethodFormPageState
    extends State<CommercePaymentMethodFormPage> {
  final _formKey = GlobalKey<FormState>();

  late String _type;
  bool _isDefault = false;
  bool _isActive = true;

  final _aliasController = TextEditingController();
  final _notesController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _documentController = TextEditingController();
  final _phoneController = TextEditingController();
  final _accountController = TextEditingController();
  // Moneda principal: VES (Bs). El dólar se usa solo como referencia.
  final _currencyController = TextEditingController(text: 'VES');

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.method;
    _type = (m?['type'] ?? 'mobile_payment') as String;
    _isDefault = m?['is_default'] == true;
    _isActive = m?['is_active'] != false;

    final ref = (m?['reference_info'] is Map)
        ? Map<String, dynamic>.from(m!['reference_info'])
        : <String, dynamic>{};

    _aliasController.text = (ref['alias'] ?? '') as String;
    _notesController.text = (ref['notes'] ?? '') as String;
    _holderNameController.text = (m?['owner_name'] ?? '') as String;
    _documentController.text = (m?['owner_id'] ?? '') as String;
    _phoneController.text = (m?['phone'] ?? '') as String;
    _accountController.text = (m?['account_number'] ?? '') as String;
    _currencyController.text = (ref['currency'] ?? 'VES') as String;
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _notesController.dispose();
    _holderNameController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    _accountController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;

    setState(() => _saving = true);

    try {
      final referenceInfo = <String, dynamic>{
        'alias': _aliasController.text.trim(),
        'notes': _notesController.text.trim(),
        'currency': _currencyController.text.trim(),
      };

      final payload = <String, dynamic>{
        'type': _type,
        'owner_name': _holderNameController.text.trim().isEmpty
            ? null
            : _holderNameController.text.trim(),
        'owner_id': _documentController.text.trim().isEmpty
            ? null
            : _documentController.text.trim(),
        'is_default': _isDefault,
        'is_active': _isActive,
        'reference_info': referenceInfo,
      };

      if (_type == 'mobile_payment') {
        payload['phone'] =
            _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
      }

      if (_type == 'bank_transfer') {
        payload['account_number'] = _accountController.text.trim().isEmpty
            ? null
            : _accountController.text.trim();
      }

      final paymentService =
          Provider.of<PaymentService>(context, listen: false);

      if (widget.method == null) {
        await paymentService.addPaymentMethod(payload);
      } else {
        final id = widget.method!['id'] as int;
        await paymentService.updatePaymentMethod(id, payload);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.method != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar método de pago' : 'Nuevo método de pago'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo de método',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'mobile_payment',
                  child: Text('Pago móvil'),
                ),
                DropdownMenuItem(
                  value: 'bank_transfer',
                  child: Text('Transferencia bancaria'),
                ),
                DropdownMenuItem(
                  value: 'cash',
                  child: Text('Efectivo'),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text('Otro'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _type = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aliasController,
              decoration: const InputDecoration(
                labelText: 'Alias (nombre amigable)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa un alias' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _holderNameController,
              decoration: const InputDecoration(
                labelText: 'Titular (nombre)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _documentController,
              decoration: const InputDecoration(
                labelText: 'Cédula/RIF',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_type == 'mobile_payment')
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono de pago móvil',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (_type != 'mobile_payment') return null;
                  if (v == null || v.trim().isEmpty) {
                    return 'Ingresa el teléfono de pago móvil';
                  }
                  return null;
                },
              ),
            if (_type == 'bank_transfer') ...[
              TextFormField(
                controller: _accountController,
                decoration: const InputDecoration(
                  labelText: 'Número de cuenta',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (_type != 'bank_transfer') return null;
                  if (v == null || v.trim().isEmpty) {
                    return 'Ingresa el número de cuenta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _currencyController,
              decoration: const InputDecoration(
                labelText: 'Moneda principal (Bs / ref. USD)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas / instrucciones para el cliente',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Método activo'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            SwitchListTile(
              title: const Text('Predeterminado'),
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
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
              label: Text(_saving ? 'Guardando...' : 'Guardar método'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

