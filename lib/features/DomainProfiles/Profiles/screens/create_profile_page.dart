import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:zonix_glasses/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix_glasses/features/DomainProfiles/Profiles/models/profile_model.dart';
import 'package:zonix_glasses/features/utils/user_provider.dart';
import 'package:intl/intl.dart';

class CreateProfilePage extends StatefulWidget {
  final int userId;

  const CreateProfilePage({super.key, required this.userId});

  @override
  CreateProfilePageState createState() => CreateProfilePageState();
}

class CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late Profile _profile;
  final TextEditingController _dateController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _profile = Profile(
      id: 0,
      userId: widget.userId,
      firstName: '',
      middleName: '',
      lastName: '',
      secondLastName: '',
      photo: null,
      dateOfBirth: '',
      maritalStatus: '',
      sex: '',
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<String?> _compressImage(String filePath) async => filePath;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _profile = _profile.copyWith(photo: _imageFile!.path);
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se seleccionó ninguna imagen.')),
      );
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (!context.mounted) return;
    if (picked != null) {
      // Formateamos la fecha para mostrarla en el formato 'dd-MM-yyyy'
      String displayedDate = DateFormat('dd-MM-yyyy').format(picked);
      _dateController.text = displayedDate; // Mostrar fecha en la interfaz

      // Guardar la fecha en el formato 'yyyy-MM-dd' para la base de datos
      String savedDate = DateFormat('yyyy-MM-dd').format(picked);

      setState(() {
        _profile = _profile.copyWith(
          dateOfBirth: savedDate,
        ); // Guardar en formato adecuado para la DB
      });
    }
  }

    //   Future<void> _createProfile() async {
    //   if (_formKey.currentState!.validate()) {
    //     _formKey.currentState!.save();

    //     // Verificar si la imagen ha sido tomada
    //     if (_imageFile == null) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         const SnackBar(
    //           content: Text(
    //             'Por favor, tome una foto.',
    //             style: TextStyle(color: Colors.white),
    //           ),
    //           backgroundColor: Colors.red,
    //           behavior: SnackBarBehavior.fixed,
    //         ),
    //       );
    //       return; // No continuar si no hay imagen
    //     }

    //     // Mostrar el indicador de progreso
    //     showDialog(
    //       context: context,
    //       barrierDismissible: false, // Evita que se cierre al tocar fuera del cuadro
    //       builder: (BuildContext context) {
    //         return const Center(child: CircularProgressIndicator());
    //       },
    //     );

    //     try {
    //       // Intentar crear el perfil
    //       await ProfileService().createProfile(
    //         _profile,
    //         widget.userId,
    //         imageFile: _imageFile,
    //       );

    //       // Perfil creado exitosamente: actualizar el estado
    //       if (mounted) {
    //         context.read<UserProvider>().setProfileCreated(true);

    //         // Mostrar el SnackBar de éxito
    //         ScaffoldMessenger.of(context).showSnackBar(
    //           SnackBar(
    //             content: const Text(
    //               'Fue registrado exitosamente.',
    //               style: TextStyle(color: Colors.white),
    //             ),
    //             backgroundColor: Colors.green,
    //             behavior: SnackBarBehavior.fixed,
    //             action: SnackBarAction(label: 'OK', onPressed: () {}),
    //           ),
    //         );

    //         // Cerrar el indicador de progreso y regresar a la pantalla anterior
    //         Navigator.of(context).pop(); // Cerrar el indicador de progreso
    //         Navigator.of(context).pop(); // Regresar a la pantalla anterior
    //       }
    //     } catch (e) {
    //       // Manejar errores
    //       if (mounted) {
    //         Navigator.of(context).pop(); // Cerrar el indicador de progreso
    //         ScaffoldMessenger.of(context).showSnackBar(
    //           SnackBar(
    //             content: Text(
    //               'Error al crear perfil: $e',
    //               style: const TextStyle(color: Colors.white),
    //             ),
    //             backgroundColor: Colors.red,
    //             behavior: SnackBarBehavior.fixed,
    //             action: SnackBarAction(label: 'OK', onPressed: () {}),
    //           ),
    //         );
    //       }
    //     }
    //   }
    // }

