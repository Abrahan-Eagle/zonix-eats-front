import 'package:flutter/material.dart';
import '../models/email.dart';
import '../api/email_service.dart';
import '../screens/create_email_screen.dart';
import 'package:logger/logger.dart';
final logger = Logger();


class EmailListScreen extends StatefulWidget {
  final int userId;
  final bool statusId;

  const EmailListScreen({super.key, required this.userId, this.statusId = false});

  @override
  EmailListScreenState createState() => EmailListScreenState();
}

class EmailListScreenState extends State<EmailListScreen> {
  final EmailService _emailService = EmailService();
  late Future<List<Email>> _emails;

  @override
  void initState() {
    super.initState();
     logger.i('=======================================================UserId recibido: ${widget.userId}');
    _emails = _emailService.fetchEmails(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emails'),
      ),
      body: FutureBuilder<List<Email>>(
        future: _emails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay correos disponibles.'));
          } else {
            final emails = snapshot.data!;
            return ListView.builder(
              itemCount: emails.length,
              itemBuilder: (context, index) {
                final email = emails[index];
                return ListTile(
                  title: Text(email.email),
                  subtitle: Text(
                    email.isPrimary ? 'Correo Primario' : 'Correo Secundario',
                  ),
                  trailing: Switch(
                    value: email.isPrimary,
                    onChanged: (value) async {
                      await _emailService.updateEmail(
                        email.id,
                        email.copyWith(isPrimary: value),
                      );
                      setState(() {
                        _emails = _emailService.fetchEmails(widget.userId);
                      });
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _navigateToCreateEmail, // Acción al presionar el FAB
      //   child: const Icon(Icons.add),
      // ),









floatingActionButton: Stack(
        children: [
          // El botón de creación de documentos
          Positioned(
            right: 10,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: _navigateToCreateEmail,
              child: const Icon(Icons.add),
            ),
          ),
          // El botón de confirmación solo si statusId es true
          if (widget.statusId)
            Positioned(
              right: 10,
              bottom: 85,
              child: FloatingActionButton(
                onPressed: () async {
                  // Mostrar el popup de confirmación antes de realizar la acción
                  bool? isConfirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Confirmar acción'),
                        content: const Text('¿Quieres aprobar esta solicitud?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);  // Retorna 'No'
                            },
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);  // Retorna 'Sí'
                            },
                            child: const Text('Sí'),
                          ),
                        ],
                      );
                    },
                  );

                  // Si el usuario confirma la acción, proceder con la lógica
                  if (isConfirmed == true) {
                    try {
                      // Llamar a la función updateStatusCheckScanner desde ApiServices
                      await EmailService().updateStatusCheckScanner(widget.userId);

                      // Mostrar SnackBar de éxito
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Estado actualizado'),
                          backgroundColor: Colors.green,  // Color de fondo para éxito
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: 'Cerrar',
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                        ),
                      );

                      // Retroceder después de la confirmación y acción exitosa
                      Navigator.of(context).pop();  // Retrocede a la pantalla anterior

                    } catch (e) {
                      // Mostrar SnackBar de error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,  // Color de fondo para error
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: 'Cerrar',
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                        ),
                      );
                    }
                  }
                },
                backgroundColor: Colors.green,
                child: const Icon(Icons.check),
              ),
            ),
        ],
      ),






    );
  }

  // Navegar a la pantalla de creación de email
  void _navigateToCreateEmail() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEmailScreen(userId: widget.userId),
      ),
    );

    // Si se creó un email, recargar la lista de emails
    if (result == true) {
      setState(() {
        _emails = _emailService.fetchEmails(widget.userId);
      });
    }
  }
}
