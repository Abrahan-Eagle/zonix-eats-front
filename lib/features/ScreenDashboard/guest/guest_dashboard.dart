// screens/Guest/Guest_dashboard.dart
import 'package:flutter/material.dart';

class GuestDashboard extends StatelessWidget {
  const GuestDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Guest')),
      body: const Center(child: Text('Bienvenido, Guest')),
    );
  }
}
