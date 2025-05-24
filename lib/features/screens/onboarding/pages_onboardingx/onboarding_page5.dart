import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix_eats/features/utils/user_provider.dart';
import 'package:zonix_eats/features/DomainProfiles/GasCylinder/screens/create_gas_cylinder_screen.dart';

class OnboardingPage5 extends StatelessWidget {
  const OnboardingPage5({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: Container(
        color: const Color(0xfff44336),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
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
                  Image.asset('assets/onboarding/storefront-illustration-2.png'),
                  const SizedBox(height: 24),
                  Text(
                    'Registra tu bombona de gas',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Agrega detalles sobre tu bombona y programa una cita.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  // ElevatedButton.icon(
                  //   onPressed: userProvider.gasCylindersCreated ? null : () {
                  //     if (userId != null) {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => CreateGasCylinderScreen(userId: userId),
                  //         ),
                  //       ).then((_) {
                  //         userProvider.setGasCylindersCreated(true);
                  //       });
                  //     }
                  //   },
                  //   icon: const Icon(Icons.add_circle, color: Colors.white),
                  //   label: Text(
                  //     userProvider.gasCylindersCreated ? 'Bombona Registrada' : 'Registrar Bombona',
                  //     style: const TextStyle(color: Colors.white),
                  //   ),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: userProvider.gasCylindersCreated
                  //         ? Colors.grey
                  //         : const Color(0xff007d6e),
                  //     padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(8.0),
                  //     ),
                  //   ),
                  // ),


                  ElevatedButton.icon(
                        onPressed: userProvider.gasCylindersCreated ? null : () async {
                          final userId = userProvider.userId;

                          if (userId != null) {
                            final wasGasCylinderCreated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateGasCylinderScreen(userId: userId),
                              ),
                            );

                            if (wasGasCylinderCreated == true) {
                              userProvider.setGasCylindersCreated(true);
                            }
                          }
                        },
                        icon: const Icon(Icons.add_circle, color: Colors.white),
                        label: Text(
                          userProvider.gasCylindersCreated ? 'Bombona Registrada' : 'Registrar Bombona',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: userProvider.gasCylindersCreated
                              ? Colors.grey
                              : const Color(0xff007d6e),
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      )

                ],
              );
            },
          ),
        ),
      ),
    );
  }
}