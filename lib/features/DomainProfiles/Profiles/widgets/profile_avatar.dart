import 'package:flutter/material.dart';

/// Avatar de perfil con fallback ante 404 o error de red.
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;

  const ProfileAvatar({super.key, this.photoUrl, this.radius = 50});

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Icon(Icons.person, size: radius),
      );
    }
    final size = radius * 2;
    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/default_avatar.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
