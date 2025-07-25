import 'package:flutter/material.dart';
import 'package:zonix/features/utils/app_colors.dart';

class HelpAndFAQPage extends StatelessWidget {
  const HelpAndFAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.headerGradientStart(context),
                AppColors.headerGradientMid(context),
                AppColors.headerGradientEnd(context),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Ayuda y Comentarios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)), // TODO: internacionalizar
            iconTheme: IconThemeData(color: AppColors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Bienvenido a la sección de Ayuda y Comentarios', // TODO: internacionalizar
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aquí encontrarás información útil sobre cómo utilizar la aplicación Zonix.', // TODO: internacionalizar
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            _buildFAQItem(
              context,
              '¿Cómo registrarse en la aplicación?', // TODO: internacionalizar
              'Para registrarse en la aplicación Zonix, sigue estos pasos:\n\n'
              '1. Abre la aplicación y selecciona "Registrarse".\n'
              '2. Ingresa tu información personal, incluyendo nombre, dirección y número de contacto.\n'
              '3. Acepta los términos y condiciones.\n'
              '4. Haz clic en "Enviar" para completar el registro.\n'
              '5. Recibirás un correo electrónico de confirmación.',
            ),
            _buildFAQItem(
              context,
              '¿Cómo iniciar sesión?', // TODO: internacionalizar
              'Para iniciar sesión en tu cuenta Zonix, sigue estos pasos:\n\n'
              '1. Abre la aplicación y selecciona "Iniciar sesión".\n'
              '2. Ingresa tu dirección de correo electrónico y contraseña.\n'
              '3. Haz clic en "Iniciar sesión".\n'
              '4. Si olvidaste tu contraseña, puedes restablecerla desde la opción "Olvidé mi contraseña".',
            ),
            _buildFAQItem(
              context,
              '¿Cómo agendar una cita?', // TODO: internacionalizar
              'Para agendar una cita en Zonix, sigue estos pasos:\n\n'
              '1. Inicia sesión en tu cuenta.\n'
              '2. Selecciona "Agendar Cita" en el menú principal.\n'
              '3. Selecciona el restaurante que deseas y la fecha y hora de la cita.\n'
              '4. Revisa la información y haz clic en "Confirmar Cita".\n'
              '5. Recibirás un mensaje de confirmación de tu cita.',
            ),
            _buildFAQItem(
              context,
              '¿Qué hacer si tengo un problema?', // TODO: internacionalizar
              'Si tienes algún problema con la aplicación, por favor sigue estos pasos:\n\n'
              '1. Verifica tu conexión a internet.\n'
              '2. Reinicia la aplicación y vuelve a intentarlo.\n'
              '3. Si el problema persiste, dirígete a la sección de "Comentarios" para enviar tu consulta o reportar el problema.\n'
              '4. Nuestro equipo de soporte se pondrá en contacto contigo lo antes posible.',
            ),
            _buildFAQItem(
              context,
              '¿Cómo contactar al soporte?', // TODO: internacionalizar
              'Para contactar al soporte de Zonix, puedes:\n\n'
              '1. Enviar un correo electrónico a soporte@zonix.com.\n'
              '2. Utilizar el formulario de contacto en la aplicación.\n'
              '3. Visitar nuestra página web y utilizar el chat en vivo.',
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Comentarios y Sugerencias', // TODO: internacionalizar
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nos encantaría saber de ti. Si tienes comentarios o sugerencias sobre la aplicación, por favor envíanos un mensaje utilizando el formulario de comentarios.', // TODO: internacionalizar
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: AppColors.cardBg(context),
      shadowColor: AppColors.purple.withOpacity(0.10),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
