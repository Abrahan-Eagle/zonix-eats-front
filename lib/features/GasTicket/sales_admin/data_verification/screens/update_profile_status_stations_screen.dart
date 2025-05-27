  import 'package:flutter/material.dart';
  import 'package:flutter_svg/flutter_svg.dart';
  import 'package:zonix/features/GasTicket/gas_button/api/gas_ticket_service.dart';

  class CreateGasTicketScreen extends StatefulWidget {
    final int userId;

    const CreateGasTicketScreen({super.key, required this.userId});

    @override
    CreateGasTicketScreenState createState() => CreateGasTicketScreenState();
  }

  class CreateGasTicketScreenState extends State<CreateGasTicketScreen> {
    final GasTicketService _ticketService = GasTicketService();
    final _formKey = GlobalKey<FormState>();

    int? _selectedCylinderId;
    List<Map<String, dynamic>> _gasCylinders = [];
    bool _isExternal = false;
    List<Map<String, dynamic>> _stations = [];
    int? _selectedStationId;

    bool _isLoading = false;

    @override
    void initState() {
      super.initState();
      _loadGasCylinders();
    }

    Future<void> _loadGasCylinders() async {
      setState(() {
        _isLoading = true;
      });
      try {
        final cylinders = await _ticketService.fetchGasCylinders(widget.userId);
        setState(() {
          _gasCylinders = cylinders;
        });
      } catch (e) {
        _showCustomSnackBar(
          'Error loading cylinders: $e',
          Colors.red,
          Icons.error,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }

    Future<void> _loadStations() async {
      setState(() {
        _isLoading = true;
      });
      try {
        final stations = await _ticketService.fetchStations();
        setState(() {
          _stations = stations;
        });
      } catch (e) {
        _showCustomSnackBar(
          'Error loading stations: $e',
          Colors.red,
          Icons.error,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }

    void _submitForm() async {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = true;
        });
        try {
          await _ticketService.createGasTicket(
            widget.userId,
            _selectedCylinderId!,
            _isExternal,
            _selectedStationId,
          );
          _showCustomSnackBar(
            'Ticket created successfully!',
            Colors.green,
            Icons.check_circle,
          );
          Navigator.pop(context);
        } catch (e) {
          _showCustomSnackBar(
            'Failed to create ticket: $e',
            Colors.red,
            Icons.error,
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    void _showCustomSnackBar(String message, Color backgroundColor, IconData icon) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      final bool isSunday = DateTime.now().weekday == DateTime.sunday;
      final screenWidth = MediaQuery.of(context).size.width;
      final isLargeScreen = screenWidth > 600;

      return Scaffold(
        appBar: AppBar(title: const Text('Generar Ticket de Gas')),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: 16.0,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SvgPicture.asset(
                    'assets/images/undraw_date_picker_re_r0p8.svg',
                    height: isLargeScreen ? 250 : 200,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¡Listo para comprar gas sin complicaciones?\n'
                  'Solo elige tu bombona y te daremos una cita con fecha y hora para recogerla. '
                  'Sin filas ni demoras, ¡todo más fácil!\n\n'
                  '⏳ Ojo: Tu ticket es válido solo por un día, así que asegúrate de ir a tiempo. '
                  '¿No puedes asistir? No pasa nada, cancela y reprograma cuando quieras.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (isSunday) ...[
                  CheckboxListTile(
                    title: const Text('¿Comprar gas en otra estación?'),
                    value: _isExternal,
                    onChanged: (value) {
                      setState(() {
                        _isExternal = value ?? false;
                      });
                      if (_isExternal) {
                        _loadStations();
                      }
                    },
                  ),
                  if (_isExternal) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Selecciona una estación'),
                        isExpanded: true,
                        items: _stations.map((station) {
                          return DropdownMenuItem<int>(
                            value: station['id'],
                            child: Text(station['code']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStationId = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Por favor, selecciona una estación' : null,
                      ),
                    ),
                  ]
                ],
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Selecciona una bombona'),
                    isExpanded: true,
                    value: _selectedCylinderId,
                    items: _gasCylinders.map((cylinder) {
                      return DropdownMenuItem<int>(
                        value: cylinder['id'],
                        child: Text(cylinder['gas_cylinder_code']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCylinderId = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Por favor, selecciona una bombona' : null,
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                if (!_isLoading)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(  // Usar Center para centrar el botón
                        child: SizedBox(
                          width: screenWidth * 0.8, // 80% del ancho de la pantalla
                          child: ElevatedButton.icon(
                            onPressed: _submitForm,
                            icon: const Icon(Icons.add_circle_outline), // Ícono
                            label: const Text('Crear Ticket'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0), // Espaciador
                    ],
                  ),

              ],
            ),
          ),
        ),
      );
    }
  }

