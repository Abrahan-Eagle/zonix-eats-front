import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/utils/auth_utils.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/profile_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/models/profile_model.dart';
import 'package:zonix/features/DomainProfiles/Addresses/api/adresse_service.dart';
import 'package:zonix/features/screens/auth/sign_in_screen.dart';
import 'package:zonix/features/DomainProfiles/Addresses/screens/adresse_list_screen.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/DomainProfiles/Phones/screens/phone_list_screen.dart';
import 'package:zonix/features/screens/about/about_page.dart';
import 'package:zonix/features/screens/help/help_and_faq_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix/features/screens/notifications/notifications_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/activity_history_page.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/data_export_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zonix/features/screens/account_deletion_page.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/screens/settings/commerce_data_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zonix/config/app_config.dart';
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

  /// Ciudad resuelta por API cuando la dirección solo trae city_id (sin objeto city).
  String? _resolvedCityName;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
      _resolvedCityName = null;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      // Intentar primero desde el provider; si viene vacío, leer directo de AuthUtils.
      final providerEmail = userProvider.userEmail;
      if (providerEmail.isNotEmpty) {
        _email = providerEmail;
      } else {
        _email = await AuthUtils.getUserEmail();
      }
      // Usar getMyProfile (GET /api/profile) en lugar de getProfileById:
      // /api/profiles/{id} espera profile ID, no user ID
      _profile = await ProfileService().getMyProfile();
      if (_profile == null) {
        throw Exception('No se encontró el perfil');
      }
      logger.i('Perfil cargado correctamente: $_profile');
      if (_profile is Profile) {
        final profile = _profile as Profile;

        // Hacemos el esfuerzo por obtener la ciudad real cargando la dirección asociada
        // Primero desde addressesData para ahorrarnos la primera llamada si la info ya viene en el login.
        if (mounted) {
          try {
            final addressService = AddressService();
            int? cityIdToFetch;

            final addrs = profile.addressesData;
            if (addrs != null && addrs.isNotEmpty) {
              Map<String, dynamic> addr = addrs.first;
              for (final e in addrs) {
                if (e['is_default'] == true || e['is_default'] == 1) {
                  addr = e;
                  break;
                }
              }
              final raw = addr['city_id'];
              cityIdToFetch = raw is int
                  ? raw
                  : (raw != null ? int.tryParse(raw.toString()) : null);
            }

            // Si no vino en addressesData, probamos llamando al endpoint AddressService para estar seguros
            if (cityIdToFetch == null || cityIdToFetch <= 0) {
              final address =
                  await addressService.getAddressById(profile.userId);
              if (address != null && address.cityId > 0) {
                cityIdToFetch = address.cityId;
              }
            }

            // Si conseguimos un ID de ciudad, lo traemos
            if (cityIdToFetch != null && cityIdToFetch > 0) {
              final cityName =
                  await addressService.fetchCityById(cityIdToFetch);
              if (cityName != null && cityName.trim().isNotEmpty && mounted) {
                setState(() {
                  _resolvedCityName = cityName.trim();
                });
              }
            } else if ((profile.address ?? '').trim().isNotEmpty && mounted) {
              // Fallback a texto en bruto
              setState(() {
                _resolvedCityName = profile.address!.trim();
              });
            }
          } catch (e) {
            logger.w('No se pudo cargar la ciudad desde la dirección: $e');
          }
        }
      }
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
        await ProfileService().updateProfile(profile.id, profile,
            imageFile: File(pickedFile.path));
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

  /// Abre la galería para elegir una foto de perfil, la sube y actualiza la cabecera.
  Future<void> _pickFromGalleryAndUpdatePhoto() async {
    if (_profile == null) return;
    final profile = _profile as Profile;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
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
        await ProfileService().updateProfile(profile.id, profile,
            imageFile: File(pickedFile.path));
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
        SnackBar(content: Text('Error al abrir la galería: $e')),
      );
    }
  }

  /// Modal foto de perfil: usa colores de la app (AppColors + theme) y soporta modo claro/oscuro.
  void _showProfilePhotoModal(
      BuildContext context, ThemeData theme, bool isTablet) {
    final isDark = theme.brightness == Brightness.dark;
    final String? photoUrl = _profile?.photo;
    final username = _email != null && _email!.trim().isNotEmpty
        ? '@${_email!.trim().split('@').first}'
        : '@usuario_zonix';

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Backdrop con blur (template: bg-slate-900/60 backdrop-blur-sm)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: AnimatedOpacity(
                opacity: animation.value,
                duration: const Duration(milliseconds: 200),
                child: Container(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.2)),
              ),
            ),
            // Contenido del modal
            ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: _buildProfilePhotoModalContent(
                context,
                username: username,
                photoUrl: photoUrl,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfilePhotoModalContent(
    BuildContext context, {
    required String username,
    required String? photoUrl,
  }) {
    final modalTheme = Theme.of(context);
    final isDark = modalTheme.brightness == Brightness.dark;
    final colorScheme = modalTheme.colorScheme;
    final bgColor = modalTheme.scaffoldBackgroundColor;
    final titleColor = AppColors.primaryText(context);
    final subtitleColor = AppColors.secondaryText(context);
    final cardBg = AppColors.cardBg(context);
    final primaryBtnColor = AppColors.primaryButton(context);
    final borderColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.3)
        : colorScheme.outline.withValues(alpha: 0.2);
    final handleColor = colorScheme.outline.withValues(alpha: 0.5);

    return Dialog(
      backgroundColor: bgColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      elevation: 24,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 384),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              Text(
                                'Mi Perfil',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                username,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: subtitleColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: 192,
                          height: 192,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child: photoUrl != null && photoUrl.isNotEmpty
                                ? Image.network(
                                    photoUrl,
                                    width: 192,
                                    height: 192,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.person,
                                        size: 64,
                                        color: subtitleColor,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.person,
                                      size: 64,
                                      color: subtitleColor,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _pickAndUpdatePhoto();
                            },
                            icon: const Icon(Icons.photo_camera_outlined,
                                size: 22),
                            label: const Text('Tomar nueva foto'),
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryBtnColor,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: Material(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                _pickFromGalleryAndUpdatePhoto();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_library_outlined,
                                      size: 22,
                                      color: titleColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Elegir de la galería',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: titleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 14,
                              color: subtitleColor,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Tu foto es visible para repartidores y comercios',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: subtitleColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 6,
                        decoration: BoxDecoration(
                          color: handleColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: titleColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F7F8);
    final isCommerce =
        Provider.of<UserProvider>(context, listen: false).userRole ==
            'commerce';
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    if (_loading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(title: const Text('Configuraciones')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadProfile, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
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
                    final userProvider =
                        Provider.of<UserProvider>(context, listen: false);
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
                      padding: EdgeInsets.fromLTRB(
                        isTablet ? 24 : 24,
                        _activeTab == 'persona' ? 20 : 0,
                        isTablet ? 24 : 24,
                        isTablet ? 40 : 40,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_activeTab == 'persona') ...[
                              _buildProfileHeader(context, theme, isTablet),
                              const SizedBox(height: 24),
                              _buildPersonaContent(
                                context,
                                theme,
                                isTablet,
                                isCommerce,
                              ),
                            ],
                            if (_activeTab == 'publicaciones' && isCommerce)
                              _buildPublicacionesContent(
                                  context, theme, isTablet),
                            if (_activeTab == 'mas')
                              _buildMasContent(context, theme, isTablet),
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

  /// Devuelve la base URL para las páginas legales (términos, privacidad, etc.).
  /// - Si APP_DOMAIN está definido, usa https://APP_DOMAIN
  /// - Si no, usa AppConfig.apiUrl (API_URL_LOCAL / API_URL_PROD desde .env)
  String _legalBaseUrl() {
    final appDomain = dotenv.env['APP_DOMAIN']?.trim();
    if (appDomain != null && appDomain.isNotEmpty) {
      final hasScheme =
          appDomain.startsWith('http://') || appDomain.startsWith('https://');
      return hasScheme ? appDomain : 'https://$appDomain';
    }
    return AppConfig.apiUrl;
  }

  Widget _buildTabPills(ThemeData theme, bool isCommerce) {
    final isDark = theme.brightness == Brightness.dark;
    const activeBg = _stitchPrimary;
    final inactiveBg =
        isDark ? _stitchSurfaceDark : theme.colorScheme.surfaceContainerLow;
    final inactiveColor =
        isDark ? const Color(0xFF9CA3AF) : theme.colorScheme.onSurfaceVariant;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _buildPill('persona', Icons.person_outline, 'Persona', theme,
              activeBg, inactiveBg, inactiveColor),
          const SizedBox(width: 8),
          if (isCommerce) ...[
            _buildPill('publicaciones', Icons.article_outlined, 'Publicaciones',
                theme, activeBg, inactiveBg, inactiveColor),
            const SizedBox(width: 8),
            _buildPill('comercios', Icons.storefront_outlined, 'Comercios',
                theme, activeBg, inactiveBg, inactiveColor),
            const SizedBox(width: 8),
          ],
          _buildPill('mas', Icons.grid_view_rounded, 'Más', theme, activeBg,
              inactiveBg, inactiveColor),
        ],
      ),
    );
  }

  Widget _buildPill(String tab, IconData icon, String label, ThemeData theme,
      Color activeBg, Color inactiveBg, Color inactiveColor) {
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
            borderRadius: BorderRadius.circular(
                24), // puntas redondeadas como Add Restaurante
            border: theme.brightness == Brightness.dark
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.05), width: 1)
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: activeBg.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16, color: isActive ? Colors.white : inactiveColor),
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

  Widget _buildProfileHeader(
      BuildContext context, ThemeData theme, bool isTablet) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => _showProfilePhotoModal(context, theme, isTablet),
              child: Container(
                width: isTablet ? 140 : 130,
                height: isTablet ? 140 : 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: _profile?.photo != null && _profile!.photo!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          _profile!.photo!,
                          width: isTablet ? 140 : 130,
                          height: isTablet ? 140 : 130,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/default_avatar.png',
                            width: isTablet ? 140 : 130,
                            height: isTablet ? 140 : 130,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Icon(Icons.person,
                        size: isTablet ? 48 : 44,
                        color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 8,
              child: GestureDetector(
                onTap: () => _showProfilePhotoModal(context, theme, isTablet),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Icon(Icons.photo_camera_outlined,
                      size: 20, color: theme.colorScheme.onSurface),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '${_profile?.firstName ?? ''} ${_profile?.lastName ?? ''}'
                  .trim()
                  .isEmpty
              ? 'Usuario'
              : '${_profile?.firstName ?? ''} ${_profile?.lastName ?? ''}'
                  .trim(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Builder(
          builder: (context) {
            final rawEmail = _email?.trim() ?? '';
            final displayEmail =
                rawEmail.isNotEmpty ? rawEmail : 'correo@ejemplo.com';
            return Text(
              displayEmail,
              style: TextStyle(
                fontSize: isTablet ? 14 : 13,
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.75)
                    : theme.colorScheme.onSurfaceVariant,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPersonaContent(
      BuildContext context, ThemeData theme, bool isTablet, bool isCommerce) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor =
        isDark ? _stitchSurfaceDark : theme.colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : theme.colorScheme.outline.withValues(alpha: 0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePagex(userId: userProvider.userId),
                    )),
                icon: const Icon(Icons.edit_square, size: 18),
                label: const Text('Editar Perfil'),
                style: FilledButton.styleFrom(
                  backgroundColor: _stitchPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => isCommerce
                          ? const CommerceOrdersPage()
                          : const OrdersPage(),
                    )),
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('Mis Pedidos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildStitchTile(
          context: context,
          theme: theme,
          icon: Icons.location_on,
          iconColor: Colors.orange,
          title: 'Direcciones guardadas',
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddressPage(userId: userProvider.userId),
              )),
        ),
        const SizedBox(height: 12),
        _buildStitchTile(
          context: context,
          theme: theme,
          icon: Icons.credit_card,
          iconColor: Colors.orange,
          title: 'Métodos de pago',
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          onTap: () {
            // Reutilizamos la lógica existente: si es comercio, abrimos métodos de pago del comercio;
            // si es usuario normal, por ahora mostramos la misma pantalla (se puede afinar luego).
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => isCommerce
                    ? const CommercePaymentMethodsPage()
                    : const CommercePaymentMethodsPage(),
              ),
            );
          },
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
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PhoneScreen(userId: userProvider.userId),
              )),
        ),
        const SizedBox(height: 20),
        _buildPersonalInfoCard(theme, isTablet),
        if (isCommerce) ...[
          const SizedBox(height: 20),
          _buildEstadisticasCard(
              context, theme, isTablet, surfaceColor, borderColor),
        ],
        const SizedBox(height: 24),
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
                  Text('Cerrar sesión',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.error,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
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
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Card de "Información Personal" similar al template HTML, usando datos de Profile.
  Widget _buildPersonalInfoCard(ThemeData theme, bool isTablet) {
    if (_profile == null || _profile is! Profile) {
      return const SizedBox.shrink();
    }
    final profile = _profile as Profile;
    String formatGender(String sex) {
      final value = sex.toLowerCase();
      if (value == 'm' || value == 'masculino') return 'Masculino';
      if (value == 'f' || value == 'femenino') return 'Femenino';
      return 'Otro';
    }

    String formatDate(String raw) {
      if (raw.isEmpty) return '—';
      try {
        final dt = DateTime.parse(raw);
        final day = dt.day.toString().padLeft(2, '0');
        final month = dt.month.toString().padLeft(2, '0');
        final year = dt.year.toString();
        return '$day/$month/$year';
      } catch (_) {
        return raw;
      }
    }

    String formatPhone(String raw) {
      if (raw.isEmpty) return '—';
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 10) {
        // e.g. 4124241234 -> 412-4241234
        final prefix = digits.substring(0, 3);
        final rest = digits.substring(3);
        return '$prefix-$rest';
      }
      return raw;
    }

    final phone = (profile.phone ?? '').trim().isEmpty
        ? '—'
        : formatPhone(profile.phone!.trim());
    final city = (_resolvedCityName ?? profile.address ?? '').trim().isEmpty
        ? '—'
        : (_resolvedCityName ?? profile.address!).trim();
    final gender = formatGender(profile.sex);
    final dob = formatDate(profile.dateOfBirth);

    final surface = theme.brightness == Brightness.dark
        ? _stitchSurfaceDark
        : theme.colorScheme.surface;
    final border = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.05)
        : theme.colorScheme.outline.withValues(alpha: 0.15);

    Text label(String text) {
      return Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    Text value(String text) {
      return Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: isTablet
              ? 14
              : 14, // Aumentado ligeramente para coincidir con template
          fontWeight: FontWeight.bold, // Segun template texto oscuro en bold
          color: theme.brightness == Brightness.dark
              ? Colors.white
              : theme.colorScheme.onSurface,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Personal',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          // Forzar grid 2x2 como en el template (Teléfono/Ciudad, Género/Fecha de nac.).
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label('Teléfono'),
                        const SizedBox(height: 4),
                        value(phone),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label('Ciudad'),
                        const SizedBox(height: 4),
                        value(city),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label('Género'),
                        const SizedBox(height: 4),
                        value(gender),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label('Fecha de nac.'),
                        const SizedBox(height: 4),
                        value(dob),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasCard(BuildContext context, ThemeData theme,
      bool isTablet, Color surfaceColor, Color borderColor) {
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
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
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
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
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500),
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

  Widget _buildLegalCard(BuildContext context, ThemeData theme, bool isTablet,
      Color surfaceColor, Color borderColor) {
    // Links centrados tipo texto, alineados con el template HTML.
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () async {
            final baseUrl = _legalBaseUrl();
            final uri = Uri.parse('$baseUrl/terminos-condiciones');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Text(
            'TÉRMINOS DE SERVICIO',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () async {
            final baseUrl = _legalBaseUrl();
            final uri = Uri.parse('$baseUrl/politica-privacidad');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Text(
            'POLÍTICA DE PRIVACIDAD',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () async {
            final baseUrl = _legalBaseUrl();
            final uri = Uri.parse('$baseUrl/politica-cookies');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Text(
            'POLÍTICA DE COOKIES',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () async {
            final baseUrl = _legalBaseUrl();
            final uri = Uri.parse('$baseUrl/seguridad');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Text(
            'SEGURIDAD',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPublicacionesContent(
      BuildContext context, ThemeData theme, bool isTablet) {
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
                        color: (theme.brightness == Brightness.dark
                                ? _stitchSurfaceDark
                                : theme.colorScheme.surfaceContainerLow)
                            .withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.rocket_launch,
                          size: 96,
                          color: _stitchPrimary.withValues(alpha: 0.3)),
                    ),
                    Positioned(
                      top: -16,
                      right: -16,
                      child: Icon(Icons.description,
                          size: 48, color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    Positioned(
                      bottom: 8,
                      left: -24,
                      child: Icon(Icons.star,
                          size: 36, color: Colors.white.withValues(alpha: 0.1)),
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
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

  Widget _buildPostTile(
      BuildContext context, ThemeData theme, Map<String, dynamic> post) {
    final name = post['name']?.toString() ?? 'Sin título';
    final desc = post['description']?.toString() ?? '';
    return ListTile(
      leading:
          post['media_url'] != null && post['media_url'].toString().isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post['media_url'].toString(),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.article, color: theme.colorScheme.primary),
                  ),
                )
              : Icon(Icons.article, color: theme.colorScheme.primary),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: desc.isNotEmpty
          ? Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
      trailing: const Icon(Icons.chevron_right),
    );
  }

  Widget _buildMasContent(
      BuildContext context, ThemeData theme, bool isTablet) {
    final isCommerce =
        Provider.of<UserProvider>(context, listen: false).userRole ==
            'commerce';
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor =
        isDark ? _stitchSurfaceDark : theme.colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : theme.colorScheme.outline.withValues(alpha: 0.2);

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
            _MasTile(
              icon: Icons.history_rounded,
              iconColor: _stitchPrimary,
              title: 'Historial de actividad',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ActivityHistoryPage())),
            ),
            _MasTile(
              icon: Icons.download_rounded,
              iconColor: Colors.green,
              title: 'Exportar datos',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DataExportPage())),
            ),
            _MasTile(
              icon: Icons.privacy_tip_outlined,
              iconColor: Colors.orange,
              title: 'Privacidad',
              onTap: () async {
                final baseUrl = dotenv.env['APP_DOMAIN'] != null
                    ? 'https://${dotenv.env['APP_DOMAIN']}'
                    : 'https://eats.aiblockweb.com';
                final uri = Uri.parse('$baseUrl/politica-de-privacidad');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
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
              _MasTile(
                  icon: Icons.store,
                  iconColor: Colors.blue,
                  title: 'Datos del comercio',
                  subtitle: 'Información básica y contacto',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CommerceDataPage()))),
              _MasTile(
                  icon: Icons.payments,
                  iconColor: Colors.green,
                  title: 'Métodos de pago',
                  subtitle: 'Cuentas bancarias y móviles',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CommercePaymentMethodsPage()))),
              _MasTile(
                  icon: Icons.schedule,
                  iconColor: Colors.purple,
                  title: 'Horarios',
                  subtitle: 'Apertura y cierre',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CommerceSchedulePage()))),
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
              _MasTile(
                  icon: Icons.campaign,
                  iconColor: Colors.orange,
                  title: 'Crear promo',
                  subtitle: 'Impulsa tus ventas',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CommercePromotionsPage()))),
              _MasTile(
                  icon: Icons.local_activity,
                  iconColor: Colors.amber,
                  title: 'Cupones',
                  subtitle: 'Gestionar descuentos',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CommercePromotionsPage()))),
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
              _MasTile(
                  icon: Icons.toggle_on_rounded,
                  iconColor: Colors.red,
                  title: 'Estado abierto/cerrado',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CommerceOpenPage()))),
              _MasTile(
                  icon: Icons.map_outlined,
                  iconColor: AppColors.brown,
                  title: 'Zonas de delivery',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CommerceZonesPage()))),
              _MasTile(
                  icon: Icons.payment_rounded,
                  iconColor: Colors.green,
                  title: 'Datos de pago móvil',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CommercePaymentPage()))),
              _MasTile(
                  icon: Icons.notifications_outlined,
                  iconColor: Colors.amber,
                  title: 'Notificaciones del comercio',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CommerceNotificationsPage()))),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _buildMasSectionSoporte(context, theme, surfaceColor, borderColor),
        const SizedBox(height: 32),
        _buildLegalCard(context, theme, isTablet, surfaceColor, borderColor),
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

  Widget _buildMasTileWidget(BuildContext context, ThemeData theme,
      _MasTile tile, Color surfaceColor) {
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
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasSectionSoporte(BuildContext context, ThemeData theme,
      Color surfaceColor, Color borderColor) {
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
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HelpAndFAQPage())),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.pink.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.help,
                              color: Colors.pink, size: 22),
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
                        Icon(Icons.chevron_right,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 24),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: borderColor),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsPage())),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.cyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.notifications,
                              color: Colors.cyan, size: 22),
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
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AboutScreen())),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.info_outline,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 22),
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
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 24),
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
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.05))
            : null,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: theme.brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.05)
          : theme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }
}
