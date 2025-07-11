import 'package:flutter/material.dart';

class AffiliateDashboardPage extends StatefulWidget {
  const AffiliateDashboardPage({super.key});

  @override
  State<AffiliateDashboardPage> createState() => _AffiliateDashboardPageState();
}

class _AffiliateDashboardPageState extends State<AffiliateDashboardPage> {
  String _selectedPeriod = 'Esta Semana';
  final List<String> _periods = ['Hoy', 'Esta Semana', 'Este Mes', 'Este Año'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Afiliado'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Datos actualizados')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('Período: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPeriod,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _periods.map((period) {
                        return DropdownMenuItem(value: period, child: Text(period));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPeriod = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Key Metrics
            const Text('Métricas Principales', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildMetricCard('Ganancias', '\$1,250', Icons.attach_money, Colors.green),
                _buildMetricCard('Referidos', '24', Icons.people, Colors.blue),
                _buildMetricCard('Comisiones', '\$180', Icons.percent, Colors.orange),
                _buildMetricCard('Nivel', 'Plata', Icons.star, Colors.purple),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Performance Overview
            const Text('Resumen de Rendimiento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildPerformanceCard(),
            
            const SizedBox(height: 24),
            
            // Recent Activity
            const Text('Actividad Reciente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildRecentActivityCard(),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text('Acciones Rápidas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildQuickActionsCard(),
            
            const SizedBox(height: 24),
            
            // Goals & Achievements
            const Text('Metas y Logros', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildGoalsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Progreso del Mes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildProgressItem('Ganancias Objetivo', '\$2,000', '\$1,250', 0.625, Colors.green),
            _buildProgressItem('Referidos Objetivo', '50', '24', 0.48, Colors.blue),
            _buildProgressItem('Nivel Siguiente', 'Oro', 'Plata', 0.75, Colors.orange),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Excelente progreso! Estás en camino a alcanzar el nivel Oro',
                      style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, String target, String current, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('$current / $target', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                final activities = [
                  {'type': 'Comisión', 'description': 'Nuevo referido registrado', 'amount': '+15.00', 'time': '2 min'},
                  {'type': 'Ganancia', 'description': 'Pago de comisión recibido', 'amount': '+25.00', 'time': '1 hora'},
                  {'type': 'Referido', 'description': 'Juan Pérez se registró', 'amount': '', 'time': '3 horas'},
                  {'type': 'Nivel', 'description': 'Progreso hacia nivel Oro', 'amount': '+5%', 'time': '1 día'},
                  {'type': 'Comisión', 'description': 'Comisión por venta', 'amount': '+8.50', 'time': '2 días'},
                ];
                
                final activity = activities[index];
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getActivityColor(activity['type']!),
                    child: Icon(_getActivityIcon(activity['type']!), color: Colors.white, size: 16),
                  ),
                  title: Text(activity['description']!),
                  subtitle: Text('Hace ${activity['time']}'),
                  trailing: activity['amount']!.isNotEmpty 
                    ? Text(
                        activity['amount']!,
                        style: TextStyle(
                          color: activity['amount']!.startsWith('+') ? Colors.green : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'Comisión':
        return Colors.orange;
      case 'Ganancia':
        return Colors.green;
      case 'Referido':
        return Colors.blue;
      case 'Nivel':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'Comisión':
        return Icons.percent;
      case 'Ganancia':
        return Icons.attach_money;
      case 'Referido':
        return Icons.person_add;
      case 'Nivel':
        return Icons.star;
      default:
        return Icons.info;
    }
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Invitar Amigos',
                    Icons.share,
                    Colors.blue,
                    () => _showInviteDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Ver Código',
                    Icons.qr_code,
                    Colors.green,
                    () => _showReferralCode(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Solicitar Pago',
                    Icons.payment,
                    Colors.orange,
                    () => _showPaymentDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Soporte',
                    Icons.support_agent,
                    Colors.purple,
                    () => _showSupportDialog(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Metas del Mes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildGoalItem('Nivel Oro', 'Gana \$3,000', '75% completado', 0.75, Colors.amber),
            _buildGoalItem('50 Referidos', 'Invita 50 personas', '48% completado', 0.48, Colors.blue),
            _buildGoalItem('Bono Extra', 'Completa 100 entregas', '60% completado', 0.60, Colors.green),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Estás muy cerca del nivel Oro! Solo necesitas \$750 más',
                      style: TextStyle(color: Colors.amber[700], fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(String title, String description, String progress, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(progress, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invitar Amigos'),
        content: const Text('Comparte tu código de referido con amigos y gana comisiones por cada registro.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enlace compartido')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
            child: const Text('Compartir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReferralCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tu Código de Referido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ZONIX123',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Comparte este código con tus amigos para ganar comisiones'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Pago'),
        content: const Text('Tu saldo disponible es \$1,250. ¿Deseas solicitar un pago?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Solicitud de pago enviada')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('Solicitar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soporte'),
        content: const Text('¿Necesitas ayuda? Nuestro equipo de soporte está disponible 24/7.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat de soporte iniciado')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700]),
            child: const Text('Contactar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 