import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import './form/commerce_registration_page.dart';
import 'onboarding_provider.dart';
import 'client_onboarding_flow.dart';
import 'commerce_onboarding_flow.dart';

// Colores del template Stitch (Onboarding - Selección de rol)
const Color _kBackgroundDark = Color(0xFF101922);
const Color _kPrimary = Color(0xFF3399FF);
const Color _kSurfaceDark = Color(0xFF1A2633);
const Color _kSurfaceHighlight = Color(0xFF233040);
const Color _kPurple = Color(0xFFA78BFA);

class OnboardingPage3 extends StatefulWidget {
  const OnboardingPage3({super.key});

  @override
  State<OnboardingPage3> createState() => _OnboardingPage3State();
}

class _OnboardingPage3State extends State<OnboardingPage3> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isSmall = w < 360;
    final isTablet = w > 600;

    return Stack(
      children: [
        _buildBackground(),
        SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 20 : (isTablet ? 32 : 24),
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Título con icono cohete
                    _buildHeader(context, isSmall),
                    const SizedBox(height: 32),
                    // Cards de rol
                    _buildRoleCard(
                      role: 'users',
                      title: 'Soy Cliente',
                      subtitle: 'Quiero pedir comida deliciosa',
                      icon: Icons.shopping_bag_outlined,
                      iconColor: _kPrimary,
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      role: 'commerce',
                      title: 'Tengo un Comercio',
                      subtitle: 'Quiero vender mis productos',
                      icon: Icons.storefront_outlined,
                      iconColor: _kPurple,
                    ),
                    const SizedBox(height: 24),
                    // ZONIX EATS UNIVERSE
                    Center(
                      child: Text(
                        'ZONIX EATS UNIVERSE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.4),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Botón Continuar
                    _buildContinueButton(context, w),
                    const SizedBox(height: 16),
                    // ¿Necesitas ayuda?
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        '¿Necesitas ayuda para decidir?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kBackgroundDark, Color(0xFF0D1218)],
        ),
      ),
      child: Stack(
        children: [
          // Estrellas sutiles
          ..._buildStars(),
          // Glow top right
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kPrimary.withOpacity(0.2), Colors.transparent],
                ),
              ),
            ),
          ),
          // Glow bottom left
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kPurple.withOpacity(0.1), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStars() {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final positions = [
      Offset(0.1 * w, 0.15 * h),
      Offset(0.2 * w, 0.35 * h),
      Offset(0.25 * w, 0.8 * h),
      Offset(0.45 * w, 0.2 * h),
      Offset(0.65 * w, 0.4 * h),
    ];
    return positions.map((p) {
      return Positioned(
        left: p.dx,
        top: p.dy,
        child: Container(
          width: 2,
          height: 2,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildHeader(BuildContext context, bool isSmall) {
    final titleSize = isSmall ? 24.0 : 28.0;
    return Column(
      children: [
        // Icono cohete
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kSurfaceDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Icon(Icons.rocket_launch, color: _kPrimary, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          '¿Cómo quieres\nexplorar hoy?',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Elige tu misión.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isSmall ? 14 : 16,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() => selectedRole = role);
        Provider.of<OnboardingProvider>(context, listen: false).setRole(role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? _kSurfaceHighlight : _kSurfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _kPrimary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: _kPrimary.withOpacity(0.15), blurRadius: 30, spreadRadius: 0)]
              : null,
        ),
        child: Row(
          children: [
            // Icono
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    iconColor.withOpacity(0.2),
                    iconColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withOpacity(0.2)),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            // Radio/Check
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _kPrimary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _kPrimary : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context, double w) {
    final enabled = selectedRole != null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled
            ? () async {
                if (selectedRole == null) return;
                final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);

                if (selectedRole == 'users') {
                  onboardingProvider.setRole('users');
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ClientOnboardingFlow()),
                  );
                } else if (selectedRole == 'commerce') {
                  onboardingProvider.setRole('commerce');
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CommerceOnboardingFlow()),
                  );
                } else {
                  _navigateToRegistration(selectedRole!);
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? _kPrimary : _kPrimary.withOpacity(0.4),
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kPrimary.withOpacity(0.3),
          disabledForegroundColor: Colors.white70,
          elevation: enabled ? 4 : 0,
          shadowColor: _kPrimary.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continuar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToRegistration(String role) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando al registro para ${_getRoleTitle(role)}'),
        backgroundColor: _kPrimary,
        duration: const Duration(seconds: 1),
      ),
    );
    if (role == 'commerce') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CommerceRegistrationPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rol no reconocido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getRoleTitle(String role) {
    switch (role) {
      case 'users':
        return 'Cliente';
      case 'commerce':
        return 'Comercio';
      default:
        return '';
    }
  }
}
