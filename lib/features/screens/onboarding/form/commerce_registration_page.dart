// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/screens/onboarding/onboarding_service.dart';
import 'package:zonix/features/screens/onboarding/onboarding_provider.dart';
import 'package:zonix/features/services/commerce_data_service.dart';
import 'package:zonix/main.dart';

class CommerceRegistrationPage extends StatefulWidget {
  const CommerceRegistrationPage({super.key});

  @override
  State<CommerceRegistrationPage> createState() =>
      _CommerceRegistrationPageState();
}

class _CommerceRegistrationPageState extends State<CommerceRegistrationPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _nombreLocalController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _pagoMovilBancoController = TextEditingController();
  final _pagoMovilCedulaController = TextEditingController();
  final _pagoMovilTelefonoController = TextEditingController();

  bool _isLoading = false;
  bool _abierto = false;

  // Horario de trabajo
  final Map<String, Map<String, String>> _horario = {
    'lunes': {'inicio': '', 'fin': '', 'cerrado': 'false'},
    'martes': {'inicio': '', 'fin': '', 'cerrado': 'false'},
    'miercoles': {'inicio': '', 'fin': '', 'cerrado': 'false'},
    'jueves': {'inicio': '', 'fin': '', 'cerrado': 'false'},
    'viernes': {'inicio': '', 'fin': '', 'cerrado': 'false'},
    'sabado': {'inicio': '', 'fin': '', 'cerrado': 'false'},
    'domingo': {'inicio': '', 'fin': '', 'cerrado': 'false'},
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    // Prefill de dirección con la misma dirección capturada en el formulario 2
    // del onboarding (street, houseNumber, postalCode).
    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);
    final street = onboarding.street;
    final houseNumber = onboarding.houseNumber;
    final postalCode = onboarding.postalCode;

    final buffer = StringBuffer();
    if (street != null && street.trim().isNotEmpty) {
      buffer.write(street.trim());
    }
    if (houseNumber != null && houseNumber.trim().isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write('#${houseNumber.trim()}');
    }
    if (postalCode != null && postalCode.trim().isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(', ');
      buffer.write('CP ${postalCode.trim()}');
    }

    if (buffer.isNotEmpty) {
      _direccionController.text = buffer.toString();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _nombreLocalController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _pagoMovilBancoController.dispose();
    _pagoMovilCedulaController.dispose();
    _pagoMovilTelefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isSmallPhone = size.width < 360;

    return Scaffold(
      backgroundColor: AppColors.green,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: _buildHeader(isTablet, isSmallPhone),
                    ),

                    // Form Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              isTablet ? 64.0 : (isSmallPhone ? 16.0 : 20.0),
                        ),
                        child: _buildFormContent(isTablet, isSmallPhone),
                      ),
                    ),

                    // Bottom spacing
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _buildSubmitButton(isTablet, isSmallPhone),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(bool isTablet, bool isSmallPhone) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : (isSmallPhone ? 16 : 24)),
      child: Column(
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),

          SizedBox(height: isTablet ? 20 : 12),

          // Icon
          Container(
            width: isTablet ? 80 : (isSmallPhone ? 60 : 70),
            height: isTablet ? 80 : (isSmallPhone ? 60 : 70),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.store,
              size: isTablet ? 40 : (isSmallPhone ? 30 : 35),
              color: AppColors.green,
            ),
          ),

          SizedBox(height: isTablet ? 24 : 16),

          Text(
            'Registra tu Comercio',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 32 : (isSmallPhone ? 24 : 28),
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),

          SizedBox(height: isTablet ? 12 : 8),

          Text(
            'Completa la información de tu negocio para comenzar a vender',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 16 : (isSmallPhone ? 12 : 14),
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(bool isTablet, bool isSmallPhone) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : (isSmallPhone ? 20 : 24)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del local
            _buildSectionTitle('Información del Local', isTablet, isSmallPhone),
            SizedBox(height: isTablet ? 20 : 16),

            _buildTextField(
              controller: _nombreLocalController,
              label: 'Nombre del Local',
              icon: Icons.store_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'Este campo es obligatorio';
                if (value.trim().length < 3) return 'Mínimo 3 caracteres';
                if (value.trim().length > 100) return 'Máximo 100 caracteres';
                if (!RegExp(r'^[a-zA-Z0-9 áéíóúÁÉÍÓÚüÜñÑ.,-]+$')
                    .hasMatch(value)) return 'Solo letras, números y espacios';
                return null;
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Z0-9 áéíóúÁÉÍÓÚüÜñÑ.,-]'))
              ],
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),

            SizedBox(height: isTablet ? 20 : 16),

            _buildTextField(
              controller: _direccionController,
              label: 'Dirección',
              icon: Icons.location_on_outlined,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'Este campo es obligatorio';
                if (value.trim().length < 5) return 'Mínimo 5 caracteres';
                if (value.trim().length > 200) return 'Máximo 200 caracteres';
                return null;
              },
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),

            SizedBox(height: isTablet ? 20 : 16),

            _buildTextField(
              controller: _telefonoController,
              label: 'Teléfono',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'Este campo es obligatorio';
                if (value.trim().length < 10) return 'Mínimo 10 dígitos';
                if (value.trim().length > 15) return 'Máximo 15 dígitos';
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Solo números';
                return null;
              },
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),

            SizedBox(height: isTablet ? 32 : 24),

            // Estado del local
            _buildSectionTitle('Estado del Local', isTablet, isSmallPhone),
            SizedBox(height: isTablet ? 16 : 12),

            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Icon(
                    _abierto ? Icons.check_circle : Icons.cancel,
                    color: _abierto ? AppColors.green : AppColors.red,
                    size: isTablet ? 24 : 20,
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Text(
                      'Local actualmente ${_abierto ? 'abierto' : 'cerrado'}',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: _abierto,
                    onChanged: (value) => setState(() => _abierto = value),
                    activeThumbColor: AppColors.green,
                  ),
                ],
              ),
            ),

            SizedBox(height: isTablet ? 32 : 24),

            // Información de Pago Móvil
            _buildSectionTitle('Pago Móvil', isTablet, isSmallPhone),
            SizedBox(height: isTablet ? 20 : 16),

            _buildTextField(
              controller: _pagoMovilBancoController,
              label: 'Banco',
              icon: Icons.account_balance_outlined,
              validator: (value) =>
                  value?.isEmpty == true ? 'Este campo es obligatorio' : null,
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),

            SizedBox(height: isTablet ? 20 : 16),

            _buildTextField(
              controller: _pagoMovilCedulaController,
              label: 'Cédula de Identidad (CI)',
              icon: Icons.credit_card_outlined,
              keyboardType: TextInputType.text,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^[vVeE0-9]+')),
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'Este campo es obligatorio';
                if (!RegExp(r'^[vVeE][0-9]{7,9}$').hasMatch(value.trim()))
                  return 'Formato válido: V12345678 o E12345678';
                return null;
              },
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),

            SizedBox(height: isTablet ? 20 : 16),

            _buildTextField(
              controller: _pagoMovilTelefonoController,
              label: 'Teléfono de Pago Móvil',
              icon: Icons.smartphone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) =>
                  value?.isEmpty == true ? 'Este campo es obligatorio' : null,
              isTablet: isTablet,
              isSmallPhone: isSmallPhone,
            ),

            SizedBox(height: isTablet ? 32 : 24),

            // Horario de atención
            _buildSectionTitle('Horario de Atención', isTablet, isSmallPhone),
            SizedBox(height: isTablet ? 20 : 16),

            _buildScheduleSection(isTablet, isSmallPhone),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isTablet, bool isSmallPhone) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isTablet ? 20 : (isSmallPhone ? 16 : 18),
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondaryDark,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isTablet,
    required bool isSmallPhone,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: isTablet ? 16 : (isSmallPhone ? 13 : 14),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 2),
        ),
        filled: true,
        fillColor: AppColors.inputBg,
        labelStyle: TextStyle(
          fontSize: isTablet ? 14 : (isSmallPhone ? 12 : 13),
        ),
      ),
    );
  }

  Widget _buildScheduleSection(bool isTablet, bool isSmallPhone) {
    return Column(
      children: _horario.keys.map((dia) {
        return Container(
          margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  dia.toUpperCase(),
                  style: TextStyle(
                    fontSize: isTablet ? 14 : (isSmallPhone ? 11 : 12),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ),
              if (_horario[dia]!['cerrado'] == 'false') ...[
                Expanded(
                  flex: 2,
                  child: _buildTimeField(
                    'Inicio',
                    _horario[dia]!['inicio']!,
                    (value) => setState(() => _horario[dia]!['inicio'] = value),
                    isTablet,
                    isSmallPhone,
                  ),
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Expanded(
                  flex: 2,
                  child: _buildTimeField(
                    'Fin',
                    _horario[dia]!['fin']!,
                    (value) => setState(() => _horario[dia]!['fin'] = value),
                    isTablet,
                    isSmallPhone,
                  ),
                ),
              ] else
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 8),
                    child: Text(
                      'CERRADO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : (isSmallPhone ? 11 : 12),
                        color: AppColors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              SizedBox(width: isTablet ? 12 : 8),
              Switch(
                value: _horario[dia]!['cerrado'] == 'false',
                onChanged: (value) {
                  setState(() {
                    _horario[dia]!['cerrado'] = value ? 'false' : 'true';
                    if (!value) {
                      _horario[dia]!['inicio'] = '';
                      _horario[dia]!['fin'] = '';
                    }
                  });
                },
                activeThumbColor: AppColors.green,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeField(
    String hint,
    String value,
    Function(String) onChanged,
    bool isTablet,
    bool isSmallPhone,
  ) {
    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          onChanged(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 12 : 8,
          horizontal: isTablet ? 12 : 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value.isEmpty ? hint : value,
              style: TextStyle(
                fontSize: isTablet ? 12 : (isSmallPhone ? 10 : 11),
                color: value.isEmpty ? AppColors.gray : AppColors.textSecondaryDark,
              ),
            ),
            Icon(
              Icons.access_time,
              size: isTablet ? 16 : 14,
              color: AppColors.gray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isTablet, bool isSmallPhone) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 64 : 20),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.green,
          padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 8,
        ),
        child: _isLoading
            ? SizedBox(
                height: isTablet ? 24 : 20,
                width: isTablet ? 24 : 20,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
                ),
              )
            : Text(
                'Registrar Comercio',
                style: TextStyle(
                  fontSize: isTablet ? 18 : (isSmallPhone ? 14 : 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userId = userProvider.userId;

        if (userId <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No se pudo identificar tu cuenta. Cierra sesión e inicia de nuevo.'),
              backgroundColor: AppColors.red,
            ),
          );
          return;
        }

        // Enviar datos del comercio al backend usando el servicio dedicado.
        final commerceResult = await CommerceDataService.createCommerce({
          'user_id': userId,
          'business_name': _nombreLocalController.text.trim(),
          'business_type': 'Restaurante',
          'tax_id': _pagoMovilCedulaController.text.trim(),
          'address': _direccionController.text.trim(),
          'phone': _telefonoController.text.trim(),
          'open': _abierto,
          'schedule': _horario,
          'mobile_payment_bank': _pagoMovilBancoController.text.trim(),
          'mobile_payment_id': _pagoMovilCedulaController.text.trim(),
          'mobile_payment_phone': _pagoMovilTelefonoController.text.trim(),
        });

        if (commerceResult['success'] != true) {
          throw Exception(
              commerceResult['message'] ?? 'No se pudo registrar el comercio');
        }

        final onboardingService = OnboardingService();
        await onboardingService.completeOnboarding(userId, role: 'commerce');
        if (!mounted) return;

        // Actualizar estado global de onboarding y rol
        if (!context.mounted) return;
        final onboardingProvider =
            Provider.of<OnboardingProvider>(context, listen: false);
        onboardingProvider.setRole('commerce');

        // Marcar onboarding completado localmente para que no se vuelva a mostrar
        userProvider.setCompletedOnboarding(true);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comercio registrado y onboarding completado'),
            backgroundColor: AppColors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainRouter()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}
