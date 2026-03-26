import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/features/screens/delivery_company/delivery_company_add_agent_page.dart';
import 'package:zonix/features/services/delivery_company_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/safe_parse.dart';
import '../../utils/responsive_helper.dart';

class DeliveryCompanyAgentsPage extends StatefulWidget {
  const DeliveryCompanyAgentsPage({super.key});

  @override
  State<DeliveryCompanyAgentsPage> createState() => _DeliveryCompanyAgentsPageState();
}

class _DeliveryCompanyAgentsPageState extends State<DeliveryCompanyAgentsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryCompanyService>().loadAgents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Agentes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const DeliveryCompanyAddAgentPage()),
          );
          if (added == true && context.mounted) {
            context.read<DeliveryCompanyService>().loadAgents();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<DeliveryCompanyService>(
        builder: (context, service, _) {
          if (service.agentsLoading && service.agents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (service.agentsError != null && service.agents.isEmpty) {
            return _buildError(service.agentsError!, () => service.loadAgents());
          }
          if (service.agents.isEmpty) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            onRefresh: () => service.loadAgents(),
            child: ResponsiveCenter(
              maxWidth: 900,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: service.agents.length,
                itemBuilder: (context, i) => _buildAgentCard(service.agents[i], isDark),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAgentCard(Map<String, dynamic> agent, bool isDark) {
    final name = agent['name'] as String? ?? 'Sin nombre';
    final working = agent['working'] == true;
    final status = agent['status'] as String? ?? 'inactive';
    final vehicleType = agent['vehicle_type'] as String? ?? '';
    final rating = safeDouble(agent['rating']);
    final deliveries = safeInt(agent['total_deliveries']);
    final phone = agent['phone'] as String? ?? '';
    final payoutPct = safeDouble(agent['payout_percentage'], 70.0);
    final agentId = safeInt(agent['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grayDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.white12 : AppColors.black12),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.blue.withValues(alpha: 0.15),
                child: const Icon(Icons.person, color: AppColors.blue, size: 24),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: working ? AppColors.green : AppColors.gray,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppColors.grayDark : AppColors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (vehicleType.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_vehicleIcon(vehicleType), size: 14, color: AppColors.secondaryText(context)),
                          const SizedBox(width: 4),
                          Text(vehicleType, style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context))),
                        ],
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: AppColors.orange),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context))),
                      ],
                    ),
                    Text('$deliveries entregas', style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context))),
                  ],
                ),
                if (phone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(phone, style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context))),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: InkWell(
                    onTap: () => _showEditPayoutDialog(context, agentId, name, payoutPct),
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pago: ${payoutPct.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 12, color: AppColors.orange),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 14, color: AppColors.orange),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(status, working),
        ],
      ),
    );
  }

  void _showEditPayoutDialog(BuildContext context, int agentId, String agentName, double currentPct) {
    final controller = TextEditingController(text: currentPct.toStringAsFixed(0));
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Porcentaje de pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Agente: $agentName', style: TextStyle(fontSize: 13, color: AppColors.secondaryText(context))),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Porcentaje (0-100)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final pct = double.tryParse(controller.text.replaceAll(',', '.'));
              if (pct == null || pct < 0 || pct > 100) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Ingresa un número entre 0 y 100')));
                return;
              }
              Navigator.of(ctx).pop();
              final ok = await context.read<DeliveryCompanyService>().updateAgentPayout(agentId, pct);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Porcentaje actualizado' : 'Error al actualizar')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool working) {
    final label = working ? 'Disponible' : (status == 'active' ? 'Inactivo' : status);
    final color = working ? AppColors.green : AppColors.gray;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  IconData _vehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'motorcycle':
      case 'moto':
        return Icons.two_wheeler;
      case 'bicycle':
      case 'bicicleta':
        return Icons.pedal_bike;
      case 'car':
      case 'carro':
        return Icons.directions_car;
      default:
        return Icons.delivery_dining;
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.secondaryText(context)),
          const SizedBox(height: 16),
          Text('No tienes agentes registrados', style: TextStyle(fontSize: 16, color: AppColors.secondaryText(context))),
        ],
      ),
    );
  }

  Widget _buildError(String msg, VoidCallback retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.red),
            const SizedBox(height: 16),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
