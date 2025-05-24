import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix_eats/features/GasTicket/gas_button/api/gas_ticket_service.dart';
import 'package:zonix_eats/features/GasTicket/gas_button/models/gas_ticket.dart';
import 'package:zonix_eats/features/GasTicket/gas_button/widgets/ticket_list_view.dart';
import 'package:zonix_eats/features/GasTicket/gas_button/screens/create_gas_ticket_screen.dart';
import 'package:zonix_eats/features/utils/user_provider.dart';

class GasTicketListScreen extends StatefulWidget {
  const GasTicketListScreen({super.key});

  @override
  GasTicketListScreenState createState() => GasTicketListScreenState();
}

class GasTicketListScreenState extends State<GasTicketListScreen> with TickerProviderStateMixin {
  final GasTicketService _ticketService = GasTicketService();
  List<GasTicket>? _ticketList;
  bool _isLoading = true; // Para manejar el estado de carga
  String? _errorMessage; // Para manejar errores

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _loadTickets(userProvider.userId);
    });
  }

  Future<void> _loadTickets(int userId) async {
    setState(() {
      _isLoading = true; // Iniciar carga
      _errorMessage = null; // Reiniciar mensaje de error
    });

    try {
      logger.i('User ID: fetchGasTickets $userId');
      final tickets = await _ticketService.fetchGasTickets(userId);
      logger.i('_ticketService.fetchGasTickets $tickets');

      if (!mounted) return; // Verificar si el widget sigue montado

      setState(() {
        _ticketList = tickets;
        _isLoading = false; // Carga completa
      });
    } catch (e) {
      print('Error al cargar tickets: $e');
      setState(() {
        _errorMessage = 'Error al cargar los tickets. Inténtalo de nuevo.'; // Mensaje de error
        _isLoading = false; // Carga completa
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gas Ticket'),
            actions: [
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 10),
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  iconSize: 24,
                  padding: const EdgeInsets.all(0),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                         builder: (context) => CreateGasTicketScreen(userId: userProvider.userId),
                      ),
                    ).then((_) => _loadTickets(userProvider.userId)); // Recargar lista
                  },
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.only(top: 0.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? const Center(child: Text('No hay tickets disponibles.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
                    : _ticketList!.isEmpty
                        ? const Center(child: Text('No hay tickets disponibles.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
                        : TicketListView(tickets: _ticketList!),
          ),
        );
      },
    );
  }
}