import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/DomainProfiles/Addresses/screens/adresse_create_screen.dart';

class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final logger = Logger();

    return Scaffold(
      body: Container(
        color: const Color(0xfffeae4f),
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
                  Image.asset('assets/onboarding/building.png'),
                  const SizedBox(height: 24),
                  Text(
                    'Agrega tu dirección',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Especifica tu dirección para programar entregas de bombonas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  // ElevatedButton.icon(
                  //   onPressed: userProvider.adresseCreated ? null : () {
                  //     if (userId != null) {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => RegisterAddressScreen(userId: userId),
                  //         ),
                  //       ).then((_) {
                  //         userProvider.setAdresseCreated(true);
                  //       });
                  //     } else {
                  //       logger.e('Error: El userId es null');
                  //     }
                  //   },
                  //   icon: const Icon(Icons.add_location, color: Colors.white),
                  //   label: Text(
                  //     userProvider.adresseCreated ? 'Dirección Agregada' : 'Agregar Dirección',
                  //     style: const TextStyle(color: Colors.white),
                  //   ),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: userProvider.adresseCreated
                  //         ? Colors.grey
                  //         : const Color(0xff007d6e),
                  //     padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(8.0),
                  //     ),
                  //   ),
                  // ),

                  ElevatedButton.icon(
                        onPressed: userProvider.adresseCreated ? null : () async {
                          final userId = userProvider.userId;

                          if (userId != null) {
                            final wasAddressCreated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterAddressScreen(userId: userId),
                              ),
                            );

                            if (wasAddressCreated != null) {
                              userProvider.setAdresseCreated(true); // Actualiza el estado si se crea la dirección
                            }
                          } else {
                            logger.e('Error: El userId es null');
                          }
                        },
                        icon: const Icon(Icons.add_location, color: Colors.white),
                        label: Text(
                          userProvider.adresseCreated ? 'Dirección Agregada' : 'Agregar Dirección',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: userProvider.adresseCreated
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