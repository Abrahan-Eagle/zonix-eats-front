import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix_glasses/features/DomainProfiles/Addresses/screens/adresse_list_screen.dart';
import 'package:zonix_glasses/features/DomainProfiles/Documents/screens/document_list_screen.dart';
import 'package:zonix_glasses/features/DomainProfiles/Phones/screens/phone_list_screen.dart';
import 'package:zonix_glasses/features/DomainProfiles/Profiles/screens/data_export_page.dart';
import 'package:zonix_glasses/features/DomainProfiles/Profiles/screens/profile_page.dart';
import 'package:zonix_glasses/features/screens/account_deletion_page.dart';
import 'package:zonix_glasses/features/screens/auth/sign_in_screen.dart';
import 'package:zonix_glasses/features/screens/help/help_and_faq_page.dart';
import 'package:zonix_glasses/features/screens/notifications/notifications_page.dart';
import 'package:zonix_glasses/features/screens/settings/legal_info_page.dart';
import 'package:zonix_glasses/features/utils/user_provider.dart';

/// Pantalla de ajustes genérica de Zonix Glasses (sin módulos de dominio).
class SettingsPage2 extends StatelessWidget {
  const SettingsPage2({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final userId = userProvider.userId;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _sectionHeader(context, 'Cuenta'),
        _tile(
          context,
          icon: Icons.person_outline,
          title: 'Mi perfil',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfilePagex(userId: userId)),
          ),
        ),
        _tile(
          context,
          icon: Icons.location_on_outlined,
          title: 'Direcciones',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddressPage(userId: userId)),
          ),
        ),
        _tile(
          context,
          icon: Icons.phone_outlined,
          title: 'Teléfonos',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PhoneScreen(userId: userId)),
          ),
        ),
        _tile(
          context,
          icon: Icons.badge_outlined,
          title: 'Documentos',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DocumentListScreen(userId: userId)),
          ),
        ),
        _tile(
          context,
          icon: Icons.notifications_outlined,
          title: 'Notificaciones',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          ),
        ),
        const Divider(height: 24),
        _sectionHeader(context, 'Privacidad y datos'),
        _tile(
          context,
          icon: Icons.download_outlined,
          title: 'Exportar mis datos',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DataExportPage()),
          ),
        ),
        _tile(
          context,
          icon: Icons.delete_outline,
          title: 'Eliminar cuenta',
          iconColor: Theme.of(context).colorScheme.error,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccountDeletionPage()),
          ),
        ),
        const Divider(height: 24),
        _sectionHeader(context, 'Ayuda'),
        _tile(
          context,
          icon: Icons.help_outline,
          title: 'Ayuda y preguntas frecuentes',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpAndFAQPage()),
          ),
        ),
        _tile(
          context,
          icon: Icons.gavel_outlined,
          title: 'Información legal',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LegalInfoPage()),
          ),
        ),
        const Divider(height: 24),
        _tile(
          context,
          icon: Icons.logout,
          title: 'Cerrar sesión',
          iconColor: Theme.of(context).colorScheme.error,
          onTap: () => _logout(context),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir de tu cuenta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<UserProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (_) => false,
    );
  }
}
