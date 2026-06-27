import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zonix_glasses/config/app_config.dart';
import 'package:zonix_glasses/features/DomainProfiles/Profiles/screens/profile_page.dart';
import 'package:zonix_glasses/features/screens/notifications/notifications_page.dart';
import 'package:zonix_glasses/features/screens/settings/settings_page_2.dart';
import 'package:zonix_glasses/features/utils/bottom_nav_persistence.dart';
import 'package:zonix_glasses/features/utils/user_provider.dart';
import 'package:zonix_glasses/widgets/app_offline_banner.dart';

class MainRouter extends StatefulWidget {
  const MainRouter({super.key});

  @override
  State<MainRouter> createState() => _MainRouterState();
}

class _MainRouterState extends State<MainRouter> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedIndex();
  }

  Future<void> _loadSavedIndex() async {
    final role = context.read<UserProvider>().userRole;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(bottomNavStorageKey(role));
    if (saved != null && mounted) {
      setState(() => _selectedIndex = saved.clamp(0, 3));
    }
  }

  Future<void> _persistIndex(int index) async {
    final role = context.read<UserProvider>().userRole;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(bottomNavStorageKey(role), index);
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<UserProvider>().userId;
    final pages = [
      const _HomePlaceholderPage(),
      const NotificationsPage(),
      ProfilePagex(userId: userId),
      const SettingsPage2(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(AppConfig.appName)),
      body: AppOfflineBanner(
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          _persistIndex(index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Avisos'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Más'),
        ],
      ),
    );
  }
}

class _HomePlaceholderPage extends StatelessWidget {
  const _HomePlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_customize_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Zonix Glasses',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Óptica online — catálogo, fórmulas y pedidos contra pedido.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
