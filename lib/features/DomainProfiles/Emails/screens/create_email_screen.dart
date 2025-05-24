import 'package:flutter/material.dart';
import '../models/email.dart';
import '../api/email_service.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import 'package:zonix_eats/features/utils/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
final logger = Logger();

class CreateEmailScreen extends StatefulWidget {
  final int userId;

  const CreateEmailScreen({super.key, required this.userId});

  @override
  CreateEmailScreenState createState() => CreateEmailScreenState();
}

class CreateEmailScreenState extends State<CreateEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final EmailService _emailService = EmailService();

  @override
    void initState() {
      super.initState();
      logger.i('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++wUserId recibido en CreateEmailScreen: ${widget.userId}');
    }


  @override
  Widget build(BuildContext context) {
    // Obtenemos las dimensiones de la pantalla
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Email'),
   
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Registra tu nuevo correo electrónico aquí:',
                      style: TextStyle(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),

                    // Imagen SVG responsiva
                    SvgPicture.asset(
                      'assets/images/undraw_mention_re_k5xc.svg',
                      height: size.height * 0.3, // 30% del alto de la pantalla
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24.0),

                    // Formulario de creación
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa un email';
                              } else if (!value.contains('@')) {
                                return 'Por favor ingresa un email válido que contenga @';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24.0),

                      
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
       // FloatingActionButton
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min, // Minimiza el espacio ocupado por la columna
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8, // 80% del ancho de la pantalla
            child: FloatingActionButton.extended(
              onPressed: _createEmail,
              tooltip: 'Registrar Email',
              icon: const Icon(Icons.email_outlined),
              label: const Text('Registrar Email'),
            ),
          ),
          const SizedBox(height: 16.0), // Espaciador
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }


Future<void> _createEmail() async {
  if (_formKey.currentState!.validate()) {
    final email = Email(
      id: 0, // Generado en el backend
      profileId: widget.userId,
      email: _emailController.text,
      isPrimary: true,
      status: true,
    );

    try {
      await _emailService.createEmail(email, widget.userId);
      context.read<UserProvider>().setEmailCreated(true); // Actualiza el estado
      Navigator.pop(context, true); // Devuelve `true` para indicar éxito
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar el email: $e')),
      );
    }
  }
}




}
