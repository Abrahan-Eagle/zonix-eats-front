import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colores del template Stitch (Onboarding beneficios)
const Color _kBackgroundDark = Color(0xFF0F1923);
const Color _kCardDark = Color(0xFF1A2633);
const Color _kPrimary = Color(0xFF3399FF);

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 360;
    final isTablet = w > 600;
    final padH = isSmall ? 20.0 : (isTablet ? 32.0 : 24.0);
    return Stack(
      children: [
        _buildBackground(context),
        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildBenefitCards(context),
                // Espacio para la barra de navegación inferior del padre
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackground(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.2,
          colors: [
            const Color(0xFF1E3A5F).withValues(alpha: 0.6),
            _kBackgroundDark,
          ],
          stops: const [0.0, 0.6],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: size.height * 0.1, left: size.width * 0.2, child: _starDot(0.4, 2)),
          Positioned(top: size.height * 0.3, right: size.width * 0.15, child: _starDot(0.6, 3)),
          Positioned(bottom: size.height * 0.2, left: size.width * 0.1, child: _starDot(0.8, 1)),
          Positioned(top: size.height * 0.15, right: size.width * 0.35, child: _starDot(0.5, 2)),
          Positioned(bottom: size.height * 0.4, right: size.width * 0.05, child: _starDot(0.7, 1)),
        ],
      ),
    );
  }

  Widget _starDot(double opacity, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
        boxShadow: size >= 2 ? [BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 4)] : null,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 360;
    final iconSize = isSmall ? 56.0 : 64.0;
    final titleSize = isSmall ? 24.0 : (w < 400 ? 26.0 : 28.0);
    final bodySize = isSmall ? 13.0 : 14.0;
    return Column(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
          ),
          child: Icon(Icons.rocket_launch, size: iconSize * 0.56, color: _kPrimary),
        ),
        const SizedBox(height: 16),
        Text(
          '¿Por qué elegir Zonix?',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Descubre un universo de sabor entregado directamente en tu puerta espacial.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: bodySize,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitCards(BuildContext context) {
    return Column(
      children: [
        _buildBenefitCard(context, icon: Icons.bolt, title: 'Velocidad Luz', description: 'Entregas más rápidas que un cometa cruzando la galaxia.'),
        const SizedBox(height: 16),
        _buildBenefitCard(context, icon: Icons.restaurant, title: 'Sabor Estelar', description: 'Los mejores restaurantes seleccionados de todo el sistema solar.'),
        const SizedBox(height: 16),
        _buildBenefitCard(context, icon: Icons.savings_outlined, title: 'Ahorro Galáctico', description: 'Ofertas y promociones que literalmente no son de este mundo.'),
      ],
    );
  }

  Widget _buildBenefitCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 360;
    final pad = isSmall ? 16.0 : 20.0;
    final titleSize = isSmall ? 16.0 : 18.0;
    final bodySize = isSmall ? 13.0 : 14.0;
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: _kCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _kPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: bodySize,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
