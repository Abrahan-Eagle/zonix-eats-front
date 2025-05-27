import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/DomainProfiles/Emails/screens/create_email_screen.dart';
import 'package:zonix/features/DomainProfiles/Phones/screens/create_phone_screen.dart';
import 'package:zonix/features/utils/user_provider.dart';

class OnboardingPage2x extends StatelessWidget {
  const OnboardingPage2x({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        color: const Color(0xff034f84), // Cambiado a un tono más oscuro de azul para mejor contraste
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.08),
          child: FutureBuilder<Map<String, dynamic>>(
            future: userProvider.getUserDetails(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData) {
                return const Center(child: Text('No se encontraron datos.'));
              }

              final userDetails = snapshot.data!;
              final userId = userDetails['userId'];

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/onboarding/undraw_add_information_j2wg.svg',
                    height: screenWidth * 0.4, // Ajustado para responsive
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Completa tu perfil',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Agrega tu email y número de teléfono para completar tu perfil y recibir notificaciones importantes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          // onPressed: userProvider.emailCreated
                          //     ? null
                          //     : () {
                          //         if (userId != null) {
                          //           Navigator.push(
                          //             context,
                          //             MaterialPageRoute(
                          //               builder: (context) => CreateEmailScreen(userId: userId),
                          //             ),
                          //           ).then((_) {
                          //             userProvider.setEmailCreated(true);
                          //           });
                          //         }
                          //       },
                          onPressed: userProvider.emailCreated ? null : () async {
                                    if (userId != null) {
                                      final wasEmailCreated = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CreateEmailScreen(userId: userId),
                                        ),
                                      );

                                      if (wasEmailCreated == true) {
                                        userProvider.setEmailCreated(true); // Actualiza el estado
                                      }
                                    }
                                  },

                          icon: const Icon(Icons.email, color: Colors.white),
                          label: Text(
                            userProvider.emailCreated ? 'Email Agregado' : 'Agregar Email',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: userProvider.emailCreated
                                ? Colors.grey
                                : const Color(0xff04658e),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          // onPressed: userProvider.phoneCreated
                          //     ? null
                          //     : () {
                          //         if (userId != null) {
                          //           Navigator.push(
                          //             context,
                          //             MaterialPageRoute(
                          //               builder: (context) => CreatePhoneScreen(userId: userId),
                          //             ),
                          //           ).then((_) {
                          //             userProvider.setPhoneCreated(true);
                          //           });
                          //         }
                          //       },

                          onPressed: userProvider.phoneCreated ? null : () async {
                            if (userId != null) {
                              final wasPhoneCreated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreatePhoneScreen(userId: userId),
                                ),
                              );

                              if (wasPhoneCreated == true) {
                                userProvider.setPhoneCreated(true); // Actualiza el estado
                              }
                            }
                          },

                          icon: const Icon(Icons.phone, color: Colors.white),
                          label: Text(
                            userProvider.phoneCreated ? 'Teléfono Agregado' : 'Agregar Teléfono',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: userProvider.phoneCreated
                                ? Colors.grey
                                : const Color(0xff04658e),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
