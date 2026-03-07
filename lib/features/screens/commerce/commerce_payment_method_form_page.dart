import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../config/app_config.dart';
import '../../../helpers/auth_helper.dart';
import 'package:zonix/features/services/payment_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix/features/DomainProfiles/Phones/api/phone_service.dart';
import 'package:zonix/features/DomainProfiles/Phones/models/phone.dart';
import 'package:zonix/features/DomainProfiles/Documents/api/document_service.dart';
import 'package:zonix/features/DomainProfiles/Documents/models/document.dart';
import 'package:zonix/features/utils/rif_formatter.dart';

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
  final _currencyController = TextEditingController(text: 'VES');
  final _platformController = TextEditingController();
  final _emailWalletController = TextEditingController();
  final _last4Controller = TextEditingController();
  final _expMonthController = TextEditingController();
  final _expYearController = TextEditingController();
  final _cardholderController = TextEditingController();
  final _brandController = TextEditingController();

  bool _saving = false;
  List<Map<String, dynamic>> _banks = [];
  int? _selectedBankId;

  List<Phone> _phones = [];
  List<Document> _documents = [];
  String? _selectedPhoneValue;
  String? _selectedDocumentOwnerId;
  bool _useManualDocument = false;
  String _documentPrefix = 'V';
  bool _loadingPhonesDocs = false;

  static const List<String> _walletPlatforms = ['PayPal', 'Zelle', 'Binance Pay', 'Otro'];
  static const List<String> _cardBrands = ['Visa', 'Mastercard', 'American Express', 'Otro'];

  static String _formatDocDisplay(Document doc) {
    if (doc.type == 'ci' && doc.numberCi != null && doc.numberCi!.isNotEmpty) {
      final digits = doc.numberCi!.replaceAll(RegExp(r'\D'), '');
      return 'V-${_addDots(digits)}';
    }
    if (doc.type == 'rif') {
      return doc.formattedRifNumber ?? 'RIF no indicado';
    }
    return doc.numberCi ?? 'Doc #${doc.id}';
  }

  static String _addDots(String digits) {
    if (digits.length <= 3) return digits;
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  static String _formatOwnerIdFromDoc(Document doc) {
    if (doc.type == 'ci' && doc.numberCi != null && doc.numberCi!.isNotEmpty) {
      final digits = doc.numberCi!.replaceAll(RegExp(r'\D'), '');
      return 'V-${_addDots(digits)}';
    }
    if (doc.type == 'rif') {
      return doc.formattedRifNumber ?? '';
    }
    return doc.numberCi ?? '';
  }

  /// Formatea RIF a J-19217553-0 / V-19217553-0; deja CI u otros valores como están.
  static String? _formatOwnerIdForPayload(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return formatRifDisplay(t) ?? t;
  }

  Future<void> _loadPhonesAndDocuments() async {
    final profile = await ProfileService().getMyProfile();
    if (profile == null || !mounted) return;
    setState(() => _loadingPhonesDocs = true);
    try {
      final phoneService = PhoneService();
      final documentService = DocumentService();
      final phones = await phoneService.fetchPhones(profile.userId);
      final documents = await documentService.fetchMyDocuments();
      if (mounted) {
        setState(() {
          _phones = phones;
          _documents = documents.where((d) => d.type == 'ci' || d.type == 'rif').toList();
          _loadingPhonesDocs = false;
          if (_phones.isNotEmpty && _phoneController.text.trim().isNotEmpty) {
            final current = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
            final matchList = _phones.where((p) {
              final full = '${p.operatorCodeName.replaceAll(RegExp(r'\D'), '')}${p.number}';
              return full == current || full.endsWith(p.number);
            }).toList();
            if (matchList.isNotEmpty) {
              final p = matchList.first;
              _selectedPhoneValue = '${p.operatorCodeName.replaceAll(RegExp(r'\D'), '')}${p.number}';
            }
          }
          if (_documents.isEmpty || _documentController.text.trim().isNotEmpty) {
            _useManualDocument = true;
            final t = _documentController.text.trim();
            if (t.startsWith('J')) _documentPrefix = 'J';
          } else {
            final current = _documentController.text.trim();
            final docList = _documents.where((d) => _formatOwnerIdFromDoc(d) == current).toList();
            if (docList.isNotEmpty) _selectedDocumentOwnerId = _formatOwnerIdFromDoc(docList.first);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPhonesDocs = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final m = widget.method;
    final ref = (m != null && m['reference_info'] is Map)
        ? Map<String, dynamic>.from(m['reference_info'] as Map)
        : <String, dynamic>{};
    final rawType = (m?['type'] ?? 'mobile_payment') as String;
    _type = (rawType == 'other' && ref['display_type'] == 'digital_wallet')
        ? 'digital_wallet'
        : rawType;
    _isDefault = m?['is_default'] == true;
    _isActive = m?['is_active'] != false;

    _aliasController.text = (ref['alias'] ?? '') as String;
    _notesController.text = (ref['notes'] ?? '') as String;
    _holderNameController.text = (m?['owner_name'] ?? '') as String;
    final ownerId = (m?['owner_id'] ?? '') as String;
    _documentController.text = _formatOwnerIdForPayload(ownerId) ?? ownerId;
    _phoneController.text = (m?['phone'] ?? '') as String;
    _accountController.text = (m?['account_number'] ?? '') as String;
    _currencyController.text = (ref['currency'] ?? 'VES') as String;
    _platformController.text = (ref['platform'] ?? 'PayPal') as String;
    _emailWalletController.text = (ref['email'] ?? m?['email'] ?? '') as String;
    _last4Controller.text = (m?['last4'] ?? ref['last4'] ?? '') as String;
    _expMonthController.text = m?['exp_month']?.toString() ?? '';
    _expYearController.text = m?['exp_year']?.toString() ?? '';
    _cardholderController.text = (m?['cardholder_name'] ?? ref['holder'] ?? m?['owner_name'] ?? '') as String;
    _brandController.text = (m?['brand'] ?? 'Visa') as String;
    if (m?['bank_id'] != null) _selectedBankId = m!['bank_id'] as int?;
    _loadBanks();
    _loadPhonesAndDocuments();
  }

  Future<void> _loadBanks() async {
    try {
      final url = Uri.parse('${AppConfig.apiUrl}/api/banks');
      final response = await http.get(url, headers: await AuthHelper.getAuthHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          if (mounted) {
            setState(() {
              _banks = List<Map<String, dynamic>>.from(data['data'] as List);
              if (_selectedBankId == null && _banks.isNotEmpty && widget.method?['bank_id'] != null) {
                _selectedBankId = widget.method!['bank_id'] as int?;
              }
            });
          }
        }
      }
    } catch (_) {}
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
    _platformController.dispose();
    _emailWalletController.dispose();
    _last4Controller.dispose();
    _expMonthController.dispose();
    _expYearController.dispose();
    _cardholderController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    if (_type == 'mobile_payment') {
      final phoneVal = _selectedPhoneValue ?? _phoneController.text.trim();
      if (phoneVal.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa o selecciona el teléfono de pago móvil'), backgroundColor: AppColors.red),
        );
        return;
      }
      final docVal = _selectedDocumentOwnerId ?? _documentController.text.trim();
      if (docVal.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona o ingresa Cédula/RIF (Ajustes > Documentos si aún no tienes)'),
            backgroundColor: AppColors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final currency = _type == 'mobile_payment' ? 'VES' : _currencyController.text.trim();
      final referenceInfo = <String, dynamic>{
        'alias': _aliasController.text.trim(),
        'notes': _notesController.text.trim(),
        'currency': currency,
      };
      if (_type == 'digital_wallet') {
        referenceInfo['display_type'] = 'digital_wallet';
        referenceInfo['platform'] = _platformController.text.trim().isEmpty
            ? 'PayPal'
            : _platformController.text.trim();
        referenceInfo['email'] = _emailWalletController.text.trim().isEmpty
            ? null
            : _emailWalletController.text.trim();
      }
      if (_type == 'card') {
        referenceInfo['exp'] = '${_expMonthController.text.padLeft(2, '0')}/${_expYearController.text}';
        referenceInfo['holder'] = _cardholderController.text.trim();
      }

      // Algunos backends solo aceptan mobile_payment, bank_transfer, cash, other
      final typeToSend = _type == 'digital_wallet' ? 'other' : _type;
      final payload = <String, dynamic>{
        'type': typeToSend,
        'owner_name': _holderNameController.text.trim().isEmpty
            ? null
            : _holderNameController.text.trim(),
        'owner_id': _formatOwnerIdForPayload(_selectedDocumentOwnerId ?? _documentController.text.trim()),
        'is_default': _isDefault,
        'is_active': _isActive,
        'reference_info': referenceInfo,
      };

      if (_selectedBankId != null) payload['bank_id'] = _selectedBankId;

      if (_type == 'mobile_payment') {
        final phoneVal = _selectedPhoneValue ?? _phoneController.text.trim();
        payload['phone'] = phoneVal.isEmpty ? null : phoneVal.replaceAll(RegExp(r'\D'), '');
      }

      if (_type == 'bank_transfer') {
        payload['account_number'] = _accountController.text.trim().isEmpty
            ? null
            : _accountController.text.trim();
      }

      if (_type == 'card') {
        payload['brand'] = _brandController.text.trim().isEmpty ? null : _brandController.text.trim();
        payload['last4'] = _last4Controller.text.trim().isEmpty ? null : _last4Controller.text.trim();
        final month = int.tryParse(_expMonthController.text.trim());
        final year = int.tryParse(_expYearController.text.trim());
        if (month != null) payload['exp_month'] = month;
        if (year != null) payload['exp_year'] = year;
        payload['cardholder_name'] = _cardholderController.text.trim().isEmpty
            ? null
            : _cardholderController.text.trim();
        payload['owner_name'] = _cardholderController.text.trim().isEmpty
            ? _holderNameController.text.trim().isEmpty ? null : _holderNameController.text.trim()
            : _cardholderController.text.trim();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.scaffoldBgLight;
    final cardBg = AppColors.cardBg(context);
    final primaryText = AppColors.primaryText(context);
    final secondaryText = AppColors.secondaryText(context);
    final borderColor = isDark ? AppColors.stitchSurfaceLighter : AppColors.stitchBorder;
    final inputBg = isDark ? AppColors.grayDark : AppColors.stitchBgCard;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Editar método de pago' : 'Nuevo método de pago',
          style: const TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.stitchNavBg,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined, color: AppColors.white),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!isEdit || _type != 'mobile_payment')
              _card(
                context,
                cardBg,
                borderColor,
                primaryText,
                secondaryText,
                inputBg,
                'Tipo de método',
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'card', child: Text('Tarjeta')),
                    DropdownMenuItem(value: 'mobile_payment', child: Text('Pago móvil')),
                    DropdownMenuItem(value: 'bank_transfer', child: Text('Transferencia bancaria')),
                    DropdownMenuItem(value: 'digital_wallet', child: Text('Billetera digital')),
                    DropdownMenuItem(value: 'other', child: Text('Otro')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _type = v);
                  },
                ),
              ),
            if (!isEdit || _type != 'mobile_payment') const SizedBox(height: 12),
            _card(
              context,
              cardBg,
              borderColor,
              primaryText,
              secondaryText,
              inputBg,
              'Alias (nombre amigable) *',
              TextFormField(
                controller: _aliasController,
                decoration: _inputDecoration(inputBg, borderColor, 'Ej. Mi cuenta personal'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa un alias' : null,
              ),
            ),
            const SizedBox(height: 12),
            _card(
              context,
              cardBg,
              borderColor,
              primaryText,
              secondaryText,
              inputBg,
              'Titular (nombre)',
              TextFormField(
                controller: _holderNameController,
                decoration: _inputDecoration(inputBg, borderColor, 'Nombre del titular'),
              ),
            ),
            const SizedBox(height: 12),
            _card(
              context,
              cardBg,
              borderColor,
              primaryText,
              secondaryText,
              inputBg,
              'Cédula/RIF',
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text('Tipo:', style: TextStyle(fontSize: 12, color: secondaryText)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _documentPrefix,
                        isExpanded: false,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'V', child: Text('V (Cédula)')),
                          DropdownMenuItem(value: 'J', child: Text('J (RIF)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _documentPrefix = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_documents.isNotEmpty && !_useManualDocument)
                    DropdownButtonFormField<String>(
                      value: _selectedDocumentOwnerId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      hint: const Text('Seleccionar documento'),
                      items: [
                        ..._documents.map((d) {
                          final id = _formatOwnerIdFromDoc(d);
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(_formatDocDisplay(d), overflow: TextOverflow.ellipsis),
                          );
                        }),
                        const DropdownMenuItem<String>(
                          value: '__manual__',
                          child: Text('Ingresar manualmente'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          if (v == '__manual__') {
                            _useManualDocument = true;
                            _selectedDocumentOwnerId = null;
                          } else {
                            _selectedDocumentOwnerId = v;
                            _useManualDocument = false;
                            _documentController.text = v ?? '';
                          }
                        });
                      },
                    )
                  else
                    TextFormField(
                      controller: _documentController,
                      decoration: _inputDecoration(
                        inputBg,
                        borderColor,
                        _documentPrefix == 'V' ? 'V-19.217.553' : 'J-19.217.553-0',
                      ),
                    ),
                  if (_documents.isNotEmpty && _useManualDocument)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          _useManualDocument = false;
                          _selectedDocumentOwnerId = _documents.isNotEmpty ? _formatOwnerIdFromDoc(_documents.first) : null;
                          _documentController.text = _selectedDocumentOwnerId ?? '';
                        }),
                        icon: const Icon(Icons.list, size: 18),
                        label: const Text('Elegir de mis documentos'),
                      ),
                    ),
                ],
              ),
            ),
            if (_type == 'mobile_payment' || _type == 'bank_transfer') ...[
              const SizedBox(height: 12),
              _card(
                context,
                cardBg,
                borderColor,
                primaryText,
                secondaryText,
                inputBg,
                'Banco',
                Builder(
                  builder: (context) {
                    // Evitar duplicados por id y valor solo si existe en items (evita assert del Dropdown)
                    final seenIds = <int>{};
                    final bankItems = _banks.where((b) {
                      final id = b['id'] is int ? b['id'] as int : (b['id'] is num ? (b['id'] as num).toInt() : null);
                      if (id == null) return false;
                      if (seenIds.contains(id)) return false;
                      seenIds.add(id);
                      return true;
                    }).toList();
                    final validBankIds = bankItems.map((b) => b['id'] is int ? b['id'] as int : (b['id'] as num).toInt()).toSet();
                    final effectiveBankValue = _selectedBankId != null && validBankIds.contains(_selectedBankId)
                        ? _selectedBankId
                        : null;
                    return DropdownButtonFormField<int?>(
                      value: effectiveBankValue,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Seleccionar banco')),
                        ...bankItems.map((b) {
                          final id = b['id'] is int ? b['id'] as int : (b['id'] as num).toInt();
                          final name = (b['name'] ?? '') as String;
                          return DropdownMenuItem<int?>(
                            value: id,
                            child: Text(name, overflow: TextOverflow.ellipsis, maxLines: 1),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => _selectedBankId = v),
                    );
                  },
                ),
              ),
            ],
            if (_type == 'mobile_payment') ...[
              const SizedBox(height: 12),
              _card(
                context,
                cardBg,
                borderColor,
                primaryText,
                secondaryText,
                inputBg,
                'Teléfono de pago móvil *',
                _loadingPhonesDocs
                    ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                    : _phones.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedPhoneValue == null && _phoneController.text.trim().isNotEmpty
                                    ? '__manual__'
                                    : (_selectedPhoneValue != null && _selectedPhoneValue!.isNotEmpty ? _selectedPhoneValue : null),
                                isExpanded: true,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: inputBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                hint: const Text('Seleccionar teléfono'),
                                items: [
                                  ..._phones.map((p) {
                                    final full = '${p.operatorCodeName.replaceAll(RegExp(r'\D'), '')}${p.number}';
                                    return DropdownMenuItem<String>(
                                      value: full,
                                      child: Text(p.fullNumber, overflow: TextOverflow.ellipsis),
                                    );
                                  }),
                                  const DropdownMenuItem<String>(
                                    value: '__manual__',
                                    child: Text('Ingresar otro número'),
                                  ),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    _selectedPhoneValue = (v == null || v == '__manual__') ? null : v;
                                    if (v != '__manual__' && v != null) _phoneController.text = v;
                                  });
                                },
                              ),
                              if (_selectedPhoneValue == null && _phones.isNotEmpty && _phoneController.text.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: _inputDecoration(inputBg, borderColor, 'Ej: 04121234567'),
                                  ),
                                ),
                            ],
                          )
                        : TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(inputBg, borderColor, 'Ej: 04121234567'),
                            validator: (v) {
                              if (_type != 'mobile_payment') return null;
                              if (v == null || v.trim().isEmpty) return 'Ingresa el teléfono de pago móvil';
                              return null;
                            },
                          ),
              ),
            ],
            if (_type == 'card') ...[
              const SizedBox(height: 12),
              _card(
                context,
                cardBg,
                borderColor,
                primaryText,
                secondaryText,
                inputBg,
                'Marca',
                DropdownButtonFormField<String>(
                  initialValue: _cardBrands.contains(_brandController.text.trim())
                      ? _brandController.text.trim()
                      : _cardBrands.first,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: _cardBrands
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      _brandController.text = v;
                      setState(() {});
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              _card(
                context,
                cardBg,
                borderColor,
                primaryText,
                secondaryText,
                inputBg,
                'Últimos 4 dígitos *',
                TextFormField(
                  controller: _last4Controller,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: _inputDecoration(inputBg, borderColor, '4242'),
                  validator: (v) {
                    if (_type != 'card') return null;
                    if (v == null || v.trim().length != 4) return 'Ingresa exactamente 4 dígitos';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _card(
                      context,
                      cardBg,
                      borderColor,
                      primaryText,
                      secondaryText,
                      inputBg,
                      'Mes (1-12) *',
                      TextFormField(
                        controller: _expMonthController,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        decoration: _inputDecoration(inputBg, borderColor, '12'),
                        validator: (v) {
                          if (_type != 'card') return null;
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1 || n > 12) return 'Mes inválido';
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _card(
                      context,
                      cardBg,
                      borderColor,
                      primaryText,
                      secondaryText,
                      inputBg,
                      'Año *',
                      TextFormField(
                        controller: _expYearController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: _inputDecoration(inputBg, borderColor, '${DateTime.now().year + 2}'),
                        validator: (v) {
                          if (_type != 'card') return null;
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < DateTime.now().year) return 'Año inválido';
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _card(
                context,
                cardBg,
                borderColor,
                primaryText,
                secondaryText,
                inputBg,
                'Nombre en la tarjeta *',
                TextFormField(
                  controller: _cardholderController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration(inputBg, borderColor, 'JUAN PÉREZ'),
                  validator: (v) {
                    if (_type != 'card') return null;
                    if (v == null || v.trim().isEmpty) return 'Ingresa el nombre del titular';
                    return null;
                  },
                ),
              ),
            ],
            if (_type == 'bank_transfer') ...[
              const SizedBox(height: 12),
              _card(
                context,
                cardBg,
                borderColor,
                primaryText,
                secondaryText,
                inputBg,
                'Número de cuenta *',
                TextFormField(
                  controller: _accountController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(inputBg, borderColor, 'Ej: 01050000000000001234'),
                  validator: (v) {
                    if (_type != 'bank_transfer') return null;
                    if (v == null || v.trim().isEmpty) return 'Ingresa el número de cuenta';
                    return null;
                  },
                ),
              ),
            ],
            if (_type == 'digital_wallet') ...[
              const SizedBox(height: 12),
              _card(
                context,
                cardBg,
                borderColor,
                primaryText,
                secondaryText,
                inputBg,
                'Plataforma',
                DropdownButtonFormField<String>(
                  initialValue: () {
                    final t = _platformController.text.trim();
                    return _walletPlatforms.contains(t) ? t : _walletPlatforms.first;
                  }(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: _walletPlatforms
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      _platformController.text = v;
                      setState(() {});
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              _card(
                context,
                cardBg,
                borderColor,
                primaryText,
                secondaryText,
                inputBg,
                'Correo electrónico asociado',
                TextFormField(
                  controller: _emailWalletController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(inputBg, borderColor, 'usuario@ejemplo.com'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _card(
              context,
              cardBg,
              borderColor,
              primaryText,
              secondaryText,
              inputBg,
              'Moneda principal (Bs / ref. USD)',
              _type == 'mobile_payment'
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text('Bs (VES)', style: TextStyle(fontSize: 16, color: primaryText)),
                    )
                  : TextFormField(
                      controller: _currencyController,
                      decoration: _inputDecoration(inputBg, borderColor, 'VES'),
                    ),
            ),
            const SizedBox(height: 12),
            _card(
              context,
              cardBg,
              borderColor,
              primaryText,
              secondaryText,
              inputBg,
              'Notas / instrucciones para el cliente',
              TextFormField(
                controller: _notesController,
                decoration: _inputDecoration(inputBg, borderColor, 'Instrucciones opcionales...'),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Método activo', style: TextStyle(fontWeight: FontWeight.w600, color: primaryText)),
                    subtitle: Text('Permitir pagos con este método', style: TextStyle(fontSize: 12, color: secondaryText)),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeThumbColor: AppColors.blue,
                  ),
                  Divider(height: 1, color: borderColor),
                  SwitchListTile(
                    title: Text('Predeterminado', style: TextStyle(fontWeight: FontWeight.w600, color: primaryText)),
                    subtitle: Text('Usar para todos mis pedidos automáticamente', style: TextStyle(fontSize: 12, color: secondaryText)),
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v),
                    activeThumbColor: AppColors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blueDark),
                      )
                    : const Icon(Icons.save, size: 22),
                label: Text(_saving ? 'Guardando...' : 'Guardar método'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.blueDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(Color fillColor, Color borderColor, String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.blue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _card(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    Color primaryText,
    Color secondaryText,
    Color inputBg,
    String label,
    Widget child,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
