  import 'package:flutter/material.dart';
  import 'package:flutter_svg/flutter_svg.dart';
  import 'package:zonix_eats/features/GasTicket/gas_button/api/gas_ticket_service.dart';

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

  // Obtén el brillo actual (modo claro u oscuro)
  final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Scaffold(
    appBar: AppBar(
      toolbarHeight: 80, // Aumenta la altura si lo necesitas
      elevation: 0,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      title: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generar Ticket de Gas',
                  style: TextStyle(
                    fontFamily: 'Inter Tight',
                    fontSize: MediaQuery.of(context).size.width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reserva tu Ticket de Gas',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: MediaQuery.of(context).size.width * 0.03,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.12,
              height: MediaQuery.of(context).size.width * 0.12,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFF4B39EF), width: 2),
              ),
              child: const Icon(
                Icons.rocket_launch,
                color: Color(0xFF4B39EF),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    ),
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              'assets/images/undraw_date_picker_re_r0p8.svg',
              width: isLargeScreen ? 329 : 250,
              height: isLargeScreen ? 278 : 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '¡Listo para comprar gas sin complicaciones!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter Tight',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Solo elige tu bombona y aparta tu cita. Sin filas ni demoras, ¡todo más fácil!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // Aquí se cambia el color de fondo según el modo oscuro
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Selecciona tu Bombona',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontFamily: 'Inter Tight',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E1E) : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: 'Selecciona tu Bombona',
                            labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 16,
                                  color: Theme.of(context).hintColor,
                                ),
                            prefixIcon: const Icon(
                              Icons.gas_meter,
                              color: Color(0xFF4B39EF),
                              size: 22,
                            ),
                            border: InputBorder.none,
                          ),
                          isExpanded: true,
                          value: _selectedCylinderId,
                          items: _gasCylinders.map((cylinder) {
                            return DropdownMenuItem<int>(
                              value: cylinder['id'],
                              child: Text(
                                cylinder['gas_cylinder_code'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCylinderId = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Por favor, selecciona una bombona' : null,
                          icon: Transform.translate(
                            offset: const Offset(0, -4),
                            child: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF4B39EF),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (isSunday) ...[
                          Checkbox(
                            value: _isExternal,
                            onChanged: (value) {
                              setState(() {
                                _isExternal = value ?? false;
                              });
                              if (_isExternal) {
                                _loadStations();
                              }
                            },
                            activeColor: const Color(0xFF4B39EF),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 2), //aqui
                          Expanded(
                            child: Text(
                              '¿Comprar gas en otra estación?',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_isExternal)
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF1E1E1E) : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                          child: DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Seleccionar Estación',
                              labelStyle: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                              prefixIcon: const Icon(
                                Icons.location_on,
                                color: Color(0xFF4B39EF),
                                size: 22,
                              ),
                              border: InputBorder.none,
                            ),
                            isExpanded: true,
                            items: _stations.map((station) {
                              return DropdownMenuItem<int>(
                                value: station['id'],
                                child: Text(
                                  station['code'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedStationId = value;
                              });
                            },
                            validator: (value) => value == null
                                ? 'Por favor, selecciona una estación'
                                : null,
                            icon: Transform.translate(
                              offset: const Offset(0, -4),
                              child: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF4B39EF),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Nota: El ticket es válido por un día. Puedes cancelar o reprogramar si no puedes asistir.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (!_isLoading) ...[
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 15),
                child: SizedBox(
                  width: double.infinity, 
                  child: ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white, 
                      size: 24,
                    ),
                    label: const Text(
                      'Crear Ticket',
                      style: TextStyle(
                        fontFamily: 'Inter Tight',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, 
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16), 
                      backgroundColor: const Color(0xFF4B39EF), 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 3, 
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

  
  
  }

