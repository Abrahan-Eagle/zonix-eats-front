import 'package:flutter/services.dart';

/// Devuelve la CI formateada para mostrar en un campo (ej. al cargar en edición).
String formatCiForDisplay(int? value) {
  if (value == null) return '';
  final digits = value.toString();
  if (digits.isEmpty) return '';
  if (digits.length <= 3) return 'V-$digits';
  final buf = StringBuffer('V-');
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// Formatea la cédula venezolana mientras se escribe: V-12.345.678
/// Solo se permiten dígitos (6 a 9); se añade "V-" y puntos de miles.
class CiVenezuelaInputFormatter extends TextInputFormatter {
  static String _addDots(String digits) {
    if (digits.isEmpty) return '';
    if (digits.length <= 3) return digits;
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 9 ? digits.substring(0, 9) : digits;
    if (limited.isEmpty) {
      return const TextEditingValue(
        text: 'V-',
        selection: TextSelection.collapsed(offset: 2),
      );
    }
    final formatted = 'V-${_addDots(limited)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatea el RIF venezolano mientras se escribe: J-19217553-0, V-19217553-0, etc.
/// Letra (V,E,J,G,P) + guión + 8 dígitos + guión + 1 dígito.
class RifVenezuelaInputFormatter extends TextInputFormatter {
  static const _allowedLetters = ['V', 'E', 'J', 'G', 'P'];

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.toUpperCase().trim();

    if (text.isEmpty) {
      return newValue;
    }

    final isDeleting = newValue.text.length < oldValue.text.length;

    if (isDeleting && text.length <= 2) {
      if (text.length == 1 && _allowedLetters.contains(text)) {
        return TextEditingValue(
          text: '$text-',
          selection: TextSelection.collapsed(offset: 2),
        );
      }
      if (text.isEmpty) {
        return const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
      return newValue;
    }

    String? prefix;
    for (final letter in _allowedLetters) {
      if (text.startsWith('$letter-')) {
        prefix = '$letter-';
        break;
      }
      if (text.length == 1 && text == letter) {
        return TextEditingValue(
          text: '$letter-',
          selection: TextSelection.collapsed(offset: 2),
        );
      }
      if (text.startsWith(letter) && !text.startsWith('$letter-')) {
        return TextEditingValue(
          text: '$letter-',
          selection: TextSelection.collapsed(offset: 2),
        );
      }
    }

    if (prefix == null) {
      return oldValue;
    }

    final numbers = text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = numbers.length > 9 ? numbers.substring(0, 9) : numbers;

    if (limited.isEmpty) {
      return TextEditingValue(
        text: prefix,
        selection: TextSelection.collapsed(offset: prefix.length),
      );
    }

    final String formattedText;
    if (limited.length <= 8) {
      formattedText = '$prefix$limited';
    } else {
      formattedText = '$prefix${limited.substring(0, 8)}-${limited.substring(8)}';
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
