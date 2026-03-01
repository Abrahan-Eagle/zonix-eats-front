import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix/features/DomainProfiles/Profiles/models/profile_model.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  final int userId;

  const EditProfilePage({super.key, required this.userId});

  @override
  EditProfilePageState createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  Profile? _profile;
  final TextEditingController _dateController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isDetecting = false;

  // Opciones para el DropdownButtonFormField
  static const maritalStatusOptions = [
    DropdownMenuItem(value: 'married', child: Text('Casado')),
    DropdownMenuItem(value: 'divorced', child: Text('Divorciado')),
    DropdownMenuItem(value: 'single', child: Text('Soltero')),
  ];

  static const sexOptions = [
    DropdownMenuItem(value: 'F', child: Text('Femenino')),
    DropdownMenuItem(value: 'M', child: Text('Masculino')),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      _profile = await ProfileService().getProfileById(widget.userId);
      if (_profile != null) {
        _dateController.text = formatDate(_profile!.dateOfBirth);
        // Solo actualizamos el estado una vez que los datos están listos
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar perfil: $e')),
        );
      }
    }
  }

  String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('dd-MM-yyyy').format(parsedDate);
  }


Future<void> _pickDate(BuildContext context) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
  );

  if (picked != null) {
    // Formateamos la fecha para mostrarla en el formato 'dd-MM-yyyy'
    String displayedDate = DateFormat('dd-MM-yyyy').format(picked);
    _dateController.text = displayedDate; // Mostrar fecha en la interfaz

    // Guardamos la fecha en formato 'yyyy-MM-dd' para la base de datos
    String savedDate = DateFormat('yyyy-MM-dd').format(picked);

    setState(() {
      if (_profile != null) {
        _profile = _profile!.copyWith(dateOfBirth: savedDate); // Guardar en formato adecuado para la DB
      }
    });
  }
}



  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      String? compressedImagePath = await _compressImage(pickedFile.path);
      if (compressedImagePath != null) {
        setState(() {
          _imageFile = File(compressedImagePath);
        });
        await _faceDetect(); // Detectar rostros después de cargar la imagen
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se seleccionó ninguna imagen.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    }
  }

  Future<String?> _compressImage(String filePath) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false, // Impide cerrar el diálogo tocando fuera
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final imageFile = File(filePath);

      if (await imageFile.length() <= 2 * 1024 * 1024) return filePath;

      final originalImage = img.decodeImage(await imageFile.readAsBytes());
      if (originalImage == null) return null;

      List<int> compressedBytes;
      String extension = filePath.split('.').last.toLowerCase();
      int quality = 85;

      if (extension == 'png') {
        compressedBytes = img.encodePng(originalImage, level: 6);
      } else {
        compressedBytes = img.encodeJpg(originalImage, quality: quality);
        while (compressedBytes.length > 2 * 1024 * 1024 && quality > 10) {
          quality -= 5;
          compressedBytes = img.encodeJpg(originalImage, quality: quality);
        }
      }

      final compressedImageFile = await File(
        '${imageFile.parent.path}/compressed_${imageFile.uri.pathSegments.last}',
      ).writeAsBytes(compressedBytes);

      Navigator.of(context).pop();

      return compressedImageFile.path;
    } catch (e) {
      debugPrint("Error al comprimir la imagen: $e");
      return null;
    }
  }

  Future<void> _faceDetect() async {
    if (_imageFile == null || _isDetecting) return;

    setState(() {
      _isDetecting = true;
    });

    try {
      final InputImage inputImage = InputImage.fromFile(_imageFile!);
      final FaceDetector faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableClassification: true,
        ),
      );

      final List<Face> faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        setState(() {
          _imageFile = null; // Borra la imagen si no hay rostro
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No se detectó un rostro. Por favor, asegúrate de que tu cara esté visible.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.fixed,
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rostro identificado correctamente: ${faces.length}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al procesar la imagen: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } finally {
      setState(() {
        _isDetecting = false;
      });
    }
  }

 Future<void> _updateProfile() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();

    // Verificar la fecha antes de enviar la solicitud
    debugPrint("Fecha de nacimiento: ${_profile!.dateOfBirth}");

   

    try {
      // Asegúrate de que la fecha esté en formato yyyy-MM-dd antes de enviarlo
      String formattedDateOfBirth = DateFormat('yyyy-MM-dd').format(DateFormat('dd-MM-yyyy').parse(_profile!.dateOfBirth));

      // Actualizar el perfil con la fecha de nacimiento correctamente formateada
      await ProfileService().updateProfile(_profile!.id, _profile!.copyWith(dateOfBirth: formattedDateOfBirth), imageFile: _imageFile);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Perfil actualizado exitosamente.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.fixed,
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
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
    }
  }
}

  @override
  Widget build(BuildContext context) {
    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_imageFile != null)
                Card(
                  elevation: 4.0,  // Puedes ajustar la elevación de la card
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Radio de las esquinas
                  ),
                  margin: const EdgeInsets.all(16.0), // Espaciado exterior
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0), // Asegura que las esquinas de la imagen coincidan
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
                initialValue: _profile!.firstName,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value == null || value.isEmpty ? 'Ingrese su nombre' : null,
                onSaved: (value) {
                  if (value != null) {
                    _profile = _profile!.copyWith(firstName: value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _profile!.middleName,
                decoration: const InputDecoration(labelText: 'Segundo Nombre'),
                onSaved: (value) {
                  if (value != null) {
                    _profile = _profile!.copyWith(middleName: value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _profile!.lastName,
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: (value) => value == null || value.isEmpty ? 'Ingrese su apellido' : null,
                onSaved: (value) {
                  if (value != null) {
                    _profile = _profile!.copyWith(lastName: value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _profile!.secondLastName,
                decoration: const InputDecoration(labelText: 'Segundo Apellido'),
                onSaved: (value) {
                  if (value != null) {
                    _profile = _profile!.copyWith(secondLastName: value);
                  }
                },
              ),
              const SizedBox(height: 16),
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
                validator: (value) => value == null || value.isEmpty ? 'Seleccione una fecha de nacimiento' : null,
                onSaved: (value) {
                  if (value != null) {
                    _profile = _profile!.copyWith(dateOfBirth: value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _profile!.maritalStatus,
                decoration: const InputDecoration(labelText: 'Estado Civil'),
                items: maritalStatusOptions,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _profile = _profile!.copyWith(maritalStatus: value);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _profile!.sex,
                decoration: const InputDecoration(labelText: 'Sexo'),
                items: sexOptions,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _profile = _profile!.copyWith(sex: value);
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
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
              onPressed: _pickImage,
              backgroundColor: Colors.blue, // Color distintivo
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children:  [
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
              onPressed: _updateProfile,
              backgroundColor: Colors.green, // Color distintivo
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children:  [
                  Icon(Icons.save, size: 20), // Ícono
                  Text(
                    'Actualizar',
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








// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
// import 'package:zonix/features/DomainProfiles/Profiles/models/profile_model.dart';
// import 'package:image/image.dart' as img;
// import 'package:intl/intl.dart';

// class EditProfilePage extends StatefulWidget {
//   final int userId;

//   const EditProfilePage({super.key, required this.userId});

//   @override
//   EditProfilePageState createState() => EditProfilePageState();
// }

// class EditProfilePageState extends State<EditProfilePage> {
//   final _formKey = GlobalKey<FormState>();
//   Profile? _profile;
//   final TextEditingController _dateController = TextEditingController();
//   File? _imageFile;
//   final ImagePicker _picker = ImagePicker();
//   String _mlResult = 'No se han detectado rostros.';
//   bool _isDetecting = false;

//   // Opciones para el DropdownButtonFormField
//   static const maritalStatusOptions = [
//     DropdownMenuItem(value: 'married', child: Text('Casado')),
//     DropdownMenuItem(value: 'divorced', child: Text('Divorciado')),
//     DropdownMenuItem(value: 'single', child: Text('Soltero')),
//   ];

//   static const sexOptions = [
//     DropdownMenuItem(value: 'F', child: Text('Femenino')),
//     DropdownMenuItem(value: 'M', child: Text('Masculino')),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadProfile();
//   }

//  Future<void> _loadProfile() async {
//   try {
//     _profile = await ProfileService().getProfileById(widget.userId);
//     if (_profile != null) {
//       _dateController.text = formatDate(_profile!.dateOfBirth);
//       // Solo actualizamos el estado una vez que los datos están listos
//       if (mounted) {
//         setState(() {});
//       }
//     }
//   } catch (e) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error al cargar perfil: $e')),
//       );
//     }
//   }
// }

//   String formatDate(String date) {
//     DateTime parsedDate = DateTime.parse(date);
//     return DateFormat('dd-MM-yyyy').format(parsedDate);
//   }

//   Future<void> _pickDate(BuildContext context) async {
//   final picked = await showDatePicker(
//     context: context,
//     initialDate: DateTime.now(),
//     firstDate: DateTime(1900),
//     lastDate: DateTime.now(),
//   );

//   if (picked != null) {
//     // Formateamos la fecha para mostrarla en el formato 'dd-MM-yyyy'
//     String displayedDate = DateFormat('dd-MM-yyyy').format(picked);
//     _dateController.text = displayedDate; // Mostrar fecha en la interfaz

//     // Guardar la fecha en el formato 'yyyy-MM-dd' para la base de datos
//     String savedDate = DateFormat('yyyy-MM-dd').format(picked);

//     setState(() {
//     _profile = _profile?.copyWith(dateOfBirth: savedDate); // Usar el operador ?. para asegurar que no sea nulo

//     });
//   }
// }

//   Future<void> _pickImage() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.camera);
//     if (pickedFile != null) {
//       String? compressedImagePath = await _compressImage(pickedFile.path);
//       if (compressedImagePath != null) {
//         setState(() {
//           _imageFile = File(compressedImagePath);
//         });
//         await _faceDetect(); // Detectar rostros después de cargar la imagen
//       }
//     } else {
//     ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('No se seleccionó ninguna imagen.'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.fixed,
//           action: SnackBarAction(label: 'OK', onPressed: () {}),
//         ),
//       );
//     }
//   }

//   Future<String?> _compressImage(String filePath) async {
//     try {

//       showDialog(
//         context: context,
//         barrierDismissible: false, // Impide cerrar el diálogo tocando fuera
//         builder: (BuildContext context) {
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         },
//       );

//       final imageFile = File(filePath);

//       if (await imageFile.length() <= 2 * 1024 * 1024) return filePath;

//       final originalImage = img.decodeImage(await imageFile.readAsBytes());
//       if (originalImage == null) return null;

//       List<int> compressedBytes;
//       String extension = filePath.split('.').last.toLowerCase();
//       int quality = 85;

//       if (extension == 'png') {
//         compressedBytes = img.encodePng(originalImage, level: 6);
//       } else {
//         compressedBytes = img.encodeJpg(originalImage, quality: quality);
//         while (compressedBytes.length > 2 * 1024 * 1024 && quality > 10) {
//           quality -= 5;
//           compressedBytes = img.encodeJpg(originalImage, quality: quality);
//         }
//       }

//       final compressedImageFile = await File(
//         '${imageFile.parent.path}/compressed_${imageFile.uri.pathSegments.last}',
//       ).writeAsBytes(compressedBytes);

//      Navigator.of(context).pop();  

//       return compressedImageFile.path;
//     } catch (e) {
//       debugPrint("Error al comprimir la imagen: $e");
//       return null;
//     }
//   }

//   Future<void> _faceDetect() async {
//     if (_imageFile == null || _isDetecting) return;

//     setState(() {
//       _isDetecting = true;
//     });

//     try {
//       final InputImage inputImage = InputImage.fromFile(_imageFile!);
//       final FaceDetector faceDetector = FaceDetector(
//         options: FaceDetectorOptions(
//           enableLandmarks: true,
//           enableClassification: true,
//         ),
//       );

//       final List<Face> faces = await faceDetector.processImage(inputImage);

//       if (faces.isEmpty) {
//         setState(() {
//          _imageFile = null; // Borra la imagen si no hay rostro
//         });

//          ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text(
//               'No se detectó un rostro. Por favor, asegúrate de que tu cara esté visible.',
//               style: TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.orange,
//             behavior: SnackBarBehavior.fixed,
//             action: SnackBarAction(label: 'OK', onPressed: () {}),
//           ),
//         );

      
//       } else {

//            ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Rostro identificado correctamente: ${faces.length}',
//               style: const TextStyle(color: Colors.white),
//             ),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.fixed,
//             action: SnackBarAction(label: 'OK', onPressed: () {}),
//           ),
//         );

//       }
//     } catch (e) {
//        ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Error al procesar la imagen: $e',
//             style: const TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.fixed,
//           action: SnackBarAction(label: 'OK', onPressed: () {}),
//         ),
//       );
//     } finally {
//       setState(() {
//         _isDetecting = false;
//       });
//     }
//   }

//   Future<void> _updateProfile() async {
//     if (_formKey.currentState!.validate()) {
//       _formKey.currentState!.save();

//  // Verificar si la imagen ha sido tomada
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

//       try {
//         await ProfileService().updateProfile(_profile!.id,_profile!,imageFile: _imageFile);

//        ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text(
//             'Perfil actualizado exitosamente.',
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.fixed,
//           action: SnackBarAction(
//             label: 'OK', 
//             onPressed: () {},
//           ),
//         ),
//       );

//         if (mounted) Navigator.pop(context);
//       } catch (e) {
//        if (mounted) {
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
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_profile == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Editar Perfil')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text('Editar Perfil')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [


// if (_imageFile != null)
//   Card(
//     elevation: 4.0,  // Puedes ajustar la elevación de la card
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(10.0), // Radio de las esquinas
//     ),
//     margin: const EdgeInsets.all(16.0), // Espaciado exterior
//     child: AspectRatio(
//       aspectRatio: 16 / 10,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(10.0), // Asegura que las esquinas de la imagen coincidan
//         child: Image.file(
//           _imageFile!,
//           width: double.infinity,
//           fit: BoxFit.cover,
//         ),
//       ),
//     ),
//   ),


//               const SizedBox(height: 16),


//               TextFormField(
//                 initialValue: _profile!.firstName,
//                 decoration: const InputDecoration(labelText: 'Nombre'),
//                 validator: (value) => value == null || value.isEmpty ? 'Ingrese su nombre' : null,
//                 onSaved: (value) {
//                   if (value != null) {
//                     _profile = _profile!.copyWith(firstName: value);
//                   }
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 initialValue: _profile!.middleName,
//                 decoration: const InputDecoration(labelText: 'Segundo Nombre'),
//                 onSaved: (value) {
//                   if (value != null) {
//                     _profile = _profile!.copyWith(middleName: value);
//                   }
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 initialValue: _profile!.lastName,
//                 decoration: const InputDecoration(labelText: 'Apellido'),
//                 validator: (value) => value == null || value.isEmpty ? 'Ingrese su apellido' : null,
//                 onSaved: (value) {
//                   if (value != null) {
//                     _profile = _profile!.copyWith(lastName: value);
//                   }
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 initialValue: _profile!.secondLastName,
//                 decoration: const InputDecoration(labelText: 'Segundo Apellido'),
//                 onSaved: (value) {
//                   if (value != null) {
//                     _profile = _profile!.copyWith(secondLastName: value);
//                   }
//                 },
//               ),
       
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _dateController,
//                 decoration: InputDecoration(
//                   labelText: 'Fecha de Nacimiento',
//                   suffixIcon: IconButton(
//                     icon: const Icon(Icons.calendar_today),
//                     onPressed: () => _pickDate(context),
//                   ),
//                 ),
//                 readOnly: true,
//                 validator: (value) => value == null || value.isEmpty ? 'Seleccione una fecha de nacimiento' : null,
//                 onSaved: (value) {
//                   if (value != null) {
//                     _profile = _profile!.copyWith(dateOfBirth: value);
//                   }
//                 },
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: _profile!.maritalStatus,
//                 decoration: const InputDecoration(labelText: 'Estado Civil'),
//                 items: maritalStatusOptions,
//                 onChanged: (value) {
//                   if (value != null) {
//                     setState(() {
//                       _profile = _profile!.copyWith(maritalStatus: value);
//                     });
//                   }
//                 },
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: _profile!.sex,
//                 decoration: const InputDecoration(labelText: 'Sexo'),
//                 items: sexOptions,
//                 onChanged: (value) {
//                   if (value != null) {
//                     setState(() {
//                       _profile = _profile!.copyWith(sex: value);
//                     });
//                   }
//                 },
//               ),
//               const SizedBox(height: 32),
         
//             ],
//           ),
//         ),
//       ),




// floatingActionButton: Stack(
//   children: [
//     // Botón para capturar foto
//     Positioned(
//       right: 10,
//       bottom: 85, // Separación del botón inferior
//       child: FloatingActionButton(
//         onPressed: _pickImage,
//         backgroundColor: Colors.blue, // Color distintivo
//         child: const Column(
//           mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children:  [
//             Icon(Icons.camera_alt, size: 20), // Ícono
//             Text(
//               'Foto',
//               style: TextStyle(fontSize: 10, color: Colors.white),
//             ), // Texto dentro del botón
//           ],
//         ),
//       ),
//     ),
//     // Botón para guardar perfil
//     Positioned(
//       right: 10,
//       bottom: 11, // Espaciado desde el borde inferior
//       child: FloatingActionButton(
//         onPressed: _updateProfile,
//         backgroundColor: Colors.green, // Color distintivo
//         child: const Column(
//           mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children:  [
//             Icon(Icons.save, size: 20), // Ícono
//             Text(
//               'Actualizar',
//               style: TextStyle(fontSize: 10, color: Colors.white),
//             ), // Texto dentro del botón
//           ],
//         ),
//       ),
//     ),
//   ],
// ),



//     );
//   }
// }


// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// // import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
// // import 'package:zonix/features/DomainProfiles/Profiles/models/profile_model.dart';
// // import 'package:image/image.dart' as img;

// // class EditProfilePage extends StatefulWidget {
// //   final int userId;

// //   const EditProfilePage({super.key, required this.userId});

// //   @override
// //   EditProfilePageState createState() => EditProfilePageState();
// // }

// // class EditProfilePageState extends State<EditProfilePage> {
// //   final _formKey = GlobalKey<FormState>();
// //   Profile? _profile;
// //   final TextEditingController _dateController = TextEditingController();
// //   File? _imageFile;
// //   final ImagePicker _picker = ImagePicker();
// //   String _mlResult = 'No se han detectado rostros.';
// //   bool _isDetecting = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadProfile();
// //   }

// //   Future<void> _loadProfile() async {
// //     try {
// //       _profile = await ProfileService().getProfileById(widget.userId);
// //       if (_profile != null) {
// //         _dateController.text = _profile!.dateOfBirth;
// //         setState(() {});
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error al cargar perfil: $e')),
// //       );
// //     }
// //   }

// //   Future<void> _pickDate(BuildContext context) async {
// //     final picked = await showDatePicker(
// //       context: context,
// //       initialDate: DateTime.now(),
// //       firstDate: DateTime(1900),
// //       lastDate: DateTime.now(),
// //     );

// //     if (picked != null) {
// //       _dateController.text = picked.toIso8601String().substring(0, 10);
// //       setState(() {
// //         _profile = _profile!.copyWith(dateOfBirth: _dateController.text);
// //       });
// //     }
// //   }

// //   Future<void> _pickImage() async {
// //     final pickedFile = await _picker.pickImage(source: ImageSource.camera);
// //     if (pickedFile != null) {
// //       String? compressedImagePath = await _compressImage(pickedFile.path);
// //       if (compressedImagePath != null) {
// //         setState(() {
// //           _imageFile = File(compressedImagePath);
// //         });
// //         await _faceDetect(); // Detectar rostros después de cargar la imagen
// //       }
// //     } else {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('No se seleccionó ninguna imagen.')),
// //       );
// //     }
// //   }

// //   Future<String?> _compressImage(String filePath) async {
// //     try {
// //       final imageFile = File(filePath);

// //       if (await imageFile.length() <= 2 * 1024 * 1024) return filePath;

// //       final originalImage = img.decodeImage(await imageFile.readAsBytes());
// //       if (originalImage == null) return null;

// //       List<int> compressedBytes;
// //       String extension = filePath.split('.').last.toLowerCase();
// //       int quality = 85;

// //       if (extension == 'png') {
// //         compressedBytes = img.encodePng(originalImage, level: 6);
// //       } else {
// //         compressedBytes = img.encodeJpg(originalImage, quality: quality);
// //         while (compressedBytes.length > 2 * 1024 * 1024 && quality > 10) {
// //           quality -= 5;
// //           compressedBytes = img.encodeJpg(originalImage, quality: quality);
// //         }
// //       }

// //       final compressedImageFile = await File(
// //         '${imageFile.parent.path}/compressed_${imageFile.uri.pathSegments.last}',
// //       ).writeAsBytes(compressedBytes);

// //       return compressedImageFile.path;
// //     } catch (e) {
// //       debugPrint("Error al comprimir la imagen: $e");
// //       return null;
// //     }
// //   }


// //   Future<void> _faceDetect() async {
// //   if (_imageFile == null || _isDetecting) return;

// //   setState(() {
// //     _isDetecting = true;
// //     _mlResult = 'Detectando rostros...';
// //   });

// //   try {
// //     final InputImage inputImage = InputImage.fromFile(_imageFile!);
// //     final FaceDetector faceDetector = FaceDetector(
// //       options: FaceDetectorOptions(
// //         enableLandmarks: true,
// //         enableClassification: true,
// //       ),
// //     );

// //     final List<Face> faces = await faceDetector.processImage(inputImage);

// //     if (faces.isEmpty) {
// //       setState(() {
// //         _mlResult = 'No se detectó ningún rostro. Por favor, muestra tu cara.';
// //         _imageFile = null; // Borra la imagen si no hay rostro
// //       });

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text('No se detectó un rostro. Por favor, asegúrate de que tu cara esté visible.'),
// //         ),
// //       );
// //     } else {
// //       setState(() {
// //         _mlResult = 'Rostro(s) detectado(s): ${faces.length}';
// //       });
// //     }
// //   } catch (e) {
// //     setState(() {
// //       _mlResult = 'Error al detectar rostros: $e';
// //     });
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text('Error al procesar la imagen: $e')),
// //     );
// //   } finally {
// //     setState(() {
// //       _isDetecting = false;
// //     });
// //   }
// // }


// //   Future<void> _updateProfile() async {
// //     if (_formKey.currentState!.validate()) {
// //       _formKey.currentState!.save();
// //       try {
// //         await ProfileService().updateProfile(
// //           _profile!.id,
// //           _profile!,
// //           imageFile: _imageFile,
// //         );

// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('Perfil actualizado exitosamente.')),
// //         );

// //         if (mounted) Navigator.pop(context);
// //       } catch (e) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Error al actualizar perfil: $e')),
// //         );
// //       }
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (_profile == null) {
// //       return Scaffold(
// //         appBar: AppBar(title: const Text('Editar Perfil')),
// //         body: const Center(child: CircularProgressIndicator()),
// //       );
// //     }

// //     return Scaffold(
// //       appBar: AppBar(title: const Text('Editar Perfil')),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Form(
// //           key: _formKey,
// //           child: Column(
// //             children: [
// //               TextFormField(
// //                 initialValue: _profile!.firstName,
// //                 decoration: const InputDecoration(labelText: 'Nombre'),
// //                 validator: (value) => value == null || value.isEmpty ? 'Ingrese su nombre' : null,
// //                 onSaved: (value) {
// //                   if (value != null) {
// //                     _profile = _profile!.copyWith(firstName: value);
// //                   }
// //                 },
// //               ),
// //               const SizedBox(height: 16),
// //               TextFormField(
// //                 initialValue: _profile!.middleName,
// //                 decoration: const InputDecoration(labelText: 'Segundo Nombre'),
// //                 onSaved: (value) {
// //                   if (value != null) {
// //                     _profile = _profile!.copyWith(middleName: value);
// //                   }
// //                 },
// //               ),
// //               const SizedBox(height: 16),
// //               TextFormField(
// //                 initialValue: _profile!.lastName,
// //                 decoration: const InputDecoration(labelText: 'Apellido'),
// //                 validator: (value) => value == null || value.isEmpty ? 'Ingrese su apellido' : null,
// //                 onSaved: (value) {
// //                   if (value != null) {
// //                     _profile = _profile!.copyWith(lastName: value);
// //                   }
// //                 },
// //               ),
// //               const SizedBox(height: 16),
// //               TextFormField(
// //                 initialValue: _profile!.secondLastName,
// //                 decoration: const InputDecoration(labelText: 'Segundo Apellido'),
// //                 onSaved: (value) {
// //                   if (value != null) {
// //                     _profile = _profile!.copyWith(secondLastName: value);
// //                   }
// //                 },
// //               ),
       
// //               const SizedBox(height: 16),
// //               ElevatedButton(
// //                 onPressed: _pickImage,
// //                 child: const Text('Tomar Foto'),
// //               ),
// //               if (_imageFile != null) ...[
// //                 const SizedBox(height: 16),
// //                 Image.file(_imageFile!, height: 150),
// //                 const SizedBox(height: 16),
// //                 Text(_mlResult),
// //               ],
             
// //              const SizedBox(height: 16),
// //               TextFormField(
// //                 controller: _dateController,
// //                 decoration: InputDecoration(
// //                   labelText: 'Fecha de Nacimiento',
// //                   suffixIcon: IconButton(
// //                     icon: const Icon(Icons.calendar_today),
// //                     onPressed: () => _pickDate(context),
// //                   ),
// //                 ),
// //                 readOnly: true,
// //                 validator: (value) => value == null || value.isEmpty ? 'Seleccione una fecha' : null,
// //               ),
// //               const SizedBox(height: 16),
// //               DropdownButtonFormField<String>(
// //                 value: _profile!.maritalStatus,
// //                 decoration: const InputDecoration(labelText: 'Estado Civil'),
// //                 items: const [
// //                   DropdownMenuItem(value: 'married', child: Text('Casado')),
// //                   DropdownMenuItem(value: 'divorced', child: Text('Divorciado')),
// //                   DropdownMenuItem(value: 'single', child: Text('Soltero')),
// //                 ],
// //                 onChanged: (value) {
// //                   setState(() {
// //                     _profile = _profile!.copyWith(maritalStatus: value);
// //                   });
// //                 },
// //               ),
// //               const SizedBox(height: 16),
// //               DropdownButtonFormField<String>(
// //                 value: _profile!.sex,
// //                 decoration: const InputDecoration(labelText: 'Sexo'),
// //                 items: const [
// //                   DropdownMenuItem(value: 'F', child: Text('Femenino')),
// //                   DropdownMenuItem(value: 'M', child: Text('Masculino')),
// //                 ],
// //                 onChanged: (value) {
// //                   setState(() {
// //                     _profile = _profile!.copyWith(sex: value);
// //                   });
// //                 },
// //               ),
// //               const SizedBox(height: 24),
             
// //               ElevatedButton(
// //                 onPressed: _updateProfile,
// //                 child: const Text('Actualizar Perfil'),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