Future<void> _createProfile() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();

    // Verificar si la imagen ha sido tomada
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, tome una foto.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
        ),
      );
      return; // No continuar si no hay imagen
    }

    // Mostrar el indicador de progreso
    showDialog(
      context: context,
      barrierDismissible: false, // Evita que se cierre al tocar fuera del cuadro
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Intentar crear el perfil
      await ProfileService().createProfile(
        _profile,
        widget.userId,
        imageFile: _imageFile,
      );

      // Perfil creado exitosamente: actualizar el estado
      if (mounted) {
        context.read<UserProvider>().setProfileCreated(true);

        // Mostrar el SnackBar de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Fue registrado exitosamente.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );

        // Cerrar el indicador de progreso y regresar a la pantalla anterior con éxito
        Navigator.of(context).pop(); // Cerrar el indicador de progreso
        Navigator.of(context).pop(true); // Regresar a la pantalla anterior con éxito
      }
    } catch (e) {
      // Manejar errores
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al crear perfil: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Cerrar el indicador de progreso
      }
    }
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_imageFile != null)
                Card(
                  elevation: 4.0, // Puedes ajustar la elevación de la card
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10.0,
                    ), // Radio de las esquinas
                  ),
                  margin: const EdgeInsets.all(16.0), // Espaciado exterior
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        10.0,
                      ), // Asegura que las esquinas de la imagen coincidan
                      child: Image.file(
                        _imageFile!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su nombre';
                  }
                  return null;
                },
                onSaved: (value) {
                  if (value != null) {
                    _profile = _profile.copyWith(firstName: value);
                  }
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Segundo Nombre'),
                onSaved: (value) {
                  if (value != null) {
                    _profile = _profile.copyWith(middleName: value);
                  }
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su apellido';
                  }
                  return null;
                },
                onSaved: (value) {
                  if (value != null) {
                    _profile = _profile.copyWith(lastName: value);
                  }
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Segundo Apellido',
                ),
                onSaved: (value) {
                  if (value != null) {
                    _profile = _profile.copyWith(secondLastName: value);
                  }
                },
              ),

              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Fecha de Nacimiento',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDate(context),
                  ),
                ),
                readOnly: true,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Seleccione una fecha'
                            : null,
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Estado Civil'),
                items: const [
                  DropdownMenuItem(value: 'married', child: Text('Casado')),
                  DropdownMenuItem(
                    value: 'divorced',
                    child: Text('Divorciado'),
                  ),
                  DropdownMenuItem(value: 'single', child: Text('Soltero')),
                ],
                validator:
                    (value) =>
                        value == null ? 'Seleccione un estado civil' : null,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _profile = _profile.copyWith(maritalStatus: value);
                    });
                  }
                },
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Sexo'),
                items: const [
                  DropdownMenuItem(value: 'F', child: Text('Femenino')),
                  DropdownMenuItem(value: 'M', child: Text('Masculino')),
                ],
                validator:
                    (value) => value == null ? 'Seleccione un sexo' : null,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _profile = _profile.copyWith(sex: value);
                    });
                  }
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),

      floatingActionButton: Stack(
        children: [
          // Botón para capturar foto
          Positioned(
            right: 10,
            bottom: 85, // Separación del botón inferior
            child: FloatingActionButton(
              heroTag: 'profile_photo_fab',
              onPressed: _pickImage,
              backgroundColor: Colors.blue, // Color distintivo
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 20), // Ícono
                  Text(
                    'Foto',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ), // Texto dentro del botón
                ],
              ),
            ),
          ),
          // Botón para guardar perfil
          Positioned(
            right: 10,
            bottom: 11, // Espaciado desde el borde inferior
            child: FloatingActionButton(
              heroTag: 'profile_save_fab',
              onPressed: _createProfile,
              backgroundColor: Colors.green, // Color distintivo
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, size: 20), // Ícono
                  Text(
                    'Guardar',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ), // Texto dentro del botón
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
