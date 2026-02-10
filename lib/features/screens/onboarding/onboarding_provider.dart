import 'package:flutter/foundation.dart';

/// Provider para el estado del onboarding (draft, pasos completados).
/// Usado por main.dart como dependencia; el flujo actual usa onboarding_page1-5 y OnboardingService.
class OnboardingProvider with ChangeNotifier {
  // Estado mínimo para que el provider exista y no rompa referencias
  int _currentStep = 0;
  int get currentStep => _currentStep;
  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }
}
