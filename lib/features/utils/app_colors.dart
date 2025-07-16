import 'package:flutter/material.dart';

class AppColors {
  // Colores base
  static const Color blueDark = Color(0xFF0A2239);
  static const Color blue = Color(0xFF1CA9E5);
  static const Color yellow = Color(0xFFFFC72C);
  static const Color orange = Color(0xFFFF9800);
  static const Color orangeCoral = Color(0xFFFF5722);
  static const Color red = Color(0xFFFF4B3E);
  static const Color green = Color(0xFF43D675);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grayLight = Color(0xFFF5F5F5);
  static const Color gray = Color(0xFF4A4A4A);
  static const Color grayDark = Color(0xFF23262B);
  static const Color backgroundDark = Color(0xFF181A20);
  static const Color purple = Color(0xFF8A56AC); // Agregado para acentos púrpura
  static const Color teal = Color(0xFF009688);
  static const Color brown = Color(0xFF795548);
  static const Color amber = Color(0xFFFFC107);

  // Helpers para modo claro/oscuro
  static Color scaffoldBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? backgroundDark : white;

  static Color cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? grayDark : white;

  static Color headerGradientStart(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? grayDark : Color(0xff0043ba);
  static Color headerGradientMid(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? orange : Color(0xff006df1);
  static Color headerGradientEnd(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? orangeCoral : Color(0xff4a90e2);

  static Color primaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? white : blueDark;
  static Color secondaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white70 : gray;

  static Color primaryButton(BuildContext context) => orange;
  static Color accentButton(BuildContext context) => blue;
  static Color error(BuildContext context) => red;
  static Color success(BuildContext context) => green;
} 