import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/commerce/commerce_payment_method_form_page.dart';
import 'package:zonix/features/services/payment_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/rif_formatter.dart';

/// Pantalla de detalle de un método de pago. Muestra una vista distinta según el tipo
/// (tarjeta, pago móvil, billetera, transferencia, otro). Efectivo no se configura aquí.
class PaymentMethodDetailPage extends StatelessWidget {
  const PaymentMethodDetailPage({
    super.key,
    required this.method,
  });

  final Map<String, dynamic> method;

  /// Tipo para mostrar: si backend guardó 'other' con display_type 'digital_wallet', tratamos como billetera.
  String get _type {
    final t = (method['type'] ?? 'other') as String;
    if (t == 'other') {
      final ref = (method['reference_info'] is Map)
          ? Map<String, dynamic>.from(method['reference_info'])
          : <String, dynamic>{};
      if (ref['display_type'] == 'digital_wallet') return 'digital_wallet';
    }
    return t;
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  String _formatOwnerIdDisplay(String value) {
    if (value == '—' || value.isEmpty) return value;
    return formatRifDisplay(value) ?? value;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final bg = isDark ? AppColors.backgroundDark : AppColors.scaffoldBgLight;
    final primaryText = AppColors.primaryText(context);
    final cardBg = AppColors.cardBg(context);
    final secondaryText = AppColors.secondaryText(context);
    final borderColor = isDark ? AppColors.stitchSurfaceLighter : AppColors.stitchBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(_appBarTitle(), style: const TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.stitchNavBg,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.white),
            onPressed: () => _openEdit(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_type == 'card') _buildCardDetail(context, cardBg, primaryText, secondaryText, borderColor, isDark),
            if (_type == 'mobile_payment') _buildMobileDetail(context, cardBg, primaryText, secondaryText, borderColor),
            if (_type == 'bank_transfer') _buildTransferDetail(context, cardBg, primaryText, secondaryText, borderColor, isDark),
            if (_type == 'digital_wallet' || _type == 'paypal') _buildWalletDetail(context, cardBg, primaryText, secondaryText, borderColor, isDark),
            if (_type == 'cash' || _type == 'other') _buildGenericDetail(context, cardBg, primaryText, secondaryText, borderColor),
            const SizedBox(height: 24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  String _appBarTitle() {
    switch (_type) {
      case 'card':
        return 'Detalle Tarjeta';
      case 'mobile_payment':
        return 'Detalle Pago Móvil';
      case 'bank_transfer':
        return 'Detalle Transferencia';
      case 'digital_wallet':
      case 'paypal':
        return 'Detalle Billetera';
      default:
        return 'Detalle método';
    }
  }

  Widget _buildCardDetail(
    BuildContext context,
    Color cardBg,
    Color primaryText,
    Color secondaryText,
    Color borderColor,
    bool isDark,
  ) {
    final ref = (method['reference_info'] is Map)
        ? Map<String, dynamic>.from(method['reference_info'])
        : <String, dynamic>{};
    final last4 = ref['last4'] ?? method['last4'] ?? '****';
    final exp = ref['exp'] ?? method['exp'] ?? '--/--';
    final holder = method['owner_name'] ?? ref['holder'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.blueDark, Color(0xFF23456b), AppColors.blue],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Text(
                    'VISA',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '•••• •••• •••• $last4',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TITULAR',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        holder.toString().toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'EXPIRA',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        exp.toString(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _infoCard(
          context,
          cardBg,
          primaryText,
          secondaryText,
          borderColor,
          [
            _InfoRow('Nombre del titular', holder.toString(), Icons.person, 'Como aparece en el plástico'),
            _InfoRow('Vencimiento', exp.toString(), Icons.calendar_today, 'Fecha de expiración'),
            _InfoRow('Estado', method['is_active'] != false ? 'Activa' : 'Inactiva', Icons.verified_user, 'Condición de la tarjeta'),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileDetail(
    BuildContext context,
    Color cardBg,
    Color primaryText,
    Color secondaryText,
    Color borderColor,
  ) {
    final ref = (method['reference_info'] is Map)
        ? Map<String, dynamic>.from(method['reference_info'])
        : <String, dynamic>{};
    final alias = ref['alias'] ?? method['owner_name'] ?? 'Pago Móvil';
    const double heroHeight = 128;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            color: cardBg,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(
                height: heroHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [AppColors.blueDark, AppColors.blue],
                        ),
                      ),
                    ),
                    Positioned(
                      top: -24,
                      right: -24,
                      child: Icon(
                        Icons.contactless,
                        size: 160,
                        color: AppColors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.contactless, color: AppColors.white, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pago Móvil Guardado',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Este método de pago está listo para ser usado en tus próximos pedidos.',
                      style: TextStyle(fontSize: 14, color: secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _detailCardWithDivide(
          context,
          cardBg,
          primaryText,
          secondaryText,
          borderColor,
          [
            _InfoRow('Banco', (ref['bank'] ?? method['bank'] ?? '—').toString(), Icons.account_balance, ''),
            _InfoRow('Número de Teléfono', (method['phone'] ?? '—').toString(), Icons.smartphone, ''),
            _InfoRow('Documento (RIF/CI)', _formatOwnerIdDisplay((method['owner_id'] ?? '—').toString()), Icons.badge, ''),
            _InfoRow('Alias del método', alias.toString(), Icons.label, ''),
          ],
        ),
        const SizedBox(height: 16),
        _securityBadge(primaryText, secondaryText, cardBg, borderColor),
      ],
    );
  }

  /// Card con filas separadas por borde inferior (estilo divide-y del HTML).
  Widget _detailCardWithDivide(
    BuildContext context,
    Color cardBg,
    Color primaryText,
    Color secondaryText,
    Color borderColor,
    List<_InfoRow> rows,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? AppColors.grayDark.withValues(alpha: 0.5) : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Text(
              'Datos del método',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: secondaryText,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: isLast ? null : Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(e.value.icon, color: AppColors.blue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.value.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: secondaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value.value,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryText),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 20, color: secondaryText),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransferDetail(
    BuildContext context,
    Color cardBg,
    Color primaryText,
    Color secondaryText,
    Color borderColor,
    bool isDark,
  ) {
    final ref = (method['reference_info'] is Map)
        ? Map<String, dynamic>.from(method['reference_info'])
        : <String, dynamic>{};
    final account = method['account_number'] ?? ref['account_number'] ?? '—';
    final bank = ref['bank'] ?? 'Banco';
    final holder = method['owner_name'] ?? ref['holder'] ?? '—';
    final rif = method['owner_id'] ?? ref['owner_id'] ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            color: cardBg,
          ),
                child: Column(
                  children: [
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.blueDark : AppColors.stitchSlate.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                      ),
                      child: const Icon(Icons.account_balance, color: AppColors.blueDark, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bank.toString(),
                            style: TextStyle(
                              color: isDark ? AppColors.white : AppColors.blueDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Cuenta Principal',
                            style: TextStyle(
                              color: isDark ? AppColors.white70 : AppColors.gray,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('Número de Cuenta', account.toString(), primaryText, secondaryText),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _detailCol('Titular', holder.toString(), primaryText, secondaryText)),
                        Expanded(child: _detailCol('RIF / Cédula', _formatOwnerIdDisplay(rif.toString()), primaryText, secondaryText)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _infoCard(
          context,
          cardBg,
          primaryText,
          secondaryText,
          borderColor,
          [
            _InfoRow('Fecha de Registro', _formatDate(method['created_at']), Icons.calendar_today, ''),
            _InfoRow('Estado', 'Verificada', Icons.verified, ''),
          ],
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value, Color primary, Color secondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: secondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: primary)),
      ],
    );
  }

  Widget _detailCol(String label, String value, Color primary, Color secondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: secondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, color: primary)),
      ],
    );
  }

  Widget _buildWalletDetail(
    BuildContext context,
    Color cardBg,
    Color primaryText,
    Color secondaryText,
    Color borderColor,
    bool isDark,
  ) {
    final ref = (method['reference_info'] is Map)
        ? Map<String, dynamic>.from(method['reference_info'])
        : <String, dynamic>{};
    final alias = ref['alias'] ?? 'Billetera';
    final platform = ref['platform'] ?? 'PayPal';
    final email = ref['email'] ?? method['email'] ?? '—';
    final holder = method['owner_name'] ?? ref['holder'] ?? '—';
    final isDefault = method['is_default'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            color: cardBg,
          ),
          child: Column(
            children: [
              Container(
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.blueDark, AppColors.blue],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: isDefault
                    ? Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.yellow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'PREDETERMINADA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blueDark,
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: AppColors.blue, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Plataforma Digital',
                          style: TextStyle(fontSize: 12, color: secondaryText, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      platform.toString(),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: primaryText),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(email.toString(), style: TextStyle(fontWeight: FontWeight.w600, color: primaryText), overflow: TextOverflow.ellipsis),
                              Text(holder.toString(), style: TextStyle(fontSize: 14, color: secondaryText), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 14, color: AppColors.green),
                              SizedBox(width: 4),
                              Text('Verificada', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.green)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _infoCard(
          context,
          cardBg,
          primaryText,
          secondaryText,
          borderColor,
          [
            _InfoRow('Proveedor', '$platform', Icons.business, ''),
            _InfoRow('Alias', alias.toString(), Icons.label, ''),
            _InfoRow('Estado', method['is_active'] != false ? 'Activo' : 'Inactivo', Icons.info_outline, ''),
          ],
        ),
      ],
    );
  }

  Widget _buildGenericDetail(
    BuildContext context,
    Color cardBg,
    Color primaryText,
    Color secondaryText,
    Color borderColor,
  ) {
    final ref = (method['reference_info'] is Map)
        ? Map<String, dynamic>.from(method['reference_info'])
        : <String, dynamic>{};
    final alias = ref['alias'] ?? method['owner_name'] ?? 'Método de pago';
    final typeLabel = _type == 'cash' ? 'Efectivo' : 'Otro';

    return _infoCard(
      context,
      cardBg,
      primaryText,
      secondaryText,
      borderColor,
      [
        _InfoRow('Alias', alias.toString(), Icons.label, ''),
        _InfoRow('Tipo', typeLabel, Icons.category, ''),
        _InfoRow('Estado', method['is_active'] != false ? 'Activo' : 'Inactivo', Icons.toggle_on, ''),
      ],
    );
  }

  Widget _infoCard(
    BuildContext context,
    Color cardBg,
    Color primaryText,
    Color secondaryText,
    Color borderColor,
    List<_InfoRow> rows,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.grayDark.withValues(alpha: 0.5)
                : AppColors.stitchBgCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Text(
              'Información',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: secondaryText,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...rows.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(e.value.icon, color: AppColors.blue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.value.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryText), overflow: TextOverflow.ellipsis),
                        if (e.value.subtitle.isNotEmpty)
                          Text(e.value.subtitle, style: TextStyle(fontSize: 12, color: secondaryText), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(e.value.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryText), overflow: TextOverflow.ellipsis, textAlign: TextAlign.end),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _securityBadge(Color primaryText, Color secondaryText, Color cardBg, Color borderColor) {
    const Color green100 = Color(0xFFDCFCE7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: green100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_user, color: AppColors.green, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seguridad Garantizada', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryText)),
                const SizedBox(height: 4),
                Text(
                  'Tus datos están protegidos con cifrado de grado bancario. Zonix Eats nunca almacena claves de acceso.',
                  style: TextStyle(fontSize: 12, color: secondaryText, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.stitchSurfaceLighter
        : AppColors.stitchBorder;
    final isDefault = method['is_default'] == true;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          if (!isDefault) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _setAsDefault(context),
                icon: const Icon(Icons.star_border, size: 20),
                label: const Text('Establecer como predeterminado'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.blue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () => _openEdit(context),
              icon: const Icon(Icons.edit_outlined, size: 22),
              label: const Text('Editar información'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton.icon(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.red),
              label: const Text('Eliminar este método', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600, fontSize: 15)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setAsDefault(BuildContext context) async {
    try {
      await Provider.of<PaymentService>(context, listen: false)
          .setDefaultPaymentMethod(method['id'] as int);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Método establecido como predeterminado'), backgroundColor: AppColors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _openEdit(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CommercePaymentMethodFormPage(method: method),
      ),
    );
    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar método'),
        content: const Text(
          '¿Eliminar este método de pago? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!context.mounted) return;
    try {
      await Provider.of<PaymentService>(context, listen: false).deletePaymentMethod(method['id'] as int);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Método eliminado'), backgroundColor: AppColors.gray),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  String _formatDate(dynamic v) {
    if (v == null) return '—';
    if (v is String) {
      try {
        final d = DateTime.parse(v);
        return '${d.day} ${_month(d.month)} ${d.year}';
      } catch (_) {}
      return v;
    }
    return '—';
  }

  String _month(int m) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[m - 1];
  }
}

class _InfoRow {
  final String label;
  final String value;
  final IconData icon;
  final String subtitle;

  _InfoRow(this.label, this.value, this.icon, [this.subtitle = '']);
}
