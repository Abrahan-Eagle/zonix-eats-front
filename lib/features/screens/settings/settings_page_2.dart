import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/DomainProfiles/Documents/screens/document_list_screen.dart';
import 'package:zonix/features/DomainProfiles/Phones/screens/phone_list_screen.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/DomainProfiles/Profiles/screens/profile_page.dart';
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
      final userDetails = await userProvider.getUserDetails();
      final id = userDetails['userId'];
      if (id == null) throw Exception('No se pudo obtener el ID del usuario');
      final userId = id is int ? id : int.tryParse(id.toString());
      if (userId == null) throw Exception('El ID del usuario no es válido: $id');
      _email = userDetails['users']['email'];
      _profile = await ProfileService().getProfileById(userId);
      logger.i('Perfil cargado correctamente: $_profile');
    } catch (e) {
      setState(() => _error = 'Error al cargar el perfil');
    } finally {
      if (mounted) setState(() => _loading = false);
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
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          'Mi Perfil',
          style: TextStyle(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _buildTabIcon(
            icon: Icons.person_outline_rounded,
            isActive: _activeTab == 'persona',
            onTap: () => setState(() => _activeTab = 'persona'),
            theme: theme,
            isTablet: isTablet,
          ),
          SizedBox(width: isTablet ? 10 : 6),
          if (isCommerce) ...[
            _buildTabIcon(
              icon: Icons.article_outlined,
              isActive: _activeTab == 'publicaciones',
              onTap: () => setState(() => _activeTab = 'publicaciones'),
              theme: theme,
              isTablet: isTablet,
            ),
            SizedBox(width: isTablet ? 10 : 6),
            _buildTabIcon(
              icon: Icons.store_outlined,
              isActive: _activeTab == 'comercios',
              onTap: () => setState(() => _activeTab = 'comercios'),
              theme: theme,
              isTablet: isTablet,
            ),
            SizedBox(width: isTablet ? 10 : 6),
          ],
          _buildTabIcon(
            icon: Icons.more_horiz_rounded,
            isActive: _activeTab == 'mas',
            onTap: () => setState(() => _activeTab = 'mas'),
            theme: theme,
            isTablet: isTablet,
          ),
          SizedBox(width: isTablet ? 16 : 12),
        ],
      ),
      body: _activeTab == 'comercios' && isCommerce
          ? const CommerceListPage(embedded: true)
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: theme.colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_activeTab != 'publicaciones') ...[
                        _buildProfileHeader(context, theme, isTablet),
                        SizedBox(height: isTablet ? 24 : 20),
                      ],
                      if (_activeTab == 'persona') _buildPersonaContent(context, theme, isTablet, isCommerce),
                      if (_activeTab == 'publicaciones' && isCommerce) _buildPublicacionesContent(context, theme, isTablet),
                      if (_activeTab == 'mas') _buildMasContent(context, theme, isTablet),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTabIcon({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isTablet ? 10 : 8),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: isTablet ? 24 : 22,
          color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ThemeData theme, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 28 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.primary, width: 2.5),
            ),
            child: CircleAvatar(
              radius: isTablet ? 40 : 32,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage: _getProfileImage(_profile?.photo),
              child: _profile?.photo == null
                  ? Icon(Icons.person, size: isTablet ? 40 : 32, color: theme.colorScheme.onSurfaceVariant)
                  : null,
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_profile?.firstName ?? ''} ${_profile?.lastName ?? ''}'.trim().isEmpty
                      ? 'Usuario' : '${_profile?.firstName ?? ''} ${_profile?.lastName ?? ''}'.trim(),
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 18,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaContent(BuildContext context, ThemeData theme, bool isTablet, bool isCommerce) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ProfilePagex(userId: userProvider.userId),
            )),
            icon: const Icon(Icons.edit),
            label: const Text('Editar Perfil'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        SizedBox(height: isTablet ? 12 : 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => isCommerce ? const CommerceOrdersPage() : const OrdersPage(),
            )),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Mis Pedidos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.green,
              side: const BorderSide(color: AppColors.green),
              padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        _buildSettingsCard(
          theme: theme,
          isTablet: isTablet,
          children: [
            _buildSettingsTile(
              context: context,
              theme: theme,
              icon: Icons.folder_outlined,
              iconColor: AppColors.purple,
              title: 'Documentos',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => DocumentListScreen(userId: userProvider.userId),
              )),
            ),
            _buildDivider(theme),
            _buildSettingsTile(
              context: context,
              theme: theme,
              icon: Icons.location_on_outlined,
              iconColor: AppColors.orange,
              title: 'Direcciones',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddressPage(userId: userProvider.userId),
              )),
            ),
            _buildDivider(theme),
            _buildSettingsTile(
              context: context,
              theme: theme,
              icon: Icons.phone_outlined,
              iconColor: AppColors.green,
              title: 'Teléfonos',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => PhoneScreen(userId: userProvider.userId),
              )),
            ),
          ],
        ),
        if (isCommerce) ...[
          SizedBox(height: isTablet ? 20 : 16),
          _buildEstadisticasCard(context, theme, isTablet),
        ],
        SizedBox(height: isTablet ? 20 : 16),
        _buildLegalCard(context, theme, isTablet),
        SizedBox(height: isTablet ? 20 : 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await userProvider.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (_) => false,
              );
            },
            icon: Icon(Icons.logout_rounded, size: isTablet ? 22 : 20),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
              padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        SizedBox(height: isTablet ? 12 : 10),
        TextButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const AccountDeletionPage(),
          )),
          icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
          label: Text('Eliminar cuenta', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w500)),
        ),
        SizedBox(height: isTablet ? 24 : 20),
      ],
    );
  }

  Widget _buildEstadisticasCard(BuildContext context, ThemeData theme, bool isTablet) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: CommercePostService.getMyPosts(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.length : 0;
        return _buildSettingsCard(
          theme: theme,
          isTablet: isTablet,
          children: [
            Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estadísticas',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatChip(
                          icon: Icons.article_outlined,
                          value: count.toString(),
                          label: 'Publicaciones',
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatChip(
                          icon: Icons.check_circle_outline,
                          value: count.toString(),
                          label: 'Activas',
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.green),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildLegalCard(BuildContext context, ThemeData theme, bool isTablet) {
    return _buildSettingsCard(
      theme: theme,
      isTablet: isTablet,
      children: [
        Padding(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Legal',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        _buildSettingsTile(
          context: context,
          theme: theme,
          icon: Icons.description_outlined,
          iconColor: theme.colorScheme.onSurfaceVariant,
          title: 'Términos y Condiciones',
          onTap: () {},
        ),
        _buildDivider(theme),
        _buildSettingsTile(
          context: context,
          theme: theme,
          icon: Icons.privacy_tip_outlined,
          iconColor: theme.colorScheme.onSurfaceVariant,
          title: 'Política de Privacidad',
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const PrivacySettingsPage(),
          )),
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
              children: [
                Icon(Icons.article_outlined, size: 80, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 24),
                Text(
                  'No tienes publicaciones aún',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea tu primera publicación para empezar',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSettingsCard(
          theme: theme,
          isTablet: isTablet,
          children: [
            _buildSettingsTile(
              context: context,
              theme: theme,
              icon: Icons.history_rounded,
              iconColor: theme.colorScheme.primary,
              title: 'Historial de actividad',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ActivityHistoryPage(),
              )),
            ),
            _buildDivider(theme),
            _buildSettingsTile(
              context: context,
              theme: theme,
              icon: Icons.download_rounded,
              iconColor: AppColors.green,
              title: 'Exportar datos',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const DataExportPage(),
              )),
            ),
            _buildDivider(theme),
            _buildSettingsTile(
              context: context,
              theme: theme,
              icon: Icons.privacy_tip_outlined,
              iconColor: AppColors.orange,
              title: 'Privacidad',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const PrivacySettingsPage(),
              )),
            ),
          ],
        ),
        if (isCommerce) ...[
          SizedBox(height: isTablet ? 20 : 16),
          _buildSettingsCard(
            theme: theme,
            isTablet: isTablet,
            children: [
              _buildSettingsTile(
                context: context,
                theme: theme,
                icon: Icons.store_rounded,
                iconColor: theme.colorScheme.primary,
                title: 'Datos del comercio',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const CommerceDataPage(),
                )),
              ),
              _buildDivider(theme),
              _buildSettingsTile(
                context: context,
                theme: theme,
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.green,
                title: 'Métodos de pago',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const CommercePaymentMethodsPage(),
                )),
              ),
              _buildDivider(theme),
              _buildSettingsTile(
                context: context,
                theme: theme,
                icon: Icons.schedule_rounded,
                iconColor: AppColors.orange,
                title: 'Horario de atención',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const CommerceSchedulePage(),
                )),
              ),
              _buildDivider(theme),
              _buildSettingsTile(
                context: context,
                theme: theme,
                icon: Icons.toggle_on_rounded,
                iconColor: AppColors.red,
                title: 'Estado abierto/cerrado',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const CommerceOpenPage(),
                )),
              ),
              _buildDivider(theme),
              _buildSettingsTile(
                context: context,
                theme: theme,
                icon: Icons.local_offer_rounded,
                iconColor: AppColors.red,
                title: 'Promociones y cupones',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const CommercePromotionsPage(),
                )),
              ),
              _buildDivider(theme),
              _buildSettingsTile(
                context: context,
                theme: theme,
                icon: Icons.map_outlined,
                iconColor: AppColors.brown,
                title: 'Zonas de delivery',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const CommerceZonesPage(),
                )),
              ),
              _buildDivider(theme),
              _buildSettingsTile(
                context: context,
                theme: theme,
                icon: Icons.payment_rounded,
                iconColor: AppColors.green,
                title: 'Datos de pago móvil',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const CommercePaymentPage(),
                )),
              ),
              _buildDivider(theme),
              _buildSettingsTile(
                context: context,
                theme: theme,
                icon: Icons.notifications_outlined,
                iconColor: AppColors.amber,
                title: 'Notificaciones del comercio',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const CommerceNotificationsPage(),
                )),
              ),
            ],
          ),
        ],
        SizedBox(height: isTablet ? 20 : 16),
        _buildSettingsCard(
          theme: theme,
          isTablet: isTablet,
          children: [
            _buildSettingsTile(
              context: context,
              theme: theme,
              icon: Icons.notifications_none_rounded,
              iconColor: AppColors.purple,
              title: 'Notificaciones',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const NotificationsPage(),
              )),
            ),
            _buildDivider(theme),
            _buildSettingsTile(
              context: context,
              theme: theme,
              icon: Icons.help_outline_rounded,
              iconColor: AppColors.purple,
              title: 'Ayuda y comentarios',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const HelpAndFAQPage(),
              )),
            ),
            _buildDivider(theme),
            _buildSettingsTile(
              context: context,
              theme: theme,
              icon: Icons.info_outline_rounded,
              iconColor: theme.colorScheme.onSurfaceVariant,
              title: 'Acerca de',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const MyApp(),
              )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required ThemeData theme,
    required bool isTablet,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 58,
      endIndent: 16,
      color: theme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }

  ImageProvider<Object> _getProfileImage(String? profilePhoto) {
    if (profilePhoto != null && profilePhoto.isNotEmpty) {
      if (profilePhoto.contains('via.placeholder.com') || profilePhoto.contains('placeholder.com')) {
        return const AssetImage('assets/default_avatar.png');
      }
      return NetworkImage(profilePhoto);
    }
    return const AssetImage('assets/default_avatar.png');
  }
}
