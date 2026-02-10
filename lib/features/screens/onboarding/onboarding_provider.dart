import 'package:flutter/foundation.dart';

/// Provider para el estado del onboarding (draft, pasos, rol y datos capturados).
/// El objetivo es guardar todo en memoria durante el flujo y al final
/// construir el payload completo para el backend.
class OnboardingProvider with ChangeNotifier {
  // Paso actual (para flujos que lo necesiten)
  int _currentStep = 0;
  int get currentStep => _currentStep;

  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  /// Rol seleccionado en el onboarding: 'users' (comprador) o 'commerce' (comerciante)
  String? _selectedRole;
  String? get selectedRole => _selectedRole;

  void setRole(String role) {
    if (role == _selectedRole) return;
    _selectedRole = role;
    notifyListeners();
  }

  // --- Draft de perfil comprador/comerciante (campos compartidos mínimos) ---

  String? _firstName;
  String? get firstName => _firstName;

  String? _middleName;
  String? get middleName => _middleName;

  String? _lastName;
  String? get lastName => _lastName;

  String? _secondLastName;
  String? get secondLastName => _secondLastName;

  DateTime? _dateOfBirth;
  DateTime? get dateOfBirth => _dateOfBirth;

  /// Sexo: 'F' o 'M'
  String? _sex;
  String? get sex => _sex;

  void setProfileData({
    required String firstName,
    String? middleName,
    required String lastName,
    String? secondLastName,
    required DateTime dateOfBirth,
    required String sex,
  }) {
    _firstName = firstName;
    _middleName = middleName;
    _lastName = lastName;
    _secondLastName = secondLastName;
    _dateOfBirth = dateOfBirth;
    _sex = sex;
    notifyListeners();
  }

  // --- Draft de dirección base (comprador o comercio) ---

  double? _latitude;
  double? get latitude => _latitude;

  double? _longitude;
  double? get longitude => _longitude;

  String? _street;
  String? get street => _street;

  String? _houseNumber;
  String? get houseNumber => _houseNumber;

  String? _postalCode;
  String? get postalCode => _postalCode;

  int? _cityId;
  int? get cityId => _cityId;

  void setLocationCoordinates({
    required double latitude,
    required double longitude,
  }) {
    _latitude = latitude;
    _longitude = longitude;
    notifyListeners();
  }

  void setAddressDetails({
    required String street,
    String? houseNumber,
    String? postalCode,
    required int cityId,
  }) {
    _street = street;
    _houseNumber = houseNumber;
    _postalCode = postalCode;
    _cityId = cityId;
    notifyListeners();
  }

  // --- Draft de teléfono principal (número crudo, se parsea en backend o servicio) ---

  String? _rawPhone;
  String? get rawPhone => _rawPhone;

  void setRawPhone(String phone) {
    _rawPhone = phone;
    notifyListeners();
  }

  /// Limpia todo el draft (si se quiere reiniciar onboarding).
  void reset() {
    _currentStep = 0;
    _selectedRole = null;
    _firstName = null;
    _middleName = null;
    _lastName = null;
    _secondLastName = null;
    _dateOfBirth = null;
    _sex = null;
    _latitude = null;
    _longitude = null;
    _street = null;
    _houseNumber = null;
    _postalCode = null;
    _cityId = null;
    _rawPhone = null;
    notifyListeners();
  }
}

