import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/phone.dart';
import '../api/phone_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/services/commerce_list_service.dart';
import 'package:zonix/models/my_commerce.dart';
import 'package:provider/provider.dart';

class EditPhoneScreen extends StatefulWidget {
  final Phone phone;
  final int userId;

  const EditPhoneScreen({
    super.key,
    required this.phone,
    required this.userId,
  });

  @override
  EditPhoneScreenState createState() => EditPhoneScreenState();
}

class EditPhoneScreenState extends State<EditPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final PhoneService _phoneService = PhoneService();

  List<Map<String, dynamic>> _operatorCodes = [];
  int? _selectedOperatorCodeId;
  bool _isPrimary = false;
  bool _isActive = true;
  bool _isLoading = false;
  String _context = PhoneContext.personal;
  List<MyCommerce> _commerces = [];
  int? _selectedCommerceId;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadOperatorCodes();
    _loadCommerces();
  }

  Future<void> _loadCommerces() async {
    try {
      final list = await CommerceListService.getMyCommerces();
      if (mounted) setState(() => _commerces = list);
    } catch (_) {}
  }

  void _initializeData() {
    _numberController.text = widget.phone.number;
    _selectedOperatorCodeId = widget.phone.operatorCodeId;
    _isPrimary = widget.phone.isPrimary;
    _isActive = widget.phone.status;
    _context = widget.phone.context;
    _selectedCommerceId = widget.phone.commerceId;

    debugPrint('DEBUG: Initializing data for phone: ${widget.phone.id}');
    debugPrint('DEBUG: Original number: ${widget.phone.number}');
    debugPrint(
        'DEBUG: Original operator code ID: ${widget.phone.operatorCodeId}');
    debugPrint('DEBUG: Original is primary: ${widget.phone.isPrimary}');
    debugPrint('DEBUG: Original status: ${widget.phone.status}');
    debugPrint('DEBUG: Controller text: ${_numberController.text}');
    debugPrint('DEBUG: Selected operator code: $_selectedOperatorCodeId');
    debugPrint('DEBUG: Is primary: $_isPrimary');
    debugPrint('DEBUG: Is active: $_isActive');
  }

  Future<void> _loadOperatorCodes() async {
    try {
      final codes = await _phoneService.fetchOperatorCodes();
      setState(() {
        _operatorCodes = codes;
      });
    } catch (e) {
      _showErrorSnackBar('Error al cargar códigos de operador: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _updatePhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updates = <String, dynamic>{
        'context': _context,
        'operator_code_id': _selectedOperatorCodeId,
        'number': _numberController.text,
        'is_primary': _isPrimary ? 1 : 0,
        'status': _isActive ? 1 : 0,
      };
      if (_context == PhoneContext.commerce) {
        updates['commerce_id'] = _selectedCommerceId;
      } else {
        updates['commerce_id'] = null;
        updates['delivery_company_id'] = null;
      }
      if (_context == PhoneContext.deliveryCompany) {
        updates['delivery_company_id'] = widget.phone.deliveryCompanyId;
      }

      debugPrint('DEBUG: Phone ID: ${widget.phone.id}');
      debugPrint('DEBUG: Updates: $updates');
      debugPrint('DEBUG: Selected operator code: $_selectedOperatorCodeId');
      debugPrint('DEBUG: Number: ${_numberController.text}');
      debugPrint('DEBUG: Is primary: $_isPrimary');
      debugPrint('DEBUG: Is active: $_isActive');

      await _phoneService.updatePhone(widget.phone.id, updates);
      if (!context.mounted) return;
      final c = context;
      _showSuccessSnackBar('Teléfono actualizado exitosamente');
      Navigator.pop(c, true);
    } catch (e) {
      if (!context.mounted) return;
      debugPrint('DEBUG: Error updating phone: $e');
      _showErrorSnackBar('Error al actualizar teléfono: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildContextSection(String role) {
    final allowed = PhoneContext.contextsForRole(role);
    if (allowed.isNotEmpty && !allowed.contains(_context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _context = allowed.first);
      });
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.stitchBorder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Etiqueta',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText(context),
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          value: allowed.contains(_context) ? _context : (allowed.isNotEmpty ? allowed.first : null),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
          items: allowed
              .map((ctx) => DropdownMenuItem<String>(
                    value: ctx,
                    child: Text(PhoneContext.label(ctx)),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _context = value;
                if (value != PhoneContext.commerce) _selectedCommerceId = null;
              });
            }
          },
        ),
        if (_context == PhoneContext.commerce) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _selectedCommerceId,
            decoration: InputDecoration(
              labelText: 'Comercio',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
            items: _commerces
                .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.businessName)))
                .toList(),
            onChanged: (value) => setState(() => _selectedCommerceId = value),
            validator: _context == PhoneContext.commerce
                ? (v) => v == null ? 'Selecciona un comercio' : null
                : null,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBorder = isDark ? AppColors.slateBorder : AppColors.stitchBorder;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Editar Teléfono'),
        elevation: 0,
        backgroundColor: AppColors.cardBg(context),
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: appBarBorder, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24.0),
                          if (PhoneContext.showContextDropdownForRole(
                              context.read<UserProvider>().userRole)) ...[
                            _buildContextSection(context.read<UserProvider>().userRole),
                            const SizedBox(height: 20.0),
                          ],
                          _buildPhoneForm(),
                          const SizedBox(height: 24.0),
                          _buildOptionsSection(),
                          const SizedBox(height: 24.0),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomButton(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.stitchBorder;
    final cardBg = AppColors.cardBg(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.smartphone, color: primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Información de contacto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Actualiza los datos de tu número de teléfono.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText(context),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.stitchBorder;
    final cardBg = AppColors.cardBg(context);
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Número de Teléfono',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText(context),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 1,
              child: DropdownButtonFormField<int>(
                value: _selectedOperatorCodeId,
                decoration: inputDecoration.copyWith(labelText: 'Código'),
                items: _operatorCodes.map((code) {
                  return DropdownMenuItem<int>(
                    value: code['id'] as int,
                    child: Text(
                      code['name'] as String,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedOperatorCodeId = value);
                },
                validator: (value) {
                  if (value == null) return 'Selecciona código';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 2,
              child: TextFormField(
                controller: _numberController,
                decoration: inputDecoration.copyWith(
                  hintText: '7 dígitos',
                  prefixIcon: Icon(
                    Icons.call,
                    size: 22,
                    color: AppColors.secondaryText(context),
                  ),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa número';
                  if (value.length != 7) return '7 dígitos';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.stitchBorder;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opciones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(
              'Teléfono Principal',
              style: TextStyle(color: AppColors.primaryText(context)),
            ),
            subtitle: Text(
              'Marcar como número principal',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText(context),
              ),
            ),
            value: _isPrimary,
            onChanged: (value) => setState(() => _isPrimary = value),
            secondary: Icon(
              Icons.star,
              color: _isPrimary ? AppColors.amber : AppColors.textMutedGray,
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(
              'Teléfono Activo',
              style: TextStyle(color: AppColors.primaryText(context)),
            ),
            subtitle: Text(
              'Habilitar o deshabilitar',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText(context),
              ),
            ),
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            secondary: Icon(
              Icons.check_circle,
              color: _isActive ? AppColors.green : AppColors.textMutedGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.slateBorder
                : AppColors.stitchBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _updatePhone,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: AppColors.white,
              elevation: 4,
              shadowColor: primary.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : const Icon(Icons.save, size: 22),
            label: Text(_isLoading ? 'Guardando...' : 'Guardar cambios'),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }
}
