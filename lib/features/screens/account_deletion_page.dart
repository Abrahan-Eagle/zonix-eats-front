import 'package:flutter/material.dart';
import '../services/account_deletion_service.dart';
import '../../helpers/auth_helper.dart';
import 'package:zonix/features/utils/app_colors.dart';

class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({Key? key}) : super(key: key);

  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  Map<String, dynamic> deletionStatus = {};
  bool isLoading = true;
  bool isRequestingDeletion = false;
  bool isConfirmingDeletion = false;
  bool isCancellingDeletion = false;

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _confirmationCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? selectedReason;
  bool immediateDeletion = false;

  final List<String> deletionReasons = [
    'Ya no uso la aplicación',
    'Problemas con el servicio',
    'Preocupaciones de privacidad',
    'Creé una nueva cuenta',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _loadDeletionStatus();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _feedbackController.dispose();
    _confirmationCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadDeletionStatus() async {
    try {
      setState(() {
        isLoading = true;
      });

      final status = await AccountDeletionService.getDeletionStatus();
      setState(() {
        deletionStatus = status;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Error al cargar estado: $e');
    }
  }

  Future<void> _requestAccountDeletion() async {
    if (selectedReason == null) {
      _showErrorSnackBar('Selecciona una razón para la eliminación');
      return;
    }

    try {
      setState(() {
        isRequestingDeletion = true;
      });

      final result = await AccountDeletionService.requestAccountDeletion(
        reason: selectedReason,
        feedback: _feedbackController.text.isNotEmpty ? _feedbackController.text : null,
        immediate: immediateDeletion,
      );

      _showSuccessSnackBar('Solicitud de eliminación enviada');
      _loadDeletionStatus(); // Recargar estado
    } catch (e) {
      _showErrorSnackBar('Error al solicitar eliminación: $e');
    } finally {
      setState(() {
        isRequestingDeletion = false;
      });
    }
  }

  Future<void> _confirmAccountDeletion() async {
    if (_confirmationCodeController.text.isEmpty) {
      _showErrorSnackBar('Ingresa el código de confirmación');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showErrorSnackBar('Ingresa tu contraseña');
      return;
    }

    try {
      setState(() {
        isConfirmingDeletion = true;
      });

      final result = await AccountDeletionService.confirmAccountDeletion(
        confirmationCode: _confirmationCodeController.text,
        password: _passwordController.text,
      );

      _showSuccessSnackBar('Cuenta eliminada correctamente');
      // Aquí podrías navegar a la pantalla de login
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _showErrorSnackBar('Error al confirmar eliminación: $e');
    } finally {
      setState(() {
        isConfirmingDeletion = false;
      });
    }
  }

  Future<void> _cancelDeletionRequest() async {
    try {
      setState(() {
        isCancellingDeletion = true;
      });

      final result = await AccountDeletionService.cancelDeletionRequest();
      _showSuccessSnackBar('Solicitud de eliminación cancelada');
      _loadDeletionStatus(); // Recargar estado
    } catch (e) {
      _showErrorSnackBar('Error al cancelar eliminación: $e');
    } finally {
      setState(() {
        isCancellingDeletion = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.headerGradientStart(context),
                AppColors.headerGradientMid(context),
                AppColors.headerGradientEnd(context),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Eliminar Cuenta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)), // TODO: internacionalizar
            iconTheme: IconThemeData(color: AppColors.white),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: AppColors.red.withValues(alpha: 0.08),
                    shadowColor: AppColors.red.withValues(alpha: 0.15),
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: AppColors.red),
                              const SizedBox(width: 8),
                              const Text(
                                'Advertencia importante', // TODO: internacionalizar
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'La eliminación de tu cuenta es permanente e irreversible. Todos tus datos, pedidos, reseñas y configuraciones serán eliminados definitivamente.', // TODO: internacionalizar
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (deletionStatus.isNotEmpty) ...[
                    _buildDeletionStatusCard(),
                    const SizedBox(height: 16),
                  ],
                  if (deletionStatus['has_pending_request'] != true) ...[
                    _buildDeletionRequestForm(),
                  ] else ...[
                    _buildPendingRequestCard(),
                  ],
                  const SizedBox(height: 24),
                  Card(
                    color: AppColors.cardBg(context),
                    shadowColor: AppColors.red.withValues(alpha: 0.10),
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¿Qué se elimina?', // TODO: internacionalizar
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('• Tu perfil y información personal'),
                          const Text('• Historial completo de pedidos'),
                          const Text('• Reseñas y calificaciones'),
                          const Text('• Direcciones guardadas'),
                          const Text('• Configuraciones de la app'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDeletionStatusCard() {
    final status = deletionStatus['status'] ?? '';
    final requestedAt = deletionStatus['requested_at'];
    final scheduledFor = deletionStatus['scheduled_for'];

    return Card(
      color: AppColors.orange.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: AppColors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Estado de eliminación',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Estado: $status'),
            if (requestedAt != null)
              Text('Solicitado: ${_formatDate(DateTime.parse(requestedAt))}'),
            if (scheduledFor != null)
              Text('Programado para: ${_formatDate(DateTime.parse(scheduledFor))}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletionRequestForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solicitar eliminación de cuenta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Razón de eliminación
            DropdownButtonFormField<String>(
              value: selectedReason,
              decoration: const InputDecoration(
                labelText: 'Razón de eliminación *',
                border: OutlineInputBorder(),
              ),
              items: deletionReasons.map((reason) => DropdownMenuItem(
                value: reason,
                child: Text(reason),
              )).toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedReason = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Feedback opcional
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Comentarios (opcional)',
                border: OutlineInputBorder(),
                hintText: 'Cuéntanos cómo podemos mejorar...',
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Eliminación inmediata
            SwitchListTile(
              title: const Text('Eliminación inmediata'),
              subtitle: const Text('Eliminar la cuenta de inmediato (no recomendado)'),
              value: immediateDeletion,
              onChanged: (bool value) {
                setState(() {
                  immediateDeletion = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Botón de solicitar eliminación
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isRequestingDeletion ? null : _requestAccountDeletion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isRequestingDeletion
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Solicitar Eliminación',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestCard() {
    return Card(
      color: AppColors.orange.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solicitud pendiente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tienes una solicitud de eliminación pendiente. '
              'Puedes cancelarla o confirmarla.',
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isCancellingDeletion ? null : _cancelDeletionRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: isCancellingDeletion
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showConfirmationDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Para confirmar la eliminación, ingresa el código de confirmación '
              'que se envió a tu email y tu contraseña actual.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmationCodeController,
              decoration: const InputDecoration(
                labelText: 'Código de confirmación',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: isConfirmingDeletion ? null : () {
              Navigator.of(context).pop();
              _confirmAccountDeletion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            child: isConfirmingDeletion
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 