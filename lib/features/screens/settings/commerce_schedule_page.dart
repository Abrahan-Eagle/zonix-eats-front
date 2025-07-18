import 'package:flutter/material.dart';
import 'package:zonix/features/services/commerce_data_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommerceSchedulePage extends StatefulWidget {
  const CommerceSchedulePage({Key? key}) : super(key: key);

  @override
  State<CommerceSchedulePage> createState() => _CommerceSchedulePageState();
}

class _CommerceSchedulePageState extends State<CommerceSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final _scheduleController = TextEditingController();
  
  bool _loading = false;
  bool _initialLoading = true;
  String? _error;
  String? _success;

  // Horarios por día
  Map<String, Map<String, dynamic>> _scheduleData = {
    'monday': {'enabled': true, 'open': '08:00', 'close': '18:00'},
    'tuesday': {'enabled': true, 'open': '08:00', 'close': '18:00'},
    'wednesday': {'enabled': true, 'open': '08:00', 'close': '18:00'},
    'thursday': {'enabled': true, 'open': '08:00', 'close': '18:00'},
    'friday': {'enabled': true, 'open': '08:00', 'close': '18:00'},
    'saturday': {'enabled': true, 'open': '09:00', 'close': '14:00'},
    'sunday': {'enabled': false, 'open': '09:00', 'close': '14:00'},
  };

  final Map<String, String> _dayNames = {
    'monday': 'Lunes',
    'tuesday': 'Martes',
    'wednesday': 'Miércoles',
    'thursday': 'Jueves',
    'friday': 'Viernes',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
  };

  @override
  void initState() {
    super.initState();
    _loadScheduleData();
  }

  @override
  void dispose() {
    _scheduleController.dispose();
    super.dispose();
  }

  Future<void> _loadScheduleData() async {
    try {
      setState(() {
        _initialLoading = true;
        _error = null;
      });

      final data = await CommerceDataService.getCommerceData();
      final schedule = data['schedule'];
      
      if (schedule != null && schedule is String && schedule.isNotEmpty) {
        _parseScheduleString(schedule);
      }
      
      setState(() {
        _initialLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar horario: $e';
        _initialLoading = false;
      });
    }
  }

  void _parseScheduleString(String schedule) {
    // Parsear horario desde string (formato simple)
    // TODO: Implementar parsing más robusto
    _scheduleController.text = schedule;
  }

  String _generateScheduleString() {
    final buffer = StringBuffer();
    for (var entry in _scheduleData.entries) {
      final day = entry.key;
      final data = entry.value;
      final dayName = _dayNames[day]!;
      
      if (data['enabled']) {
        buffer.writeln('$dayName: ${data['open']} - ${data['close']}');
      } else {
        buffer.writeln('$dayName: Cerrado');
      }
    }
    return buffer.toString().trim();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { 
      _loading = true; 
      _error = null; 
      _success = null; 
    });

    try {
      final scheduleString = _generateScheduleString();
      
      final data = {
        'schedule': scheduleString,
      };

      await CommerceDataService.updateCommerceData(data);
      
      setState(() {
        _loading = false;
        _success = 'Horario actualizado correctamente.';
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
        _error = 'Error al actualizar horario: $e';
      });
    }
  }

  Widget _buildDaySchedule(String day, String dayName) {
    final data = _scheduleData[day]!;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: data['enabled'],
                  onChanged: (value) {
                    setState(() {
                      data['enabled'] = value ?? false;
                    });
                  },
                  activeColor: AppColors.purple,
                ),
                Text(
                  dayName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (data['enabled'])
                  Text(
                    '${data['open']} - ${data['close']}',
                    style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold),
                  )
                else
                  const Text(
                    'Cerrado',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            if (data['enabled']) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: data['open'],
                      decoration: const InputDecoration(
                        labelText: 'Apertura',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        data['open'] = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('a', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: data['close'],
                      decoration: const InputDecoration(
                        labelText: 'Cierre',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        data['close'] = value;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Horario de atención'),
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horario de atención'),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Selector de horarios por día
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: AppColors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Horario por Días',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._scheduleData.keys.map((day) => _buildDaySchedule(day, _dayNames[day]!)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Horario personalizado
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Horario Personalizado',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Si necesitas un horario más específico, puedes escribirlo aquí:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _scheduleController,
                        decoration: const InputDecoration(
                          labelText: 'Horario personalizado',
                          border: OutlineInputBorder(),
                          hintText: 'Ejemplo:\nL-V 8:00-18:00\nS 9:00-14:00\nD cerrado',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
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
                  padding: const EdgeInsets.all(16.0),
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
                      const Text(
                        '• El horario se muestra a los clientes para que sepan cuándo pueden hacer pedidos\n'
                        '• Los días marcados como "Cerrado" no aparecerán en el horario público\n'
                        '• Puedes usar el horario personalizado para casos especiales\n'
                        '• Los cambios se aplican inmediatamente',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_success!, style: const TextStyle(color: Colors.green))),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

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
                    _loading ? 'Guardando...' : 'Guardar horario',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ),
              
              // Espacio adicional para evitar overflow
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
} 