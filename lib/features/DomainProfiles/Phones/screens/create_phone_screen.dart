import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/phone.dart';
import '../api/phone_service.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/services/commerce_list_service.dart';
import 'package:zonix/models/my_commerce.dart';

class CreatePhoneScreen extends StatefulWidget {
  final int userId;

  const CreatePhoneScreen({super.key, required this.userId});

  @override
  CreatePhoneScreenState createState() => CreatePhoneScreenState();
}

class CreatePhoneScreenState extends State<CreatePhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final PhoneService _phoneService = PhoneService();

  List<Map<String, dynamic>> _operatorCodes = [];
  int? _selectedOperatorCodeId;
  bool _isLoading = false;
  bool _isPrimary = true;
  String _context = PhoneContext.personal;
  List<MyCommerce> _commerces = [];
  int? _selectedCommerceId;

  @override
  void initState() {
    super.initState();
    _loadOperatorCodes();
    _loadCommerces();
  }

  Future<void> _loadCommerces() async {
    try {
      final list = await CommerceListService.getMyCommerces();
      if (mounted) setState(() => _commerces = list);
    } catch (_) {}
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

  Future<void> _createPhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await ProfileService().getMyProfile();
      if (profile == null) {
        if (!context.mounted) return;
        _showErrorSnackBar('No se pudo obtener el perfil. Inicia sesión de nuevo.');
        setState(() => _isLoading = false);
        return;
      }

      final phone = Phone(
        id: 0,
        profileId: profile.id,
        context: _context,
        commerceId: _context == PhoneContext.commerce ? _selectedCommerceId : null,
        deliveryCompanyId: _context == PhoneContext.deliveryCompany ? null : null,
        operatorCodeId: _selectedOperatorCodeId!,
        operatorCodeName: _operatorCodes.firstWhere(
            (code) => code['id'] == _selectedOperatorCodeId)['name'],
        number: _numberController.text,
        isPrimary: _isPrimary,
        status: true,
      );

      await _phoneService.createPhone(phone, profile.userId);

      if (!context.mounted) return;
      final c = context;
      c.read<UserProvider>().setPhoneCreated(true);
      _showSuccessSnackBar('Teléfono creado exitosamente');
      Navigator.pop(c, true);
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar('Error al crear teléfono: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBorder = isDark ? AppColors.slateBorder : AppColors.stitchBorder;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Nuevo Teléfono'),
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
                          const SizedBox(height: 20.0),
                          _buildVerificationSection(),
                          const SizedBox(height: 24.0),
                          _buildOptionsSection(),
                          const SizedBox(height: 24.0),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildFloatingActionButton(),
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
                  'Registra un número para recibir actualizaciones de tus pedidos en Zonix Eats.',
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

  Widget _buildContextSection(String role) {
    final allowed = PhoneContext.contextsForRole(role);
    if (allowed.isEmpty || !allowed.contains(_context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && allowed.isNotEmpty) setState(() => _context = allowed.first);
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
          initialValue: allowed.contains(_context) ? _context : (allowed.isNotEmpty ? allowed.first : null),
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
            initialValue: _selectedCommerceId,
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
                initialValue: _selectedOperatorCodeId,
                decoration: inputDecoration.copyWith(
                  labelText: 'Código',
                ),
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
                  setState(() {
                    _selectedOperatorCodeId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecciona código';
                  }
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
                  if (value == null || value.isEmpty) {
                    return 'Ingresa número';
                  } else if (value.length != 7) {
                    return '7 dígitos';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Sección Código de Verificación (opcional).
  /// TODO: Implementar cuando el backend exponga API para:
  /// - Enviar SMS con código de 6 dígitos (ej. POST /api/phones/send-verification-code).
  /// - Validar código antes o al guardar (ej. campo verification_code en create/update).
  /// La UI está lista; el botón "Enviar código" muestra mensaje informativo hasta tener API.
  Widget _buildVerificationSection() {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.slateBorder : AppColors.stitchBorder;
    final cardBg = AppColors.cardBg(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText(context),
              ),
              children: [
                const TextSpan(text: 'Código de Verificación '),
                TextSpan(
                  text: '(opcional)',
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: AppColors.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _verificationCodeController,
                decoration: InputDecoration(
                  hintText: '000000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verificación gratuita. Próximamente en esta versión.'),
                      backgroundColor: AppColors.green,
                      behavior: SnackBarBehavior.fixed,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Enviar código'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Se enviará un SMS con un código de 6 dígitos para validar tu identidad. Verificación gratuita.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.secondaryText(context),
              height: 1.35,
            ),
          ),
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
            onChanged: (value) {
              setState(() {
                _isPrimary = value;
              });
            },
            secondary: Icon(
              Icons.star,
              color: _isPrimary ? AppColors.amber : AppColors.textMutedGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
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
            onPressed: _isLoading ? null : _createPhone,
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
            label: Text(_isLoading ? 'Guardando...' : 'Guardar teléfono'),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }
}
