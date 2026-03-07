import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/commerce/commerce_payment_method_form_page.dart';
import 'package:zonix/features/screens/commerce/payment_method_detail_page.dart';
import 'package:zonix/features/services/payment_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommercePaymentMethodsPage extends StatefulWidget {
  const CommercePaymentMethodsPage({super.key});

  @override
  State<CommercePaymentMethodsPage> createState() =>
      _CommercePaymentMethodsPageState();
}

class _CommercePaymentMethodsPageState
    extends State<CommercePaymentMethodsPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _methods = [];

  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final paymentService =
          Provider.of<PaymentService>(context, listen: false);
      final list = await paymentService.getPaymentMethods();
      if (mounted) {
        setState(() {
          _methods = list.cast<Map<String, dynamic>>();
          _methods.sort((a, b) {
            final aDefault = a['is_default'] == true ? 1 : 0;
            final bDefault = b['is_default'] == true ? 1 : 0;
            return bDefault.compareTo(aDefault);
          });
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'mobile_payment':
        return 'Pago móvil';
      case 'bank_transfer':
        return 'Transferencia bancaria';
      case 'cash':
        return 'Efectivo';
      case 'digital_wallet':
        return 'Billetera digital';
      case 'card':
        return 'Tarjeta';
      case 'paypal':
        return 'PayPal';
      default:
        return 'Otro';
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'mobile_payment':
        return Icons.smartphone;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'cash':
        return Icons.attach_money;
      case 'digital_wallet':
      case 'paypal':
        return Icons.account_balance_wallet;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.account_balance_wallet;
    }
  }

  String _subtitle(Map<String, dynamic> m, String type, [Map<String, dynamic>? refMap]) {
    final ref = refMap ?? (m['reference_info'] is Map ? Map<String, dynamic>.from(m['reference_info']) : <String, dynamic>{});
    if (type == 'mobile_payment' && m['phone'] != null) {
      return 'Pago móvil · ${m['phone']}';
    }
    if (type == 'bank_transfer' && m['account_number'] != null) {
      final acc = m['account_number'].toString();
      if (acc.length > 4) {
        return 'Transferencia · •••• ${acc.substring(acc.length - 4)}';
      }
      return 'Transferencia · $acc';
    }
    if (type == 'card') {
      final last4 = ref['last4'] ?? m['last4'];
      final exp = ref['exp'] ?? m['exp'];
      if (last4 != null) return 'Expira ${exp ?? ""}'.trim();
      return 'Tarjeta';
    }
    if (type == 'digital_wallet' || type == 'paypal') {
      return ref['email']?.toString() ?? _typeLabel(type);
    }
    return _typeLabel(type);
  }

  Future<void> _deactivate(Map<String, dynamic> method) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar método'),
        content: const Text(
          '¿Desactivar este método de pago? Podrás reactivarlo editándolo después.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desactivar', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    try {
      final paymentService =
          Provider.of<PaymentService>(context, listen: false);
      await paymentService.deletePaymentMethod(method['id'] as int);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Método eliminado'),
            backgroundColor: AppColors.gray,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  void _openDetail(Map<String, dynamic> m) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodDetailPage(method: m),
      ),
    );
    if (result == true && mounted) _loadData();
  }

  void _openForm([Map<String, dynamic>? method]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CommercePaymentMethodFormPage(method: method),
      ),
    );
    if (result == true && mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isDark ? AppColors.backgroundDark : AppColors.scaffoldBgLight;
    final cardBg = AppColors.cardBg(context);
    final primaryText = AppColors.primaryText(context);
    final secondaryText = AppColors.secondaryText(context);
    final borderColor = _isDark ? AppColors.stitchSurfaceLighter : AppColors.stitchBorder;

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.red),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: primaryText)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadData,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(context),
      body: _methods.isEmpty
          ? _buildEmptyState(secondaryText)
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.blue,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final m = _methods[index];
                          final type = (m['type'] ?? '') as String;
                          final ref = (m['reference_info'] is Map)
                              ? Map<String, dynamic>.from(m['reference_info'])
                              : <String, dynamic>{};
                          final effectiveType = (type == 'other' && ref['display_type'] == 'digital_wallet')
                              ? 'digital_wallet'
                              : type;
                          final alias = (ref['alias'] ?? m['owner_name'] ?? _typeLabel(effectiveType)).toString();
                          final isActive = m['is_active'] != false;
                          final subtitle = _subtitle(m, effectiveType, ref);

                          final cardBorder = _isDark ? borderColor : const Color(0xFFE2E8F0);
                          final iconBg = _isDark
                              ? AppColors.blue.withValues(alpha: 0.25)
                              : const Color(0xFFEFF6FF); // blue-50
                          final iconColor = isActive
                              ? (_isDark ? const Color(0xFF60A5FA) : AppColors.blue)
                              : AppColors.gray;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Material(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              clipBehavior: Clip.antiAlias,
                              elevation: 0,
                              child: InkWell(
                                onTap: () => _openDetail(m),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: cardBorder, width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: iconBg,
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: Icon(
                                          _typeIcon(effectiveType),
                                          color: iconColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              alias,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                height: 1.25,
                                                color: primaryText,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              subtitle,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.normal,
                                                color: secondaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit_outlined, size: 22, color: secondaryText),
                                            onPressed: () => _openDetail(m),
                                            style: IconButton.styleFrom(
                                              foregroundColor: AppColors.orange,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline, size: 22, color: secondaryText),
                                            onPressed: () => _deactivate(m),
                                            style: IconButton.styleFrom(
                                              foregroundColor: AppColors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _methods.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isDark ? AppColors.grayDark.withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isDark ? borderColor : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lock_outline, size: 20, color: secondaryText),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tus datos de pago se almacenan de forma segura cumpliendo con los estándares PCI DSS.',
                                style: TextStyle(fontSize: 12, color: secondaryText, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _openForm(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                        ),
                        child: const Text('+ Agregar nuevo método', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Métodos de pago'),
      backgroundColor: AppColors.stitchNavBg,
      foregroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    );
  }

  Widget _buildEmptyState(Color secondaryText) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay métodos de pago configurados',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: secondaryText),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 20, color: secondaryText),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tus datos de pago se almacenan de forma segura cumpliendo con los estándares PCI DSS.',
                  style: TextStyle(fontSize: 12, color: secondaryText, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _openForm(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: const Text('+ Agregar nuevo método', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
