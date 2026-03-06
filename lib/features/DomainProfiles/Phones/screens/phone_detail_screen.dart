import 'package:flutter/material.dart';
import '../models/phone.dart';
import '../api/phone_service.dart';
import 'edit_phone_screen.dart';
import 'package:zonix/features/utils/app_colors.dart';

class PhoneDetailScreen extends StatefulWidget {
  final Phone phone;

  const PhoneDetailScreen({super.key, required this.phone});

  @override
  PhoneDetailScreenState createState() => PhoneDetailScreenState();
}

class PhoneDetailScreenState extends State<PhoneDetailScreen> {
  final PhoneService _phoneService = PhoneService();
  bool _isLoading = false;

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

  Future<void> _deletePhone() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
            '¿Estás seguro de que quieres eliminar el teléfono ${widget.phone.fullNumber}?'),
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
      setState(() {
        _isLoading = true;
      });

      try {
        await _phoneService.deletePhone(widget.phone.id);
        if (!context.mounted) return;
        final c = context;
        _showSuccessSnackBar('Teléfono eliminado exitosamente');
        Navigator.pop(c, true); // Regresar con resultado de éxito
      } catch (e) {
        if (!context.mounted) return;
        _showErrorSnackBar('Error al eliminar teléfono: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Detalle del Teléfono'),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con información principal
                  _buildMainInfoCard(),
                  const SizedBox(height: 20),

                  // Información detallada
                  _buildDetailInfoCard(),
                  const SizedBox(height: 20),

                  // Botones de acción
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildMainInfoCard() {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: primary,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: AppColors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Número de Teléfono',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.phone.fullNumber,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatusChip(
                  widget.phone.typeText,
                  Color(widget.phone.typeColor),
                ),
                const SizedBox(width: 12),
                _buildStatusChip(
                  widget.phone.statusText,
                  Color(widget.phone.statusColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Detallada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText(context),
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailItem(
                'Código de Operador', widget.phone.operatorCodeName),
            _buildDetailItem('Número', widget.phone.number),
            _buildDetailItem('Tipo', widget.phone.typeText),
            _buildDetailItem('Estado', widget.phone.statusText),
            _buildDetailItem('Creado', widget.phone.formattedCreatedAt),
            if (widget.phone.updatedAt != null)
              _buildDetailItem('Actualizado', widget.phone.formattedUpdatedAt),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryText(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _navigateToEdit(),
            icon: const Icon(Icons.edit),
            label: const Text('Editar Teléfono'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _deletePhone,
            icon: const Icon(Icons.delete),
            label: const Text('Eliminar Teléfono'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPhoneScreen(
          phone: widget.phone,
          userId: widget.phone.profileId,
        ),
      ),
    );

    if (result == true) {
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }
}
