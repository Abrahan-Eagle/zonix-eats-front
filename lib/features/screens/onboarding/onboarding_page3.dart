import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './form/commerce_registration_page.dart';
import 'onboarding_provider.dart';
import 'client_onboarding_flow.dart';
import 'commerce_onboarding_flow.dart';

class OnboardingPage3 extends StatefulWidget {
  const OnboardingPage3({super.key});

  @override
  State<OnboardingPage3> createState() => _OnboardingPage3State();
}

class _OnboardingPage3State extends State<OnboardingPage3> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea), // Azul púrpura
              Color(0xFF764ba2), // Púrpura
              Color(0xFF8E2DE2), // Púrpura vibrante
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenHeight * 0.02,
                ),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.03),
                    
                    Text(
                      '¿Cómo quieres usar FoodZone?',
                      style: TextStyle(
                        fontSize: screenWidth * 0.065,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: screenHeight * 0.01),
                    
                    Text(
                      'Selecciona tu rol para personalizar tu experiencia',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: screenWidth * 0.04,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: screenHeight * 0.04),
                    
                    // Role cards - Solo users (comprador) y commerce (comerciante)
                    Column(
                      children: [
                        _buildRoleCard(
                          role: 'users',
                          title: 'Cliente',
                          subtitle: 'Ordena tu comida favorita',
                          icon: Icons.person,
                          color: const Color(0xFFFF6B6B),
                          description: 'Explora restaurantes y realiza pedidos',
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                        ),
                        
                        SizedBox(height: screenHeight * 0.02),
                        
                        _buildRoleCard(
                          role: 'commerce',
                          title: 'Restaurante',
                          subtitle: 'Vende tus productos',
                          icon: Icons.store,
                          color: const Color(0xFFFFB347),
                          description: 'Registra tu negocio y aumenta ventas',
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                        ),
                      ],
                    ),
                    
                    SizedBox(height: screenHeight * 0.04),
                    
                    if (selectedRole != null)
                      Container(
                        width: double.infinity,
                        height: screenHeight * 0.07,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFFFB347)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedRole == null) return;

                            final onboardingProvider = Provider.of<OnboardingProvider>(
                              context,
                              listen: false,
                            );

                            if (selectedRole == 'users') {
                              // Flujo de onboarding para CLIENTE (users)
                              onboardingProvider.setRole('users');
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ClientOnboardingFlow(),
                                ),
                              );
                            } else if (selectedRole == 'commerce') {
                              // Flujo de onboarding para COMERCIO:
                              // primero datos personales/dirección/teléfono,
                              // luego se continúa en CommerceRegistrationPage.
                              onboardingProvider.setRole('commerce');
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CommerceOnboardingFlow(),
                                ),
                              );
                            } else {
                              _navigateToRegistration(selectedRole!);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            selectedRole == 'users' 
                              ? 'Continuar como Cliente' 
                              : 'Continuar como ${_getRoleTitle(selectedRole!)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String description,
    required double screenWidth,
    required double screenHeight,
  }) {
    final isSelected = selectedRole == role;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
        });
        // Guardar el rol seleccionado en el provider global de onboarding
        final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
        onboardingProvider.setRole(role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white.withOpacity(0.25)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Colors.white.withOpacity(0.8)
                : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: color.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: screenWidth * 0.07,
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.048,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.003),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: screenWidth * 0.03,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.check,
                  color: color,
                  size: screenWidth * 0.045,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getRoleTitle(String role) {
    switch (role) {
      case 'users':
        return 'Cliente';
      case 'commerce':
        return 'Restaurante';
      default:
        return '';
    }
  }

  void _navigateToRegistration(String role) {
    // Mostrar mensaje de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando al registro para ${_getRoleTitle(role)}'),
        backgroundColor: const Color(0xFF4ECDC4),
        duration: const Duration(seconds: 1),
      ),
    );

    // Navegar a la página de registro correspondiente
    switch (role) {
      case 'commerce':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CommerceRegistrationPage(),
          ),
        );
        break;
      default:
        // Fallback en caso de error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rol no reconocido'),
            backgroundColor: Color(0xFFE74C3C),
          ),
        );
    }
  }
}