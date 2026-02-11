import 'client_onboarding_flow.dart';

/// Flujo de onboarding específico para el rol **comercio**.
///
/// Extiende el flujo base reutilizando toda la lógica, pero deja claro a nivel
/// de clase que este widget pertenece al rol commerce.
class CommerceOnboardingFlow extends ClientOnboardingFlow {
  const CommerceOnboardingFlow({super.key}) : super(isCommerce: true);
}


