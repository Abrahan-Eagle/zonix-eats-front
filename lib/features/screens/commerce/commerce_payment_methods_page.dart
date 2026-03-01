import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/commerce/commerce_payment_method_form_page.dart';
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

          // Ordenar: primero el método predeterminado, luego el resto
          _methods.sort((a, b) {
            final aDefault = a['is_default'] == true ? 1 : 0;
            final bDefault = b['is_default'] == true ? 1 : 0;
            // Queremos que los predeterminados (1) queden antes que los no predeterminados (0)
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
        return Icons.account_balance_wallet;
      case 'paypal':
        return Icons.payment;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Future<void> _setDefault(Map<String, dynamic> method) async {
    try {
      final paymentService =
          Provider.of<PaymentService>(context, listen: false);
      final id = method['id'] as int;
      await paymentService.setDefaultPaymentMethod(id);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _deactivate(Map<String, dynamic> method) async {
    try {
      final paymentService =
          Provider.of<PaymentService>(context, listen: false);
      final id = method['id'] as int;
      await paymentService.deletePaymentMethod(id);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Métodos de pago')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.red),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Métodos de pago')),
      body: _methods.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay métodos de pago configurados'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _methods.length,
                itemBuilder: (context, index) {
                  final m = _methods[index];
                  final type = (m['type'] ?? '') as String;
                  final ref = (m['reference_info'] is Map)
                      ? Map<String, dynamic>.from(m['reference_info'])
                      : <String, dynamic>{};
                  final alias =
                      (ref['alias'] ?? m['owner_name'] ?? _typeLabel(type))
                          .toString();
                  final isDefault = m['is_default'] == true;
                  final isActive = m['is_active'] != false;
                  final subtitle = () {
                    if (type == 'mobile_payment' && m['phone'] != null) {
                      return 'Pago móvil · ${m['phone']}';
                    }
                    if (type == 'bank_transfer' && m['account_number'] != null) {
                      return 'Transferencia · ${m['account_number']}';
                    }
                    return _typeLabel(type);
                  }();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        _typeIcon(type),
                        color: isActive ? AppColors.blue : AppColors.gray,
                      ),
                      title: Text(alias),
                      subtitle: Text(subtitle),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CommercePaymentMethodFormPage(method: m),
                              ),
                            );
                            if (result == true) _loadData();
                          } else if (value == 'default') {
                            await _setDefault(m);
                          } else if (value == 'deactivate') {
                            await _deactivate(m);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar'),
                          ),
                          if (!isDefault && isActive)
                            const PopupMenuItem(
                              value: 'default',
                              child: Text('Marcar como predeterminado'),
                            ),
                          if (isActive)
                            const PopupMenuItem(
                              value: 'deactivate',
                              child: Text('Desactivar'),
                            ),
                        ],
                      ),
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CommercePaymentMethodFormPage(method: m),
                          ),
                        );
                        if (result == true) _loadData();
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const CommercePaymentMethodFormPage(),
            ),
          );
          if (result == true) _loadData();
        },
        backgroundColor: AppColors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}

