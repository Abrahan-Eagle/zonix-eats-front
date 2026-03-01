import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/DomainProfiles/Documents/screens/document_list_screen.dart';
import 'package:zonix/features/DomainProfiles/Phones/screens/phone_list_screen.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/profile_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/models/profile_model.dart';
import 'package:zonix/features/screens/auth/sign_in_screen.dart';
import 'package:zonix/features/DomainProfiles/Addresses/screens/adresse_list_screen.dart';
import 'package:zonix/features/screens/about/about_page.dart';
import 'package:zonix/features/screens/help/help_and_faq_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix/features/screens/notifications/notifications_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/activity_history_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/data_export_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/privacy_settings_page.dart';
import 'package:zonix/features/screens/account_deletion_page.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/screens/settings/commerce_data_page.dart';
import 'package:zonix/features/screens/settings/commerce_payment_page.dart';
import 'package:zonix/features/screens/settings/commerce_schedule_page.dart';
import 'package:zonix/features/screens/settings/commerce_open_page.dart';
import 'package:zonix/features/screens/commerce/commerce_promotions_page.dart';
import 'package:zonix/features/screens/commerce/commerce_zones_page.dart';
import 'package:zonix/features/screens/commerce/commerce_notifications_page.dart';
import 'package:zonix/features/screens/commerce/commerce_payment_methods_page.dart';
import 'package:zonix/features/screens/commerce/commerce_list_page.dart';
import 'package:zonix/features/screens/orders/orders_page.dart';
import 'package:zonix/features/screens/commerce/commerce_orders_page.dart';
import 'package:zonix/features/services/commerce_post_service.dart';

final logger = Logger();

class _MasTile {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _MasTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}

// Colores Stitch (template)
const Color _stitchPrimary = Color(0xFF3399FF);
const Color _stitchSurfaceDark = Color(0xFF182430);
const Color _stitchSurfaceLighter = Color(0xFF21303E);

class SettingsPage2 extends StatefulWidget {
  const SettingsPage2({super.key});

  @override
  State<SettingsPage2> createState() => _SettingsPage2State();
}

