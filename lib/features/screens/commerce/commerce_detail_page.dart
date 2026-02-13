import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zonix/models/my_commerce.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/screens/settings/commerce_data_page.dart';
import 'package:zonix/features/services/commerce_list_service.dart';

/// Detalle de restaurante estilo CorralX: datos, descripción, ubicación, estadísticas.
class CommerceDetailPage extends StatelessWidget {
  final MyCommerce commerce;

  const CommerceDetailPage({super.key, required this.commerce});

  @override
  Widget build(BuildContext context) {
    final c = commerce;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.businessName),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _openEdit(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(c),
            const SizedBox(height: 24),
            _buildSection(
              'Datos del comercio',
              [
                _InfoRow(label: 'Nombre', value: c.businessName),
                if (c.taxId != null && c.taxId!.isNotEmpty)
                  _InfoRow(label: 'RIF / NIT', value: c.taxId!),
                if (c.businessType != null && c.businessType!.isNotEmpty)
                  _InfoRow(label: 'Tipo', value: c.businessType!),
                _InfoRow(label: 'Estado', value: c.open ? 'Abierto' : 'Cerrado'),
              ],
            ),
            const SizedBox(height: 16),
            if (c.address != null && c.address!.isNotEmpty)
              _buildSection(
                'Ubicación',
                [_InfoRow(label: 'Dirección', value: c.address!)],
              ),
            const SizedBox(height: 16),
            _buildSection(
              'Estadísticas',
              [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(
                      icon: Icons.star,
                      label: 'Rating',
                      value: c.stats != null ? c.stats!.rating.toString() : '-',
                    ),
                    _StatChip(
                      icon: Icons.shopping_bag,
                      label: 'Ventas',
                      value: c.stats?.ventas.toString() ?? '-',
                    ),
                    _StatChip(
                      icon: Icons.inventory_2,
                      label: 'Productos',
                      value: c.stats?.productos.toString() ?? '-',
                    ),
                  ],
                ),
              ],
            ),
            if (c.schedule != null && _formatSchedule(c.schedule).isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSection(
                'Horario',
                [_InfoRow(label: 'Horario', value: _formatSchedule(c.schedule))],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openEdit(context),
                icon: const Icon(Icons.edit),
                label: const Text('Editar restaurante'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MyCommerce c) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: c.image != null && c.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        c.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.store, color: AppColors.green, size: 36),
                      ),
                    )
                  : const Icon(Icons.store, color: AppColors.green, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.businessName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (c.isPrimary) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Principal',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.purple,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  String _formatSchedule(dynamic schedule) {
    if (schedule == null) return '';
    if (schedule is String) return schedule;
    if (schedule is Map && schedule['raw'] != null) return schedule['raw'].toString();
    return jsonEncode(schedule);
  }

  Future<void> _openEdit(BuildContext context) async {
    final c = commerce;
    if (!c.isPrimary) {
      try {
        await CommerceListService.setPrimary(c.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
          );
        }
        return;
      }
    }
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CommerceDataPage(),
        ),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.green),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
