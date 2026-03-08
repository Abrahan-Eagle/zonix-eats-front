/// Pantalla de Ayuda y Soporte (Help & FAQ).
///
/// - Contenido por rol: users, commerce, delivery, delivery_company, admin.
/// - Búsqueda en tiempo real sobre FAQs.
/// - Temas populares (grid) que filtran por palabra clave.
/// - Acordeón de preguntas frecuentes con "Ver todas".
/// - Contacto: Chat en vivo (abre URL de soporte) y Enviar correo.
library help_and_faq_page;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/user_provider.dart';

class HelpAndFAQPage extends StatefulWidget {
  const HelpAndFAQPage({super.key});

  @override
  State<HelpAndFAQPage> createState() => _HelpAndFAQPageState();
}

class _HelpAndFAQPageState extends State<HelpAndFAQPage> {
  static const String _supportEmail = 'soporte@zonixeats.com';
  static const String _supportUrl = 'https://zonixeats.com/soporte';

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
        backgroundColor: isDark ? AppColors.grayDark : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Zonix Eats - Tu pedido más cerca'),
                  backgroundColor: AppColors.blue,
                  duration: Duration(seconds: 2),
                ),
              );
            },
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
                          color: Colors.black.withValues(alpha: 0.06),
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
                fillColor: isDark ? AppColors.grayDark : Colors.white,
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
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _searchController.text = t.searchKeyword;
              setState(() {});
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.grayDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.white12 : AppColors.borderLight,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
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
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
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
          backgroundColor: isDark ? AppColors.grayDark : Colors.white,
          collapsedBackgroundColor: isDark ? AppColors.grayDark : Colors.white,
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
                foregroundColor: Colors.white,
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
    switch (role) {
      case 'users':
        return [
          (title: 'Mis Pedidos', icon: Icons.shopping_bag, searchKeyword: 'pedido'),
          (title: 'Pagos y Reembolsos', icon: Icons.payments, searchKeyword: 'pago'),
          (title: 'Mi Cuenta', icon: Icons.person, searchKeyword: 'cuenta'),
          (title: 'Seguridad', icon: Icons.shield, searchKeyword: 'soporte'),
        ];
      case 'commerce':
        return [
          (title: 'Gestionar Pedidos', icon: Icons.receipt_long, searchKeyword: 'orden'),
          (title: 'Productos y Menú', icon: Icons.restaurant_menu, searchKeyword: 'producto'),
          (title: 'Promociones', icon: Icons.campaign, searchKeyword: 'promoción'),
          (title: 'Reportes', icon: Icons.analytics, searchKeyword: 'reporte'),
        ];
      case 'delivery':
      case 'delivery_agent':
        return [
          (title: 'Mis Entregas', icon: Icons.delivery_dining, searchKeyword: 'entrega'),
          (title: 'Rutas', icon: Icons.route, searchKeyword: 'ruta'),
          (title: 'Ganancias', icon: Icons.attach_money, searchKeyword: 'ganancia'),
          (title: 'Mi Estado', icon: Icons.toggle_on, searchKeyword: 'estado'),
        ];
      case 'delivery_company':
        return [
          (title: 'Entregas', icon: Icons.local_shipping, searchKeyword: 'entrega'),
          (title: 'Pagos', icon: Icons.payments, searchKeyword: 'pago'),
          (title: 'Configuración', icon: Icons.settings, searchKeyword: 'soporte'),
          (title: 'Soporte', icon: Icons.support, searchKeyword: 'soporte'),
        ];
      case 'admin':
        return [
          (title: 'Usuarios', icon: Icons.people, searchKeyword: 'usuario'),
          (title: 'Seguridad', icon: Icons.security, searchKeyword: 'seguridad'),
          (title: 'Analíticas', icon: Icons.bar_chart, searchKeyword: 'analítica'),
          (title: 'Soporte', icon: Icons.support_agent, searchKeyword: 'soporte'),
        ];
      default:
        return [
          (title: 'Mis Pedidos', icon: Icons.shopping_bag, searchKeyword: 'pedido'),
          (title: 'Pagos', icon: Icons.payments, searchKeyword: 'pago'),
          (title: 'Mi Cuenta', icon: Icons.person, searchKeyword: 'cuenta'),
          (title: 'Ayuda', icon: Icons.help, searchKeyword: ''),
        ];
    }
  }

  List<({String question, String answer})> _faqForRole(String role) {
    switch (role) {
      case 'users':
        return _faqUsers;
      case 'commerce':
        return _faqCommerce;
      case 'delivery':
      case 'delivery_agent':
        return _faqDelivery;
      case 'delivery_company':
        return _faqDeliveryCompany;
      case 'admin':
        return _faqAdmin;
      default:
        return _faqUsers;
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri.parse(
      'mailto:$_supportEmail?subject=${Uri.encodeComponent('Zonix Eats - Comentarios o soporte')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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
          const SnackBar(
            content: Text('No se pudo abrir $_supportUrl'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  static final List<({String question, String answer})> _faqUsers = [
    (question: '¿Cómo hago un pedido?', answer: 'Entra en Restaurantes o Productos, elige el restaurante y los platos. Añádelos al carrito (solo de un restaurante a la vez). En Checkout indica tu dirección y método de pago. Si pagas por transferencia o pago móvil, sube el comprobante. El comercio validará el pago y preparará tu pedido.'),
    (question: '¿Cómo cambio o agrego mi dirección de entrega?', answer: 'En Configuración (Mi perfil) → "Direcciones guardadas" puedes añadir o editar. La predeterminada se usa para buscar restaurantes; en cada pedido puedes elegir otra.'),
    (question: '¿Qué métodos de pago puedo usar?', answer: 'Cada restaurante define los suyos: efectivo, transferencia, tarjeta, pago móvil, etc. En el checkout verás las opciones. Para transferencia o pago móvil deberás subir el comprobante en el tiempo indicado.'),
    (question: '¿Cómo sigo mi pedido?', answer: 'En "Mis Órdenes" verás el estado: Pendiente de pago, Pagado, En preparación, Enviado, Entregado. Toca una orden para el detalle. Si hay repartidor, verás seguimiento en tiempo real.'),
    (question: '¿Cómo cancelo mi pedido en curso?', answer: 'Solo mientras esté en "Pendiente de pago". Después depende del comercio. Si tienes un problema, contacta soporte con el número de orden.'),
    (question: '¿Mi pedido llegó incompleto, qué hago?', answer: 'Contacta a soporte (correo o chat) e indica el número de orden y qué faltó. El equipo revisará con el comercio y te responderá.'),
    (question: '¿Cuánto tardan los reembolsos?', answer: 'Los reembolsos se gestionan de forma manual. Una vez aprobado, el tiempo depende del método de pago (transferencia suele ser 3-5 días hábiles). Consulta con soporte para tu caso.'),
    (question: '¿Cómo uso un cupón o promoción?', answer: 'En el checkout verás un campo para el código. Introdúcelo y aplica; se descontará si es válido. Las promociones del restaurante pueden aplicarse automáticamente.'),
    (question: '¿Cómo contacto a soporte?', answer: 'Correo a $_supportEmail o el enlace de soporte más abajo. Para un pedido, incluye el número de orden.'),
  ];

  static final List<({String question, String answer})> _faqCommerce = [
    (question: '¿Cómo gestiono las órdenes que me llegan?', answer: 'En el panel, pestaña "Órdenes", ves todas con filtros por estado. Toca una para ver detalle, aceptar o rechazar, y actualizar estado. Las notificaciones avisan de nuevos pedidos.'),
    (question: '¿Cómo acepto o rechazo un pedido?', answer: 'En el detalle de la orden: Aceptar o Rechazar (con razón). Luego actualiza a "En preparación" y cuando salga con el repartidor a "Enviado".'),
    (question: '¿Cómo doy de alta o edito mis productos?', answer: 'Panel → "Productos": ver catálogo, crear, editar, eliminar y activar/desactivar disponibilidad. El botón "+" crea un nuevo producto.'),
    (question: '¿Cómo creo promociones o cupones?', answer: 'Configuración (Más) → "Promociones y cupones", o desde el Dashboard "Promociones". Crea promos y códigos; los clientes los usan en el checkout.'),
    (question: '¿Dónde registro mis cuentas bancarias?', answer: 'Configuración (Más) → CONFIGURACIÓN DE NEGOCIO → "Métodos de pago". Añade cuentas bancarias y pago móvil para recibir las ventas.'),
    (question: '¿Cómo configuro horarios y abierto/cerrado?', answer: 'En el Dashboard está el interruptor "Comercio abierto/cerrado". En Configuración → "Horarios" defines días y horas de apertura.'),
    (question: '¿Qué son las zonas de delivery?', answer: 'Son las áreas donde ofreces envío. Configuración → "Zonas de delivery". La app usa esto para saber si un cliente puede pedirte.'),
    (question: '¿Cómo veo mis reportes e ingresos?', answer: 'Panel → "Reportes": resumen de ventas e ingresos por periodo (hoy, semana, mes). El Dashboard muestra pendientes, órdenes hoy e ingresos hoy.'),
    (question: '¿Cómo contacto a soporte?', answer: 'Correo a $_supportEmail o enlace de soporte. Para órdenes o pagos, incluye número de orden o referencia.'),
  ];

  static final List<({String question, String answer})> _faqDelivery = [
    (question: '¿Cómo recibo y acepto entregas?', answer: 'Panel → "Entregas": órdenes asignadas o disponibles. Entra al detalle, revisa dirección y acepta o rechaza con motivo.'),
    (question: '¿Qué hago si debo rechazar una entrega?', answer: 'En el detalle tienes Rechazar con razón. Si no estás disponible, pon tu estado como no disponible en vez de rechazar muchas seguidas.'),
    (question: '¿Cómo actualizo el estado de la entrega?', answer: 'En el detalle: marca en camino, recogida o entregado. Así el cliente y el comercio siguen el pedido en tiempo real.'),
    (question: '¿Cómo veo la ruta o dirección del cliente?', answer: 'En el detalle de la entrega ves dirección de entrega y del comercio. Puedes abrir en mapa o en tu app de navegación.'),
    (question: '¿Dónde veo mis ganancias?', answer: 'Panel → "Ganancias": lo que has ganado por entregas. Recibes el monto según las reglas de la plataforma.'),
    (question: '¿Qué es el estado Disponible / Trabajando?', answer: 'Indica si aceptas nuevas entregas. Con "Disponible" o "Trabajando" la app puede asignarte órdenes. Desactívalo si no estás disponible.'),
    (question: '¿Cómo contacto a soporte?', answer: 'Correo a $_supportEmail o enlace de soporte. Para una entrega, incluye el número de orden.'),
  ];

  static final List<({String question, String answer})> _faqDeliveryCompany = [
    (question: '¿Cómo gestiono las entregas de mi empresa?', answer: 'Tienes acceso al panel de entregas: órdenes de tus repartidores, estados y rutas. "Entregas" e "Historial" para operación.'),
    (question: '¿Dónde registro métodos de pago de la empresa?', answer: 'Configuración (Más) → PAGOS o CONFIGURACIÓN DE EMPRESA. Ahí configuras las cuentas donde la empresa recibe.'),
    (question: '¿Cómo contacto a soporte?', answer: 'Correo a $_supportEmail o enlace de soporte. Para facturación u operación, incluye nombre de tu empresa.'),
  ];

  static final List<({String question, String answer})> _faqAdmin = [
    (question: '¿Cómo gestiono usuarios?', answer: 'Panel admin → "Usuarios": buscar y gestionar cuentas (compradores, comercios, repartidores). Según permisos: ver datos, activar/desactivar, roles.'),
    (question: '¿Dónde está la configuración de seguridad?', answer: 'Panel admin → "Seguridad": opciones de seguridad, políticas de acceso y auditoría.'),
    (question: '¿Cómo veo las analíticas?', answer: 'Panel admin → "Sistema" o "Analíticas": vistas globales de órdenes, ingresos, comercios, repartidores y uso por periodo.'),
    (question: '¿Cómo doy soporte a comercios o usuarios?', answer: 'Revisa órdenes, disputas o reportes desde el panel. Los usuarios contactan por correo y página de soporte; tú tienes acceso a la información para resolver.'),
    (question: '¿Cómo contacto a soporte técnico?', answer: 'Correo a $_supportEmail o enlace de soporte. Indica que eres administrador y el tipo de consulta (técnica, facturación, etc.).'),
  ];
}
