import 'package:flutter/material.dart';
import '../models/phone.dart';
import '../api/phone_service.dart';
import '../screens/create_phone_screen.dart';
import '../screens/edit_phone_screen.dart';
import '../screens/phone_detail_screen.dart';
import 'package:zonix/features/utils/app_colors.dart';

class PhoneScreen extends StatefulWidget {
  final int userId;
  final bool statusId;

  const PhoneScreen({super.key, required this.userId, this.statusId = false});

  @override
  PhoneScreenState createState() => PhoneScreenState();
}

class PhoneScreenState extends State<PhoneScreen> {
  final PhoneService _phoneService = PhoneService();
  List<Phone> _phones = [];
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadPhones();
  }

  Future<void> _loadPhones() async {
    try {
      debugPrint('Loading phones for user: ${widget.userId}');
      final phones = await _phoneService.fetchPhones(widget.userId);
      debugPrint('Fetched ${phones.length} phones');

      if (mounted) {
        setState(() {
          _phones = phones;
          _loading = false;
        });
        debugPrint('State updated with ${_phones.length} phones');
      }
    } catch (e) {
      debugPrint('Error loading phones: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
        _showErrorSnackBar('Error al cargar teléfonos: $e');
      }
    }
  }

  Future<void> _refreshPhones() async {
    setState(() {
      _refreshing = true;
    });

    try {
      final phones = await _phoneService.fetchPhones(widget.userId);
      setState(() {
        _phones = phones;
        _refreshing = false;
      });
    } catch (e) {
      setState(() {
        _refreshing = false;
      });
      _showErrorSnackBar('Error al actualizar teléfonos: $e');
    }
  }

  Future<void> _updatePrimaryStatus(Phone phone, bool isPrimary) async {
    try {
      // Actualizar UI inmediatamente para mejor UX
      setState(() {
        if (isPrimary) {
          _phones = _phones.map((p) {
            return p.id == phone.id
                ? p.copyWith(isPrimary: true)
                : p.copyWith(isPrimary: false);
          }).toList();
        } else {
          _phones = _phones.map((p) {
            return p.id == phone.id ? p.copyWith(isPrimary: false) : p;
          }).toList();
        }
      });

      await _phoneService.updatePrimaryStatus(
          phone.id, isPrimary, widget.userId);
      _showSuccessSnackBar('Estado actualizado exitosamente');
    } catch (e) {
      // Revertir cambios si hay error
      _loadPhones();
      _showErrorSnackBar('Error al actualizar teléfono: $e');
    }
  }

  Future<void> _deletePhone(Phone phone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
            '¿Estás seguro de que quieres eliminar el teléfono ${phone.fullNumberDisplay}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _phoneService.deletePhone(phone.id);
        _showSuccessSnackBar('Teléfono eliminado exitosamente');
        _loadPhones();
      } catch (e) {
        _showErrorSnackBar('Error al eliminar teléfono: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBg = AppColors.cardBg(context);
    final borderColor = isDark ? AppColors.slateBorder : AppColors.stitchBorder;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Mis Teléfonos'),
        elevation: 0,
        backgroundColor: appBarBg,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
        actions: [
          if (_phones.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshing ? null : _refreshPhones,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando teléfonos...'),
                ],
              ),
            )
          : _phones.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refreshPhones,
                  child: _buildPhoneList(),
                ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildEmptyState() {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.phone_disabled,
              size: 60,
              color: primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay teléfonos registrados',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.secondaryText(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega al menos un teléfono para que te contactemos por tu pedido',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryText(context),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreatePhone(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Teléfono'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _phones.length,
      itemBuilder: (context, index) {
        final phone = _phones[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPhoneCard(phone),
        );
      },
    );
  }

  IconData _iconForPhone(Phone phone) {
    if (phone.isPrimary) return Icons.call;
    if (phone.context == 'commerce' || phone.context == 'delivery_company') return Icons.work;
    return Icons.home;
  }

  Widget _buildPhoneCard(Phone phone) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.cardBg(context);
    final borderColor = isDark ? AppColors.slateBorder : AppColors.stitchBorder;
    final verifiedBg = AppColors.green.withValues(alpha: isDark ? 0.25 : 0.15);
    const verifiedFg = AppColors.green;
    final pendingBg = AppColors.orange.withValues(alpha: isDark ? 0.25 : 0.15);
    const pendingFg = AppColors.orange;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      color: cardBg,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToPhoneDetail(phone),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconForPhone(phone), color: primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          phone.typeText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone.fullNumberDisplay,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: phone.status ? verifiedBg : pendingBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      phone.status ? 'VERIFICADO' : 'PENDIENTE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: phone.status ? verifiedFg : pendingFg,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, phone),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppColors.red),
                            SizedBox(width: 8),
                            Text('Eliminar',
                                style: TextStyle(color: AppColors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(
                  'Principal',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryText(context),
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                value: phone.isPrimary,
                onChanged: (value) => _updatePrimaryStatus(phone, value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    final primary = Theme.of(context).colorScheme.primary;
    return Stack(
      children: [
        Positioned(
          right: 24,
          bottom: 24,
          child: Material(
            color: primary,
            borderRadius: BorderRadius.circular(999),
            elevation: 4,
            shadowColor: primary.withValues(alpha: 0.3),
            child: InkWell(
              onTap: _navigateToCreatePhone,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: AppColors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Nuevo',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.statusId)
          Positioned(
            right: 24,
            bottom: 80,
            child: FloatingActionButton(
              heroTag: 'phone_list_confirm',
              onPressed: _handleStatusConfirmation,
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.white,
              child: const Icon(Icons.check),
            ),
          ),
      ],
    );
  }

  void _handleMenuAction(String action, Phone phone) {
    switch (action) {
      case 'edit':
        _navigateToEditPhone(phone);
        break;
      case 'delete':
        _deletePhone(phone);
        break;
    }
  }

  void _navigateToCreatePhone() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePhoneScreen(userId: widget.userId),
      ),
    );
    if (!context.mounted) return;
    debugPrint('Create phone result: $result');
    if (result == true) {
      debugPrint('Reloading phones after create...');
      await _loadPhones();
      debugPrint('Phones reloaded. Count: ${_phones.length}');
    }
  }

  void _navigateToEditPhone(Phone phone) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPhoneScreen(
          phone: phone,
          userId: widget.userId,
        ),
      ),
    );
    if (!context.mounted) return;
    debugPrint('Edit phone result: $result');
    if (result == true) {
      debugPrint('Reloading phones after edit...');
      await _loadPhones();
      debugPrint('Phones reloaded. Count: ${_phones.length}');
    }
  }

  void _navigateToPhoneDetail(Phone phone) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhoneDetailScreen(phone: phone, userId: widget.userId),
      ),
    );
    if (!context.mounted) return;
    debugPrint('Phone detail result: $result');
    if (result == true) {
      debugPrint('Reloading phones after delete from detail...');
      await _loadPhones();
      debugPrint('Phones reloaded. Count: ${_phones.length}');
    }
  }

  Future<void> _handleStatusConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar acción'),
        content: const Text('¿Quieres aprobar esta solicitud?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _phoneService.updateStatusCheckScanner(widget.userId);
        if (!context.mounted) return;
        final c = context;
        _showSuccessSnackBar('Estado actualizado exitosamente');
        Navigator.pop(c);
      } catch (e) {
        if (!context.mounted) return;
        _showErrorSnackBar('Error: $e');
      }
    }
  }
}
