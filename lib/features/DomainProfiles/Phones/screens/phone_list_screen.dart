import 'package:flutter/material.dart';
import '../models/phone.dart';
import '../api/phone_service.dart';
import '../screens/create_phone_screen.dart';
import '../screens/edit_phone_screen.dart';
import '../screens/phone_detail_screen.dart';

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
            return p.id == phone.id 
                ? p.copyWith(isPrimary: false) 
                : p;
          }).toList();
        }
      });

      await _phoneService.updatePrimaryStatus(phone.id, isPrimary, widget.userId);
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
        content: Text('¿Estás seguro de que quieres eliminar el teléfono ${phone.fullNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Teléfonos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.phone_disabled,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay teléfonos registrados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer número de teléfono',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreatePhone(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Teléfono'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
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
        return _buildPhoneCard(phone);
      },
    );
  }

  Widget _buildPhoneCard(Phone phone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToPhoneDetail(phone),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.phone,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phone.fullNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusChip(
                              phone.typeText,
                              Color(phone.typeColor),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusChip(
                              phone.statusText,
                              Color(phone.statusColor),
                            ),
                          ],
                        ),
                      ],
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
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Principal'),
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

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Stack(
      children: [
        // Botón de agregar teléfono
        Positioned(
          right: 10,
          bottom: 20,
          child: FloatingActionButton(
            onPressed: _navigateToCreatePhone,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ),
        // Botón de confirmación solo si statusId es true
        if (widget.statusId)
          Positioned(
            right: 10,
            bottom: 85,
            child: FloatingActionButton(
              onPressed: _handleStatusConfirmation,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
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
        builder: (context) => PhoneDetailScreen(phone: phone),
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
