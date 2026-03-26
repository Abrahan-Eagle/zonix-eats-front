import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/safe_parse.dart';
import '../../utils/responsive_helper.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _type = 'info';
  String _targetRole = 'all';
  bool _isSending = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  static const _types = <String, _TypeMeta>{
    'info':
        _TypeMeta('Información', Icons.info_outline_rounded, AppColors.blue),
    'warning':
        _TypeMeta('Advertencia', Icons.warning_amber_rounded, AppColors.orange),
    'error': _TypeMeta('Error', Icons.error_outline_rounded, AppColors.red),
    'success':
        _TypeMeta('Éxito', Icons.check_circle_outline_rounded, AppColors.green),
  };

  static const _targets = <String, String>{
    'all': 'Todos',
    'users': 'Compradores',
    'commerce': 'Comercios',
    'delivery': 'Delivery',
    'delivery_company': 'Empresas',
    'admin': 'Administradores',
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    try {
      final result = await context.read<AdminService>().sendSystemNotification({
        'title': _titleCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'type': _type,
        'target_role': _targetRole == 'all' ? null : _targetRole,
      });

      if (!mounted) return;
      final count = safeInt(
          result['recipients_count'] ?? result['data']?['recipients_count']);
      _snack(
        count > 0
            ? 'Notificación enviada a $count destinatarios'
            : 'Notificación enviada correctamente',
      );
      _titleCtrl.clear();
      _messageCtrl.clear();
      setState(() {
        _type = 'info';
        _targetRole = 'all';
      });
    } catch (e) {
      if (!mounted) return;
      _snack('Error: ${e.toString().replaceFirst("Exception: ", "")}',
          isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Enviar Notificación'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.headerGradientStart(context),
                AppColors.headerGradientMid(context),
              ],
            ),
          ),
        ),
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Form(
          key: _formKey,
          child: ResponsiveCenter(
            maxWidth: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _previewBanner(),
                const SizedBox(height: 24),
                _label('Título'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  onChanged: (_) => setState(() {}),
                  decoration: _inputDecoration(
                    hint: 'Ej: Mantenimiento programado',
                    icon: Icons.title_rounded,
                  ),
                ),
                const SizedBox(height: 20),
                _label('Mensaje'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _messageCtrl,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  onChanged: (_) => setState(() {}),
                  decoration: _inputDecoration(
                    hint: 'Escribe el contenido de la notificación…',
                    icon: Icons.message_rounded,
                  ),
                ),
                const SizedBox(height: 20),
                _label('Tipo'),
                const SizedBox(height: 6),
                _buildTypeSelector(),
                const SizedBox(height: 20),
                _label('Destinatarios'),
                const SizedBox(height: 6),
                _buildTargetDropdown(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _send,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white),
                          )
                        : const Icon(Icons.send_rounded),
                    label:
                        Text(_isSending ? 'Enviando…' : 'Enviar notificación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                _buildHistoryPlaceholder(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────── Preview banner ────────────────────────────

  Widget _previewBanner() {
    final meta = _types[_type]!;
    final title = _titleCtrl.text.trim();
    final message = _messageCtrl.text.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: meta.color.withAlpha(_isDark ? 25 : 18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: meta.color.withAlpha(50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(meta.icon, color: meta.color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Vista previa' : title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: title.isEmpty
                        ? AppColors.secondaryText(context)
                        : AppColors.primaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.isEmpty ? 'El mensaje aparecerá aquí…' : message,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText(context),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────── Type selector (chips) ─────────────────────

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _types.entries.map((entry) {
        final selected = _type == entry.key;
        final meta = entry.value;
        return ChoiceChip(
          avatar:
              Icon(meta.icon, size: 18, color: selected ? meta.color : null),
          label: Text(meta.label),
          selected: selected,
          selectedColor: meta.color.withAlpha(35),
          labelStyle: TextStyle(
            color: selected
                ? meta.color
                : (_isDark ? AppColors.white70 : AppColors.gray),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
          onSelected: (_) => setState(() => _type = entry.key),
        );
      }).toList(),
    );
  }

  // ────────────────────── Target dropdown ───────────────────────────

  Widget _buildTargetDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _targetRole,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.group_rounded),
        filled: true,
        fillColor: _isDark ? AppColors.grayDark : AppColors.grayLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: _targets.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _targetRole = v);
      },
    );
  }

  // ────────────────────── History placeholder ───────────────────────

  Widget _buildHistoryPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: _isDark ? Border.all(color: AppColors.white12) : null,
        boxShadow: [
          if (!_isDark)
            const BoxShadow(
              color: AppColors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded,
              size: 40, color: AppColors.secondaryText(context)),
          const SizedBox(height: 10),
          Text(
            'Historial de notificaciones',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'El historial de notificaciones enviadas se implementará en una próxima versión.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────── Helpers ───────────────────────────────────

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.primaryText(context),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: _isDark ? AppColors.grayDark : AppColors.grayLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _TypeMeta {
  final String label;
  final IconData icon;
  final Color color;
  const _TypeMeta(this.label, this.icon, this.color);
}
