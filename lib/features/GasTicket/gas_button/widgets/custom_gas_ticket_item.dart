import 'package:flutter/material.dart';
import 'package:zonix_eats/features/GasTicket/gas_button/providers/status_provider.dart';

class CustomGasTicketItem extends StatefulWidget {
  final Widget thumbnail;
  final String queuePosition;
  final String status;
  final String appointmentDate;
  final String timePosition;

  const CustomGasTicketItem({
    Key? key,
    required this.thumbnail,
    required this.queuePosition,
    required this.status,
    required this.appointmentDate,
    required this.timePosition,
  }) : super(key: key);

  @override
  _CustomGasTicketItemState createState() => _CustomGasTicketItemState();
}

class _CustomGasTicketItemState extends State<CustomGasTicketItem> {
  final StatusProvider statusProvider = StatusProvider(); // Mover aquí para evitar problemas de reactividad.

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    // Determinar el color para el texto "Estado:"
    Color estadoLabelColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0), // Bordes redondeados
          child: SizedBox(
            width: 56.0,
            height: 56.0,
            child: ImageIcon(
              statusProvider.getStatusIcon(widget.status),
              color: statusProvider.getStatusColor(widget.status), // Color según el estado
              size: 56.0,
            ),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket #${widget.queuePosition}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            // Usar Row para mantener "Estado:" y el estado traducido en la misma línea
            Row(
              children: [
                Text(
                  'Estado: ', // El label "Estado:" siempre en blanco o negro
                  style: TextStyle(color: estadoLabelColor),
                ),
                Text(
                  statusProvider.getStatusSpanish(widget.status), // Llamada a la función para obtener el estado en español
                  style: TextStyle(color: statusProvider.getStatusColor(widget.status), fontWeight: FontWeight.bold), // Color según el estado
                ),
              ],
            ),
            Text('Cita: ${widget.appointmentDate}', style: TextStyle(color: textColor)),
            Text('Posición de tiempo: ${widget.timePosition}', style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );
  }
}
