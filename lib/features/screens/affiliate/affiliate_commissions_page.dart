import 'package:flutter/material.dart';

class AffiliateCommissionsPage extends StatefulWidget {
  const AffiliateCommissionsPage({super.key});

  @override
  State<AffiliateCommissionsPage> createState() => _AffiliateCommissionsPageState();
}

class _AffiliateCommissionsPageState extends State<AffiliateCommissionsPage> {
  String _selectedFilter = 'Todas';
  final List<String> _filters = ['Todas', 'Pendientes', 'Aprobadas', 'Pagadas', 'Rechazadas'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comisiones'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard('Total Ganado', '\$2,450', Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard('Pendiente', '\$180', Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard('Este Mes', '\$450', Colors.blue),
                ),
              ],
            ),
          ),
          
          // Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: Row(
              children: [
                const Text('Filtrar: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _filters.map((filter) {
                      return DropdownMenuItem(value: filter, child: Text(filter));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Commission List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 15,
              itemBuilder: (context, index) {
                return _buildCommissionCard(index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showWithdrawalDialog();
        },
        backgroundColor: Colors.purple[700],
        child: const Icon(Icons.payment, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionCard(int index) {
    final commissionTypes = ['Referido', 'Venta', 'Bono', 'Nivel', 'Especial'];
    final statuses = ['Pendiente', 'Aprobada', 'Pagada', 'Rechazada'];
    final amounts = [15.00, 25.50, 10.00, 30.00, 8.75, 20.00, 12.50, 18.25];
    
    final type = commissionTypes[index % commissionTypes.length];
    final status = statuses[index % statuses.length];
    final amount = amounts[index % amounts.length];
    final isPending = status == 'Pendiente';
    final isRejected = status == 'Rechazada';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _getStatusColor(status),
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_getCommissionIcon(type), color: _getCommissionColor(type)),
                      const SizedBox(width: 8),
                      Text(
                        type,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Referido: ${_getReferralName(index)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Fecha: ${_getCommissionDate(index)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              
              if (isPending || isRejected) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _showCommissionDetails(index);
                        },
                        child: const Text('Ver Detalles'),
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _showApproveDialog(index);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                          child: const Text('Aprobar', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendiente':
        return Colors.orange;
      case 'Aprobada':
        return Colors.blue;
      case 'Pagada':
        return Colors.green;
      case 'Rechazada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getCommissionColor(String type) {
    switch (type) {
      case 'Referido':
        return Colors.blue;
      case 'Venta':
        return Colors.green;
      case 'Bono':
        return Colors.orange;
      case 'Nivel':
        return Colors.purple;
      case 'Especial':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCommissionIcon(String type) {
    switch (type) {
      case 'Referido':
        return Icons.person_add;
      case 'Venta':
        return Icons.shopping_cart;
      case 'Bono':
        return Icons.card_giftcard;
      case 'Nivel':
        return Icons.star;
      case 'Especial':
        return Icons.emoji_events;
      default:
        return Icons.attach_money;
    }
  }

  String _getReferralName(int index) {
    final names = [
      'Juan Pérez',
      'María González',
      'Carlos Rodríguez',
      'Ana Martínez',
      'Luis Fernández',
      'Sofia López',
      'Pedro García',
      'Carmen Ruiz',
    ];
    return names[index % names.length];
  }

  String _getCommissionDate(int index) {
    final dates = [
      '15/12/2024',
      '14/12/2024',
      '13/12/2024',
      '12/12/2024',
      '11/12/2024',
      '10/12/2024',
      '09/12/2024',
      '08/12/2024',
    ];
    return dates[index % dates.length];
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Comisiones'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('Todas las comisiones', true),
            _buildFilterOption('Solo pendientes', false),
            _buildFilterOption('Solo aprobadas', false),
            _buildFilterOption('Solo pagadas', false),
            _buildFilterOption('Por rango de fechas', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filtro aplicado')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700]),
            child: const Text('Aplicar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String title, bool isSelected) {
    return CheckboxListTile(
      title: Text(title),
      value: isSelected,
      onChanged: (value) {},
      activeColor: Colors.purple[700],
    );
  }

  void _showCommissionDetails(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de Comisión #${1000 + index}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tipo', 'Referido'),
              _buildDetailRow('Referido', _getReferralName(index)),
              _buildDetailRow('Fecha', _getCommissionDate(index)),
              _buildDetailRow('Monto', '\$15.00'),
              _buildDetailRow('Estado', 'Pendiente'),
              _buildDetailRow('Descripción', 'Comisión por nuevo usuario registrado'),
              const SizedBox(height: 16),
              const Text('Historial:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildHistoryItem('15/12/2024 10:30', 'Comisión generada'),
              _buildHistoryItem('15/12/2024 10:35', 'Enviada para revisión'),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String date, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(width: 8),
          Text(action, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showApproveDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar Comisión'),
        content: Text('¿Estás seguro de que deseas aprobar la comisión #${1000 + index}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comisión aprobada exitosamente')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('Aprobar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showWithdrawalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Retiro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tu saldo disponible es \$180.00'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Monto a retirar',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Método de pago',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'bank', child: Text('Transferencia Bancaria')),
                DropdownMenuItem(value: 'paypal', child: Text('PayPal')),
                DropdownMenuItem(value: 'crypto', child: Text('Criptomonedas')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Solicitud de retiro enviada')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700]),
            child: const Text('Solicitar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 