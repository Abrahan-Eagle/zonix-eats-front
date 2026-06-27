/// Pantalla de Ayuda y Soporte (Help & FAQ).
///
/// - Contenido por rol: user, admin.
/// - Búsqueda en tiempo real sobre FAQs.
/// - Temas populares (grid) que filtran por palabra clave.
/// - Acordeón de preguntas frecuentes con "Ver todas".
/// - Contacto: Chat en vivo (abre URL de soporte) y Enviar correo.
library help_and_faq_page;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zonix_glasses/config/app_config.dart';
import 'package:zonix_glasses/features/utils/app_colors.dart';
import 'package:zonix_glasses/features/utils/user_provider.dart';

class HelpAndFAQPage extends StatefulWidget {
  const HelpAndFAQPage({super.key});

  @override
  State<HelpAndFAQPage> createState() => _HelpAndFAQPageState();
}

class _HelpAndFAQPageState extends State<HelpAndFAQPage> {
  static String get _supportEmail => AppConfig.supportEmail;
  static String get _supportUrl => AppConfig.supportUrl;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _faqSectionKey = GlobalKey();
  bool _showAllFaq = false;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final role = Provider.of<UserProvider>(context, listen: false).userRole;
    final faqEntries = _faqForRole(role);
    final popularTopics = _popularTopicsForRole(role);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.scaffoldBgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.grayDark : AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.white : AppColors.blueDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ayuda y Soporte',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.blueDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rocket_launch, color: AppColors.blue, size: 24),
            tooltip: 'Zonix Glasses',
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppColors.white12 : AppColors.borderLight,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _buildSearchBar(context, isDark, faqEntries),
                const SizedBox(height: 24),
                _buildSectionTitle(context, isDark, 'Temas populares'),
                const SizedBox(height: 12),
                _buildPopularTopics(context, isDark, popularTopics),
                const SizedBox(height: 24),
                _buildFaqSection(context, theme, isDark, role, faqEntries, _faqSectionKey),
                const SizedBox(height: 24),
                _buildContactCard(context, isDark),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    bool isDark,
    List<({String question, String answer})> faqEntries,
  ) {
    return ListenableBuilder(
      listenable: _searchController,
      builder: (context, _) {
        final query = _searchController.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? faqEntries
            : faqEntries.where((e) =>
                e.question.toLowerCase().contains(query) ||
                e.answer.toLowerCase().contains(query)).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: isDark
                  ? null
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {
                  _showAllFaq = false;
                }),
                decoration: InputDecoration(
                hintText: '¿Cómo podemos ayudarte?',
                hintStyle: const TextStyle(color: AppColors.textMutedGray),
                prefixIcon: Icon(
                  Icons.search,
                  color: query.isNotEmpty ? AppColors.blue : AppColors.textMutedGray,
                  size: 24,
                ),
                filled: true,
                fillColor: isDark ? AppColors.grayDark : AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.white12 : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.white12 : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
                style: TextStyle(
                  color: isDark ? AppColors.white : AppColors.blueDark,
                  fontSize: 15,
                ),
              ),
            ),
            if (query.isNotEmpty && filtered.isEmpty) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 40, color: AppColors.textMutedGray),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No hay resultados para "$query". Prueba con otras palabras.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMutedGray),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isDark ? AppColors.white54 : AppColors.textMutedGray,
        ),
      ),
    );
  }

  Widget _buildPopularTopics(
    BuildContext context,
    bool isDark,
    List<({String title, IconData icon, String searchKeyword})> topics,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: topics.map((t) {
        return Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: () {
              _searchController.text = t.searchKeyword;
              setState(() {});
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.grayDark : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.white12 : AppColors.borderLight,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(t.icon, color: AppColors.blue, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.blueDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFaqSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String role,
    List<({String question, String answer})> faqEntries,
    GlobalKey faqSectionKey,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? faqEntries
        : faqEntries.where((e) =>
            e.question.toLowerCase().contains(query) ||
            e.answer.toLowerCase().contains(query)).toList();
    final toShow = _showAllFaq ? filtered : filtered.take(4).toList();

    return Column(
      key: faqSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(context, isDark, 'Preguntas frecuentes'),
            if (filtered.length > 4 && !_showAllFaq)
              TextButton(
                onPressed: () {
                  setState(() => _showAllFaq = true);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final ctx = faqSectionKey.currentContext;
                    if (ctx != null) {
                      Scrollable.ensureVisible(
                        ctx,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  });
                },
                child: const Text('Ver todas', style: TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                )),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...toShow.map((e) => _buildFAQItem(context, theme, isDark, e.question, e.answer)),
      ],
    );
  }

  Widget _buildFAQItem(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String question,
    String answer,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: isDark
            ? null
            : BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
        child: Theme(
          data: theme.copyWith(dividerColor: AppColors.transparent),
          child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? AppColors.white12 : AppColors.borderLight,
            ),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? AppColors.white12 : AppColors.borderLight,
            ),
          ),
          backgroundColor: isDark ? AppColors.grayDark : AppColors.white,
          collapsedBackgroundColor: isDark ? AppColors.grayDark : AppColors.white,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(
            question,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.white : AppColors.blueDark,
            ),
          ),
          trailing: const Icon(
            Icons.expand_more,
            color: AppColors.textMutedGray,
            size: 24,
          ),
          children: [
            Container(
              padding: const EdgeInsets.only(left: 0),
              decoration: BoxDecoration(
                border: const Border(
                  left: BorderSide(color: AppColors.blue, width: 3),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.only(left: 4),
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? AppColors.white70 : AppColors.gray,
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

  Widget _buildContactCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Text(
            '¿Aún necesitas ayuda?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.blueDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nuestro equipo de soporte está disponible 24/7 para asistirte en tu viaje.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.white54 : AppColors.textMutedGray,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _launchChat(context),
              icon: const Icon(Icons.forum, size: 20),
              label: const Text('Chat en Vivo'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 2,
                shadowColor: AppColors.blue.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _launchEmail(context),
              icon: const Icon(Icons.mail, size: 20),
              label: const Text('Enviar un Correo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.white : AppColors.blueDark,
                side: BorderSide(color: isDark ? AppColors.white24 : AppColors.borderLight),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<({String title, IconData icon, String searchKeyword})> _popularTopicsForRole(String role) {
    if (role == 'admin') {
      return [
        (title: 'Usuarios', icon: Icons.people, searchKeyword: 'usuario'),
        (title: 'Seguridad', icon: Icons.security, searchKeyword: 'seguridad'),
        (title: 'Notificaciones', icon: Icons.notifications, searchKeyword: 'notificación'),
        (title: 'Soporte', icon: Icons.support_agent, searchKeyword: 'soporte'),
      ];
    }
    return [
      (title: 'Mi perfil', icon: Icons.person, searchKeyword: 'perfil'),
      (title: 'Direcciones', icon: Icons.location_on, searchKeyword: 'dirección'),
      (title: 'Notificaciones', icon: Icons.notifications, searchKeyword: 'notificación'),
      (title: 'Seguridad', icon: Icons.shield, searchKeyword: 'soporte'),
    ];
  }

  List<({String question, String answer})> _faqForRole(String role) {
    if (role == 'admin') return _faqAdmin;
    return _faqUsers;
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri.parse(
      'mailto:$_supportEmail?subject=${Uri.encodeComponent('Zonix Glasses - Soporte')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el correo. Escribe a $_supportEmail'),
            backgroundColor: AppColors.orange,
          ),
        );
      }
    }
  }

  Future<void> _launchChat(BuildContext context) async {
    final uri = Uri.parse(_supportUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir $_supportUrl'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  static final List<({String question, String answer})> _faqUsers = [
    (question: '¿Cómo completo mi perfil?', answer: 'Ve a Configuración → Mi perfil y completa tus datos personales. Puedes añadir foto, teléfonos y direcciones desde las secciones correspondientes.'),
    (question: '¿Cómo cambio o agrego una dirección?', answer: 'En Configuración → Direcciones guardadas puedes añadir, editar o marcar una como predeterminada.'),
    (question: '¿Cómo gestiono mis métodos de pago?', answer: 'Los métodos de pago se gestionan vía API REST (/api/payment-methods). Puedes añadir una pantalla dedicada en Configuración cuando el producto lo requiera.'),
    (question: '¿Cómo activo las notificaciones?', answer: 'La app solicita permiso al iniciar. También puedes revisar el estado en Configuración → Notificaciones.'),
    (question: '¿Cómo contacto a soporte?', answer: 'Correo a $_supportEmail o usa el enlace de chat más abajo. Indica tu correo de cuenta para una respuesta más rápida.'),
  ];

  static final List<({String question, String answer})> _faqAdmin = [
    (question: '¿Cómo gestiono usuarios?', answer: 'Desde el panel admin puedes listar usuarios, ver detalle con perfil y actualizar roles (user/admin).'),
    (question: '¿Dónde está la configuración de seguridad?', answer: 'Panel admin → Seguridad: políticas de acceso y opciones de la plataforma.'),
    (question: '¿Cómo veo actividad reciente?', answer: 'El dashboard muestra métricas básicas y actividad reciente de la plataforma.'),
    (question: '¿Cómo contacto a soporte técnico?', answer: 'Correo a $_supportEmail o enlace de soporte. Indica que eres administrador y el tipo de consulta.'),
  ];
}