class _SettingsPage2State extends State<SettingsPage2> {
  dynamic _profile;
  String? _email;
  bool _loading = true;
  String? _error;
  String _activeTab = 'persona';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _email = userProvider.userEmail;
      // Usar getMyProfile (GET /api/profile) en lugar de getProfileById:
      // /api/profiles/{id} espera profile ID, no user ID
      _profile = await ProfileService().getMyProfile();
      if (_profile == null) {
        throw Exception('No se encontró el perfil');
      }
      logger.i('Perfil cargado correctamente: $_profile');
    } catch (e) {
      setState(() => _error = 'Error al cargar el perfil');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Abre la cámara para tomar una nueva foto de perfil, la sube y actualiza la cabecera.
  Future<void> _pickAndUpdatePhoto() async {
    if (_profile == null) return;
    final profile = _profile as Profile;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (pickedFile == null || !mounted) return;
      bool dialogShown = false;
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        dialogShown = true;
      }
      try {
        await ProfileService().updateProfile(profile.id, profile, imageFile: File(pickedFile.path));
        if (!mounted) return;
        if (dialogShown) Navigator.of(context).pop();
        await _loadProfile();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );
      } catch (e) {
        if (!mounted) return;
        if (dialogShown) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la foto: $e')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir la cámara: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCommerce = Provider.of<UserProvider>(context, listen: false).userRole == 'commerce';
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Configuraciones')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadProfile, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        title: Text(
          _headerTitleForTab(_activeTab),
          style: GoogleFonts.plusJakartaSans(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_activeTab == 'mas' ? Icons.logout : Icons.settings),
            onPressed: _activeTab == 'mas'
                ? () async {
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    await userProvider.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                      (_) => false,
                    );
                  }
                : () {},
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabPills(theme, isCommerce),
          Expanded(
            child: _activeTab == 'comercios' && isCommerce
                ? const CommerceListPage(embedded: true)
                : RefreshIndicator(
                    onRefresh: _loadProfile,
                    color: theme.colorScheme.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(isTablet ? 24 : 24, 0, isTablet ? 24 : 24, isTablet ? 40 : 40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_activeTab == 'persona') ...[
                              _buildProfileHeader(context, theme, isTablet),
                              SizedBox(height: isTablet ? 24 : 20),
                              _buildPersonaContent(context, theme, isTablet, isCommerce),
                            ],
                            if (_activeTab == 'publicaciones' && isCommerce) _buildPublicacionesContent(context, theme, isTablet),
                            if (_activeTab == 'mas') _buildMasContent(context, theme, isTablet),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _headerTitleForTab(String tab) {
    switch (tab) {
      case 'comercios':
        return 'Mis Comercios';
      case 'mas':
        return 'Más';
      default:
        return 'Mi Perfil';
    }
  }

  Widget _buildTabPills(ThemeData theme, bool isCommerce) {
    final isDark = theme.brightness == Brightness.dark;
    const activeBg = _stitchPrimary;
    final inactiveBg = isDark ? _stitchSurfaceDark : theme.colorScheme.surfaceContainerLow;
    final inactiveColor = isDark ? const Color(0xFF9CA3AF) : theme.colorScheme.onSurfaceVariant;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _buildPill('persona', Icons.person_outline, 'Persona', theme, activeBg, inactiveBg, inactiveColor),
          const SizedBox(width: 8),
          if (isCommerce) ...[
            _buildPill('publicaciones', Icons.article_outlined, 'Publicaciones', theme, activeBg, inactiveBg, inactiveColor),
            const SizedBox(width: 8),
            _buildPill('comercios', Icons.storefront_outlined, 'Comercios', theme, activeBg, inactiveBg, inactiveColor),
            const SizedBox(width: 8),
          ],
          _buildPill('mas', Icons.grid_view_rounded, 'Más', theme, activeBg, inactiveBg, inactiveColor),
        ],
      ),
    );
  }

  Widget _buildPill(String tab, IconData icon, String label, ThemeData theme, Color activeBg, Color inactiveBg, Color inactiveColor) {
    final isActive = _activeTab == tab;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _activeTab = tab),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(24), // puntas redondeadas como Add Restaurante
            border: theme.brightness == Brightness.dark ? Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1) : null,
            boxShadow: isActive ? [BoxShadow(color: activeBg.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isActive ? Colors.white : inactiveColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? Colors.white : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ThemeData theme, bool isTablet) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: isTablet ? 100 : 96,
              height: isTablet ? 100 : 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_stitchPrimary, Colors.cyan.shade400],
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: GestureDetector(
                onTap: _pickAndUpdatePhoto,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.scaffoldBackgroundColor,
                  ),
                  child: _profile?.photo != null && _profile!.photo!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            _profile!.photo!,
                            width: (isTablet ? 100 : 96) - 8,
                            height: (isTablet ? 100 : 96) - 8,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/default_avatar.png',
                              width: (isTablet ? 100 : 96) - 8,
                              height: (isTablet ? 100 : 96) - 8,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: (isTablet ? 100 : 96) / 2 - 4,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.person, size: isTablet ? 40 : 36, color: theme.colorScheme.onSurfaceVariant),
                        ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ProfilePagex(userId: userProvider.userId),
                )),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? _stitchSurfaceLighter : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.scaffoldBackgroundColor, width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '${_profile?.firstName ?? ''} ${_profile?.lastName ?? ''}'.trim().isEmpty
              ? 'Usuario' : '${_profile?.firstName ?? ''} ${_profile?.lastName ?? ''}'.trim(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _email ?? 'Correo no disponible',
          style: TextStyle(
            fontSize: isTablet ? 14 : 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonaContent(BuildContext context, ThemeData theme, bool isTablet, bool isCommerce) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? _stitchSurfaceDark : theme.colorScheme.surface;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : theme.colorScheme.outline.withValues(alpha: 0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ProfilePagex(userId: userProvider.userId),
                )),
                icon: const Icon(Icons.edit_square, size: 18),
                label: const Text('Editar Perfil'),
                style: FilledButton.styleFrom(
                  backgroundColor: _stitchPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => isCommerce ? const CommerceOrdersPage() : const OrdersPage(),
                )),
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('Mis Pedidos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildStitchTile(
          context: context,
          theme: theme,
          icon: Icons.folder_open,
          iconColor: Colors.purple,
          title: 'Documentos',
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => DocumentListScreen(userId: userProvider.userId),
          )),
        ),
        const SizedBox(height: 12),
        _buildStitchTile(
          context: context,
          theme: theme,
          icon: Icons.location_on,
          iconColor: Colors.orange,
          title: 'Direcciones',
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => AddressPage(userId: userProvider.userId),
          )),
        ),
        const SizedBox(height: 12),
        _buildStitchTile(
          context: context,
          theme: theme,
          icon: Icons.call,
          iconColor: Colors.green,
          title: 'Teléfonos',
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => PhoneScreen(userId: userProvider.userId),
          )),
        ),
        if (isCommerce) ...[
          const SizedBox(height: 20),
          _buildEstadisticasCard(context, theme, isTablet, surfaceColor, borderColor),
        ],
        const SizedBox(height: 20),
        _buildLegalCard(context, theme, isTablet, surfaceColor, borderColor),
        const SizedBox(height: 20),
        Material(
          color: theme.colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () async {
              await userProvider.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (_) => false,
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 20, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.error, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const AccountDeletionPage(),
          )),
          child: Text(
            'Eliminar cuenta permanentemente',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStitchTile({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color surfaceColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadisticasCard(BuildContext context, ThemeData theme, bool isTablet, Color surfaceColor, Color borderColor) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: CommercePostService.getMyPosts(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.length : 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ESTADÍSTICAS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      children: [
                        Text(
                          count.toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Publicaciones',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      children: [
                        Text(
                          count.toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _stitchPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Activas',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegalCard(BuildContext context, ThemeData theme, bool isTablet, Color surfaceColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LEGAL',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Material(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Términos',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Condiciones de uso',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Material(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const PrivacySettingsPage(),
                  )),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacidad',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Política de datos',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPublicacionesContent(BuildContext context, ThemeData theme, bool isTablet) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: CommercePostService.getMyPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(isTablet ? 48 : 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 192,
                      height: 192,
                      decoration: BoxDecoration(
                        color: (theme.brightness == Brightness.dark ? _stitchSurfaceDark : theme.colorScheme.surfaceContainerLow)
                            .withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.rocket_launch, size: 96, color: _stitchPrimary.withValues(alpha: 0.3)),
                    ),
                    Positioned(
                      top: -16,
                      right: -16,
                      child: Icon(Icons.description, size: 48, color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    Positioned(
                      bottom: 8,
                      left: -24,
                      child: Icon(Icons.star, size: 36, color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'No tienes publicaciones aún',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isTablet ? 22 : 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Crea tu primera publicación para empezar a compartir tus sabores favoritos',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Crear Publicación'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _stitchPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ],
            ),
          );
        }
        return _buildSettingsCard(
          theme: theme,
          isTablet: isTablet,
          children: [
            for (int i = 0; i < posts.length; i++) ...[
              if (i > 0) _buildDivider(theme),
              _buildPostTile(context, theme, posts[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPostTile(BuildContext context, ThemeData theme, Map<String, dynamic> post) {
    final name = post['name']?.toString() ?? 'Sin título';
    final desc = post['description']?.toString() ?? '';
    return ListTile(
      leading: post['media_url'] != null && post['media_url'].toString().isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post['media_url'].toString(),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.article, color: theme.colorScheme.primary),
              ),
            )
          : Icon(Icons.article, color: theme.colorScheme.primary),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: desc.isNotEmpty ? Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
      trailing: const Icon(Icons.chevron_right),
    );
  }

  Widget _buildMasContent(BuildContext context, ThemeData theme, bool isTablet) {
    final isCommerce = Provider.of<UserProvider>(context, listen: false).userRole == 'commerce';
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? _stitchSurfaceDark : theme.colorScheme.surface;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : theme.colorScheme.outline.withValues(alpha: 0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMasSection(
          context: context,
          theme: theme,
          title: 'CUENTA',
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          tiles: [
            _MasTile(icon: Icons.history_rounded, iconColor: _stitchPrimary, title: 'Historial de actividad', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityHistoryPage()))),
            _MasTile(icon: Icons.download_rounded, iconColor: Colors.green, title: 'Exportar datos', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataExportPage()))),
            _MasTile(icon: Icons.privacy_tip_outlined, iconColor: Colors.orange, title: 'Privacidad', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsPage()))),
          ],
        ),
        if (isCommerce) ...[
          const SizedBox(height: 24),
          _buildMasSection(
            context: context,
            theme: theme,
            title: 'CONFIGURACIÓN DE NEGOCIO',
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            tiles: [
              _MasTile(icon: Icons.store, iconColor: Colors.blue, title: 'Datos del comercio', subtitle: 'Información básica y contacto', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommerceDataPage()))),
              _MasTile(icon: Icons.payments, iconColor: Colors.green, title: 'Métodos de pago', subtitle: 'Cuentas bancarias y móviles', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommercePaymentMethodsPage()))),
              _MasTile(icon: Icons.schedule, iconColor: Colors.purple, title: 'Horarios', subtitle: 'Apertura y cierre', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommerceSchedulePage()))),
            ],
          ),
          const SizedBox(height: 24),
          _buildMasSection(
            context: context,
            theme: theme,
            title: 'PROMOCIONES Y VENTAS',
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            tiles: [
              _MasTile(icon: Icons.campaign, iconColor: Colors.orange, title: 'Crear promo', subtitle: 'Impulsa tus ventas', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommercePromotionsPage()))),
              _MasTile(icon: Icons.local_activity, iconColor: Colors.amber, title: 'Cupones', subtitle: 'Gestionar descuentos', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommercePromotionsPage()))),
            ],
          ),
          const SizedBox(height: 24),
          _buildMasSection(
            context: context,
            theme: theme,
            title: 'MÁS OPCIONES',
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            tiles: [
              _MasTile(icon: Icons.toggle_on_rounded, iconColor: Colors.red, title: 'Estado abierto/cerrado', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommerceOpenPage()))),
              _MasTile(icon: Icons.map_outlined, iconColor: AppColors.brown, title: 'Zonas de delivery', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommerceZonesPage()))),
              _MasTile(icon: Icons.payment_rounded, iconColor: Colors.green, title: 'Datos de pago móvil', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommercePaymentPage()))),
              _MasTile(icon: Icons.notifications_outlined, iconColor: Colors.amber, title: 'Notificaciones del comercio', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommerceNotificationsPage()))),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _buildMasSectionSoporte(context, theme, surfaceColor, borderColor),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMasSection({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required Color surfaceColor,
    required Color borderColor,
    required List<_MasTile> tiles,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                if (i > 0) Divider(height: 1, color: borderColor),
                _buildMasTileWidget(context, theme, tiles[i], surfaceColor),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMasTileWidget(BuildContext context, ThemeData theme, _MasTile tile, Color surfaceColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tile.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tile.iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(tile.icon, color: tile.iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tile.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (tile.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        tile.subtitle!,
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasSectionSoporte(BuildContext context, ThemeData theme, Color surfaceColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'SOPORTE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpAndFAQPage())),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.pink.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.help, color: Colors.pink, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Ayuda',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: borderColor),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.cyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.notifications, color: Colors.cyan, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Notificaciones',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Switch(
                          value: true,
                          onChanged: (_) {},
                          activeTrackColor: _stitchPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: borderColor),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyApp())),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Acerca de',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Versión 1.0.0',
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required ThemeData theme,
    required bool isTablet,
    required List<Widget> children,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? _stitchSurfaceDark : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : theme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }

}
