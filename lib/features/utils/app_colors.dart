import 'package:flutter/material.dart';

class AppColors {
  // Colores base
  static const Color blueDark = Color(0xFF0A2239);
  static const Color blue =
      Color(0xFF3399FF); // Sincronizado con ThemeData._stitchPrimary
  static const Color blueLight = Color(0xFF93C5FD); // Azul claro (auth overlay)
  static const Color yellow = Color(0xFFFFC72C);
  static const Color orange = Color(0xFFFF9800);
  static const Color orangeCoral = Color(0xFFFF5722);
  static const Color red = Color(0xFFFF4B3E);
  static const Color green = Color(0xFF43D675);
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color white60 = Colors.white60;
  static const Color white54 = Colors.white54;
  static const Color white38 = Colors.white38;
  static const Color white24 = Colors.white24;
  static const Color white12 = Colors.white12;
  static const Color black = Colors.black;
  static const Color black87 = Colors.black87;
  static const Color black54 = Colors.black54;
  static const Color black45 = Colors.black45;
  static const Color black38 = Colors.black38;
  static const Color black26 = Colors.black26;
  static const Color black12 = Colors.black12;
  static const Color transparent = Colors.transparent;
  static const Color surfaceDarkLighter = Color(0xFF2D3A48); // Superficie oscura (product detail)
  static const Color scaffoldBgLight = Color(0xFFF5F7F8); // Fondo claro settings
  static const Color textMutedGray = Color(0xFF9CA3AF); // Texto apagado
  static const Color grayLight = Color(0xFFF5F5F5);
  static const Color gray = Color(0xFF4A4A4A);
  static const Color grayDark =
      Color(0xFF1A2733); // Sincronizado con ThemeData._stitchSurfaceDark
  static const Color backgroundDark =
      Color(0xFF0F1923); // Sincronizado con ThemeData._stitchBgDark
  static const Color purple =
      Color(0xFF8A56AC); // Agregado para acentos púrpura
  static const Color teal = Color(0xFF009688);
  static const Color brown = Color(0xFF795548);
  static const Color amber = Color(0xFFFFC107);

  // Tokens Stitch y Genéricos Adicionales
  static const Color stitchTextDark = Color(0xFF0F172A);
  static const Color stitchSlate = Color(0xFF64748B);
  static const Color stitchSlate400 = Color(0xFF94A3B8);
  static const Color stitchBorder = Color(0xFFE2E8F0);
  static const Color stitchBgCard = Color(0xFFF1F5F9);
  static const Color stitchAmber = Color(0xFFF59E0B);
  static const Color stitchCardCream = Color(0xFFF9F0E0);
  static const Color stitchNavBg = Color(0xFF1A2E46);
  static const Color stitchSurfaceLighter = Color(0xFF21303E);
  static const Color stitchPink400 = Color(0xFFF472B6);
  static const Color whatsappGreen = Color(0xFF25D366);

  // ── Paleta logo (splash) + psicología comida rápida / marketplace ──
  // Azul oscuro: confianza, estabilidad (fondos, navegación)
  // Azul vibrante: velocidad, frescura (CTAs, enlaces)
  // Crema: limpieza, claridad (fondos de tarjetas, texto sobre oscuro)
  // Dorado/Naranja: energía, hambre, CTA (botones primarios, ofertas)
  // Rojo: urgencia, ofertas (badges, alertas)
  static const Color cream = Color(0xFFF5F0E6); // Off-white / “bun” logo
  static const Color inputBg = Color(0xFFF8F9FA); // Fondos inputs/forms
  static const Color borderLight = Color(0xFFE8E8E8); // Bordes inputs
  static const Color textSecondaryDark = Color(0xFF2C3E50); // Texto secundario forms
  static const Color onboardingCompanyBlue = Color(0xFF2E86C1); // Rol commerce/company
  static const Color onboardingDeliveryPurple = Color(0xFF8E44AD); // Rol delivery agent
  static const Color surfaceHighlight = Color(0xFF233040); // Superficie destacada (onboarding)
  static const Color onboardingPurpleAccent = Color(0xFFA78BFA); // Acento púrpura onboarding
  static const Color backgroundDarker = Color(0xFF0D1218); // Gradiente fondo oscuro
  static const Color cardDarkSlate = Color(0xFF1E293B); // Card oscuro (detalle restaurante)
  static const Color ratingAmberLight = Color(0xFFFBBF24);
  static const Color ratingAmberDark = Color(0xFFD97706);

  // Onboarding (flujo usuario) — sin hardcode en pantallas
  static const Color addressPrimary = Color(0xFFFFC105); // Dirección en client onboarding
  static const Color onboardingBlueDark = Color(0xFF1E3A5F); // Gradiente/page1/page2
  static const Color slateBorder = Color(0xFF334155); // Borde slate
  static const Color onboardingGradientStart = Color(0xFF1B365D);
  static const Color onboardingBlueLight = Color(0xFF5DADE2);
  static const Color blueDeep = Color(0xFF1E3A8A);
  static const Color blueMedium = Color(0xFF3B82F6);

  // Helpers para modo claro/oscuro
  static Color scaffoldBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? backgroundDark : white;

  static Color cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? grayDark : white;

  static Color headerGradientStart(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? grayDark : blueDark;
  static Color headerGradientMid(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? orange : blue;
  static Color headerGradientEnd(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? orangeCoral : blue;

  static Color primaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? white : blueDark;
  static Color secondaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? white70 : gray;

  static Color primaryButton(BuildContext context) => yellow;
  static Color accentButton(BuildContext context) => blue;
  static Color error(BuildContext context) => red;
  static Color success(BuildContext context) => green;
}
