import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix_eats/features/DomainProfiles/Profiles/screens/create_profile_page.dart';
import 'package:zonix_eats/features/utils/user_provider.dart';

class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: Container(
        color: const Color(0xff1eb090),
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
                    'Crea tu perfil',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ingresa tu información personal y crea tu perfil.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  
                  










                  //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                  ElevatedButton.icon(
                      onPressed: userProvider.profileCreated ? null : () async {
                        if (userId != null) {
                          final wasProfileCreated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateProfilePage(userId: userId),
                            ),
                          );

                          if (wasProfileCreated == true) {
                            userProvider.setProfileCreated(true);
                          }
                        }
                      },
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      label: Text(
                        userProvider.profileCreated ? 'Perfil Creado' : 'Crear Perfil',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: userProvider.profileCreated
                            ? Colors.grey
                            : const Color(0xff007d6e),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    )



                  //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
