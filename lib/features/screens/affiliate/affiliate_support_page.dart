import 'package:flutter/material.dart';

class AffiliateSupportPage extends StatefulWidget {
  const AffiliateSupportPage({super.key});

  @override
  State<AffiliateSupportPage> createState() => _AffiliateSupportPageState();
}

class _AffiliateSupportPageState extends State<AffiliateSupportPage> {
  final TextEditingController _messageController = TextEditingController();
  String _selectedCategory = 'General';
  final List<String> _categories = ['General', 'Técnico', 'Pagos', 'Comisiones', 'Cuenta'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Help Section
            const Text('Ayuda Rápida', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildQuickHelpCard(),
            
            const SizedBox(height: 24),
            
            // FAQ Section
            const Text('Preguntas Frecuentes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildFAQCard(),
            
            const SizedBox(height: 24),
            
            // Contact Support
            const Text('Contactar Soporte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildContactCard(),
            
            const SizedBox(height: 24),
            
            // Resources
            const Text('Recursos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildResourcesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickHelpCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildQuickHelpButton(
                    'Cómo Ganar',
                    Icons.trending_up,
                    Colors.green,
                    () => _showHowToEarn(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickHelpButton(
                    'Código QR',
                    Icons.qr_code,
                    Colors.blue,
                    () => _showQRCode(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickHelpButton(
                    'Pagos',
                    Icons.payment,
                    Colors.orange,
                    () => _showPaymentInfo(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickHelpButton(
                    'Niveles',
                    Icons.star,
                    Colors.purple,
                    () => _showLevelsInfo(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickHelpButton(String title, IconData icon, Color color, VoidCallback onTap) {
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

  Widget _buildFAQCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFAQItem(
              '¿Cómo funciona el programa de afiliados?',
              'Ganas comisiones por cada persona que se registre usando tu código de referido.',
            ),
            _buildFAQItem(
              '¿Cuándo recibo mis pagos?',
              'Los pagos se procesan cada 15 días para montos superiores a \$50.',
            ),
            _buildFAQItem(
              '¿Cómo subo de nivel?',
              'Completa metas mensuales de ganancias y referidos para alcanzar niveles superiores.',
            ),
            _buildFAQItem(
              '¿Puedo cambiar mi método de pago?',
              'Sí, puedes actualizar tu método de pago en la configuración de tu cuenta.',
            ),
            _buildFAQItem(
              '¿Qué pasa si mi referido cancela?',
              'Las comisiones ya aprobadas se mantienen, pero no se generan nuevas.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(answer, style: TextStyle(color: Colors.grey[600])),
        ),
      ],
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enviar Mensaje', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mensaje',
                border: OutlineInputBorder(),
                hintText: 'Describe tu problema o consulta...',
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showLiveChat();
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat en Vivo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _sendMessage();
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tiempo de respuesta: 2-4 horas en días laborables',
                      style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
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

  Widget _buildResourcesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildResourceItem(
              'Guía de Afiliados',
              'Aprende todo sobre el programa de afiliados',
              Icons.book,
              Colors.blue,
              () => _showGuide(),
            ),
            _buildResourceItem(
              'Video Tutoriales',
              'Videos explicativos paso a paso',
              Icons.video_library,
              Colors.red,
              () => _showVideos(),
            ),
            _buildResourceItem(
              'Herramientas de Marketing',
              'Recursos para promocionar tu código',
              Icons.campaign,
              Colors.green,
              () => _showMarketingTools(),
            ),
            _buildResourceItem(
              'Comunidad',
              'Conecta con otros afiliados',
              Icons.people,
              Colors.orange,
              () => _showCommunity(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceItem(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showHowToEarn() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cómo Ganar Comisiones'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Comparte tu código de referido', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• En redes sociales\n• Por WhatsApp\n• En tu blog o sitio web'),
              SizedBox(height: 16),
              Text('2. Gana por cada registro', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• \$15 por nuevo usuario\n• \$5 por primera compra\n• 5% de comisión continua'),
              SizedBox(height: 16),
              Text('3. Sube de nivel', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Bronce: \$0-\$500\n• Plata: \$500-\$2000\n• Oro: \$2000+\n• Diamante: \$5000+'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tu Código QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('ZONIX123', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Escanea para registrarte'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código QR descargado')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700]),
            child: const Text('Descargar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPaymentInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de Pagos'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Métodos de Pago:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Transferencia bancaria\n• PayPal\n• Criptomonedas'),
              SizedBox(height: 16),
              Text('Frecuencia:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Cada 15 días\n• Monto mínimo: \$50'),
              SizedBox(height: 16),
              Text('Comisiones:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Transferencia: Gratis\n• PayPal: 2.9%\n• Crypto: 1%'),
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

  void _showLevelsInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Niveles de Afiliado'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLevelInfo('Bronce', '0-500', '5% comisión', Colors.brown),
              _buildLevelInfo('Plata', '500-2000', '7% comisión', Colors.grey),
              _buildLevelInfo('Oro', '2000-5000', '10% comisión', Colors.amber),
              _buildLevelInfo('Diamante', '5000+', '15% comisión', Colors.blue),
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

  static Widget _buildLevelInfo(String level, String range, String commission, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.star, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Ganancias: \$$range'),
                Text(commission),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLiveChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat en Vivo'),
        content: const Text('Conectando con un agente de soporte...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat iniciado')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700]),
            child: const Text('Iniciar Chat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un mensaje')),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mensaje enviado exitosamente')),
    );
    _messageController.clear();
  }

  void _showGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guía de Afiliados'),
        content: const Text('Descargando guía completa...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guía descargada')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
            child: const Text('Descargar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVideos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Tutoriales'),
        content: const Text('Abriendo biblioteca de videos...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showMarketingTools() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Herramientas de Marketing'),
        content: const Text('Accediendo a herramientas...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showCommunity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comunidad'),
        content: const Text('Conectando con la comunidad...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
} 