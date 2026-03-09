import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/features/utils/app_colors.dart';

/// Pantalla con enlaces legales: Términos, Privacidad, Cookies, Seguridad.
/// Se accede desde Ajustes → Más → Información legal.
class LegalInfoPage extends StatelessWidget {
  const LegalInfoPage({super.key});

  String _legalBaseUrl() {
    final appDomain = dotenv.env['APP_DOMAIN']?.trim();
    if (appDomain != null && appDomain.isNotEmpty) {
      final hasScheme = appDomain.startsWith('http://') || appDomain.startsWith('https://');
      return hasScheme ? appDomain : 'https://$appDomain';
    }
    return AppConfig.apiUrl;
  }

  Future<void> _openUrl(BuildContext context, String path, String label) async {
    final uri = Uri.parse('${_legalBaseUrl()}$path');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Información legal',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _LegalTile(
            icon: Icons.description_outlined,
            title: 'Términos de servicio',
            onTap: () => _openUrl(context, '/terminos-condiciones', 'Términos'),
          ),
          const Divider(height: 1),
          _LegalTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Política de privacidad',
            onTap: () => _openUrl(context, '/politica-privacidad', 'Privacidad'),
          ),
          const Divider(height: 1),
          _LegalTile(
            icon: Icons.cookie_outlined,
            title: 'Política de cookies',
            onTap: () => _openUrl(context, '/politica-cookies', 'Cookies'),
          ),
          const Divider(height: 1),
          _LegalTile(
            icon: Icons.security_outlined,
            title: 'Seguridad',
            onTap: () => _openUrl(context, '/seguridad', 'Seguridad'),
          ),
        ],
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _LegalTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.blue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.blue, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Icon(Icons.open_in_new, size: 20, color: theme.colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
