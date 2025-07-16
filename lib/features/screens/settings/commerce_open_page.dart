import 'package:flutter/material.dart';
import 'package:zonix/features/services/commerce_data_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommerceOpenPage extends StatefulWidget {
  const CommerceOpenPage({Key? key}) : super(key: key);

  @override
  State<CommerceOpenPage> createState() => _CommerceOpenPageState();
}

class _CommerceOpenPageState extends State<CommerceOpenPage> {
  bool _open = false;
  bool _loading = false;
  bool _initialLoading = true;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadCommerceStatus();
  }

  Future<void> _loadCommerceStatus() async {
    try {
      setState(() {
        _initialLoading = true;
        _error = null;
      });

      final data = await CommerceDataService.getCommerceData();
      
      setState(() {
        _open = data['open'] ?? false;
        _initialLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar estado: $e';
        _initialLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() { 
      _loading = true; 
      _error = null; 
      _success = null; 
    });

    try {
      final data = {
        'open': _open,
      };

      await CommerceDataService.updateCommerceData(data);
      
      setState(() {
        _loading = false;
        _success = _open ? '¡El comercio está ABIERTO!' : 'El comercio está CERRADO.';
      });

      // Limpiar mensaje de éxito después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _success = null;
          });
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error al actualizar estado: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Estado del comercio'),
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final color = _open ? Colors.green : Colors.red;
    final text = _open ? 'ABIERTO' : 'CERRADO';
    final icon = _open ? Icons.store : Icons.store_mall_directory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado del comercio'),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Estado actual
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: _open 
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.red.shade400, Colors.red.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _open 
                        ? 'Los clientes pueden hacer pedidos'
                        : 'Los clientes no pueden hacer pedidos',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Control de estado
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.power_settings_new, color: AppColors.blue),
                        const SizedBox(width: 12),
                        const Text(
                          'Control de Estado',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estado actual:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                text,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _open,
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                          inactiveTrackColor: Colors.red.shade200,
                          onChanged: (v) => setState(() => _open = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Información adicional
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Información',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _open
                        ? '• Tu comercio está visible para los clientes\n'
                          '• Los clientes pueden hacer pedidos\n'
                          '• Aparecerás en la lista de restaurantes activos\n'
                          '• Recibirás notificaciones de nuevos pedidos'
                        : '• Tu comercio no está visible para los clientes\n'
                          '• Los clientes no pueden hacer pedidos\n'
                          '• No aparecerás en la lista de restaurantes\n'
                          '• No recibirás notificaciones de pedidos',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Mensajes de estado
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            
            if (_success != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _success!, 
                        style: TextStyle(color: color, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // Botón de guardar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
                label: Text(
                  _loading ? 'Guardando...' : 'Guardar estado',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 