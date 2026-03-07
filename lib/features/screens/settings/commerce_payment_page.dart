import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zonix/features/services/commerce_data_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommercePaymentPage extends StatefulWidget {
  const CommercePaymentPage({super.key});

  @override
  State<CommercePaymentPage> createState() => _CommercePaymentPageState();
}

class _CommercePaymentPageState extends State<CommercePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _paymentIdController = TextEditingController();
  final _paymentPhoneController = TextEditingController();

  String? _bank;
  bool _loading = false;
  bool _initialLoading = true;
  String? _error;
  String? _success;

  final List<String> _banks = [
    'Banco de Venezuela',
    'Banesco',
    'Mercantil',
    'BOD',
    'BNC',
    'Bancaribe',
    'Banco del Tesoro',
    'Banco Plaza',
    'BBVA Provincial',
    'Banco Exterior',
    'Banco Caroní',
    'Banco Sofitasa',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  @override
  void dispose() {
    _paymentIdController.dispose();
    _paymentPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentData() async {
    try {
      setState(() {
        _initialLoading = true;
        _error = null;
      });

      final data = await CommerceDataService.getCommerceData();

      setState(() {
        _bank = data['mobile_payment_bank'];
        _paymentIdController.text = data['mobile_payment_id'] ?? '';
        _paymentPhoneController.text = data['mobile_payment_phone'] ?? '';
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
        'bank': _bank,
        'payment_id': _paymentIdController.text,
        'payment_phone': _paymentPhoneController.text,
      };

      await CommerceDataService.updatePaymentData(data);

      setState(() {
        _loading = false;
        _success = 'Datos de pago móvil actualizados correctamente.';
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _success = null);
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error al actualizar datos: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.scaffoldBgLight;
    final primaryText = AppColors.primaryText(context);
    final cardBg = AppColors.cardBg(context);
    final secondaryText = AppColors.secondaryText(context);
    final borderColor = isDark ? AppColors.stitchSurfaceLighter : AppColors.stitchBorder;
    final inputBg = isDark ? AppColors.grayDark : AppColors.stitchBgCard;

    if (_initialLoading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: const Text('Datos de pago móvil'),
          backgroundColor: AppColors.stitchNavBg,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Datos de pago móvil'),
        backgroundColor: AppColors.stitchNavBg,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_success != null) _banner(true, _success!, primaryText),
              if (_error != null) _banner(false, _error!, primaryText),
              if (_success != null || _error != null) const SizedBox(height: 16),
              _card(
                context,
                cardBg,
                borderColor,
                primaryText,
                secondaryText,
                'Información del Banco',
                Icons.account_balance,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Banco', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: secondaryText)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _bank,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        constraints: const BoxConstraints(minHeight: 48),
                      ),
                      hint: Text('Seleccionar banco', style: TextStyle(color: secondaryText)),
                      items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (v) => setState(() => _bank = v),
                      validator: (v) => v == null || v.isEmpty ? 'Seleccione un banco' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                context,
                cardBg,
                borderColor,
                primaryText,
                secondaryText,
                'Datos de Pago Móvil',
                Icons.contactless,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID de pago móvil *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: secondaryText)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _paymentIdController,
                      decoration: _inputDecorationWithIcon(inputBg, borderColor, secondaryText, 'Ej: 12345678', Icons.badge),
                      validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 16),
                    Text('Teléfono de pago móvil *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: secondaryText)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _paymentPhoneController,
                      decoration: _inputDecorationWithIcon(inputBg, borderColor, secondaryText, 'Ej: 04121234567', Icons.phone_android),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Campo requerido';
                        final digits = v.replaceAll(RegExp(r'\D'), '');
                        if (digits.length != 11) return 'Debe tener 11 dígitos';
                        return null;
                      },
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _infoCard(cardBg, borderColor, primaryText, secondaryText),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    shadowColor: AppColors.purple.withValues(alpha: 0.3),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : const Text('Guardar cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _banner(bool isSuccess, String message, Color primaryText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? AppColors.green.withValues(alpha: 0.1) : AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuccess ? AppColors.green.withValues(alpha: 0.3) : AppColors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? AppColors.green : AppColors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14, color: primaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    Color primaryText,
    Color secondaryText,
    String title,
    IconData titleIcon,
    Widget child,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(titleIcon, color: AppColors.purple, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoCard(Color cardBg, Color borderColor, Color primaryText, Color secondaryText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.blue, size: 22),
              const SizedBox(width: 8),
              Text(
                'Información Importante',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _bullet(secondaryText, 'Los datos de pago móvil se utilizan para recibir pagos de los clientes.'),
          _bullet(secondaryText, 'Asegúrate de que el número de teléfono esté activo.'),
          _bullet(secondaryText, 'El ID debe ser el mismo registrado en tu banco.'),
          _bullet(secondaryText, 'Estos datos son confidenciales y seguros.'),
        ],
      ),
    );
  }

  Widget _bullet(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: color, height: 1.4))),
        ],
      ),
    );
  }

  InputDecoration _inputDecorationWithIcon(Color fillColor, Color borderColor, Color iconColor, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fillColor,
      prefixIcon: Icon(icon, size: 22, color: iconColor),
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
        borderSide: const BorderSide(color: AppColors.purple, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      constraints: const BoxConstraints(minHeight: 48),
    );
  }
}
