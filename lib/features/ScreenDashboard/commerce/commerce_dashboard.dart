// screens/Commerce/Commerce_dashboard.dart
import 'package:flutter/material.dart';

class CommerceDashboard extends StatelessWidget {
  const CommerceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Commerce')),
      body: const Center(child: Text('Bienvenido, Commerce')),
    );
  }
}
