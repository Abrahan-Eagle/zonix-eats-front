import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zonix/features/DomainProfiles/GasCylinder/api/gas_cylinder_service.dart';
import 'package:zonix/features/DomainProfiles/GasCylinder/models/gas_cylinder.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
class CreateGasCylinderScreen extends StatefulWidget {
  final int userId;

  const CreateGasCylinderScreen({super.key, required this.userId});

  @override
  CreateGasCylinderScreenState createState() => CreateGasCylinderScreenState();
}

class CreateGasCylinderScreenState extends State<CreateGasCylinderScreen> {
  final _formKey = GlobalKey<FormState>();
  final GasCylinderService _supplierService = GasCylinderService();

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedCylinderType;
  String? _selectedCylinderWeight;
  DateTime? _manufacturingDate;
  File? _imageFile;

  int? _selectedSupplierId;
  List<Map<String, dynamic>> _gasSuppliers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGasSuppliers();
  }

  Future<void> _loadGasSuppliers() async {
    try {
      final suppliers = await _supplierService.getGasSuppliers();
      setState(() {
        _gasSuppliers = suppliers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando proveedores: $e')),
      );
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _manufacturingDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _manufacturingDate = picked;
        _dateController.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

   Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final compressedFile = await _compressImage(pickedFile.path);

      if (compressedFile != null) {
        setState(() {
          _imageFile = File(compressedFile);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al comprimir la imagen.')),
        );
      }
    }
  }

  Future<String?> _compressImage(String filePath) async {
    try {
      final imageFile = File(filePath);

      // Verificar si la imagen ya es menor a 2 MB
      if (await imageFile.length() <= 2 * 1024 * 1024) {
        return filePath; // Devolver la misma imagen si no necesita compresión
      }

      final originalImage = img.decodeImage(await imageFile.readAsBytes());
      if (originalImage == null) {
        debugPrint("No se pudo decodificar la imagen.");
        return null; // Si no se puede decodificar, devuelve null
      }

      String extension = filePath.split('.').last.toLowerCase();
      int quality = 85; // Calidad inicial
      List<int> compressedBytes;

      if (extension == 'png') {
        // Compresión para PNG
        compressedBytes = img.encodePng(originalImage, level: 6);
      } else {
        // Compresión para JPG
        compressedBytes = img.encodeJpg(originalImage, quality: quality);

        // Reducir calidad iterativamente si es mayor a 2 MB
        while (compressedBytes.length > 2 * 1024 * 1024 && quality > 10) {
          quality -= 5;
          compressedBytes = img.encodeJpg(originalImage, quality: quality);
        }
      }

      // Guardar la imagen comprimida
      final compressedImageFile = await File(
        '${imageFile.parent.path}/compressed_${imageFile.uri.pathSegments.last}',
      ).writeAsBytes(compressedBytes);

      debugPrint("Imagen comprimida guardada en: ${compressedImageFile.path}");
      return compressedImageFile.path;

    } catch (e) {
      debugPrint("Error al comprimir la imagen: $e");
      return null;
    }
  }




  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Bombona')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(labelText: 'Código bombona'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'El código es obligatorio';
                        if (double.tryParse(value) == null) return 'El código debe ser un número';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Selecciona compañía de bombona'),
                      value: _selectedSupplierId,
                      items: _gasSuppliers.map((supplier) {
                        return DropdownMenuItem<int>(
                          value: supplier['id'],
                          child: Text(supplier['name']),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedSupplierId = value),
                      validator: (value) =>
                          value == null ? 'Por favor, selecciona una compañía' : null,
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt), // Ícono de cámara
                      label: const Text('Capturar Bombona'),
                    ),

               
                    const SizedBox(height: 16),

                    if (_imageFile != null)
                      Image.file(
                        _imageFile!,
                        height: width * 0.5,
                        width: width * 0.5,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Tipo de Bombona'),
                      items: const [
                        DropdownMenuItem(value: 'small', child: Text('Boca Pequeña')),
                        DropdownMenuItem(value: 'wide', child: Text('Boca Ancha')),
                      ],
                      onChanged: (value) => setState(() => _selectedCylinderType = value),
                      validator: (value) => value == null ? 'Seleccione un tipo' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Peso de Bombona'),
                      items: const [
                        DropdownMenuItem(value: '10kg', child: Text('10kg')),
                        // DropdownMenuItem(value: '18kg', child: Text('18kg')),
                        // DropdownMenuItem(value: '45kg', child: Text('45kg')),
                      ],
                      onChanged: (value) => setState(() => _selectedCylinderWeight = value),
                      validator: (value) => value == null ? 'Seleccione un peso' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(labelText: 'Fecha de Fabricación'),
                      readOnly: true,
                      onTap: () => _pickDate(context),
                      validator: (value) =>
                          _manufacturingDate == null ? 'Seleccione una fecha' : null,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

      

                floatingActionButton: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8, // 80% del ancho de la pantalla
                      child: FloatingActionButton.extended(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Crear un nuevo objeto de bombona
                            final newCylinder = GasCylinder(
                              gasCylinderCode: _codeController.text,
                              cylinderType: _selectedCylinderType,
                              cylinderWeight: _selectedCylinderWeight,
                              manufacturingDate: _manufacturingDate,
                              companySupplierId: _selectedSupplierId,
                            );

                            // Mostrar el indicador de progreso
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return const Center(child: CircularProgressIndicator());
                              },
                            );

                            try {
                              // Intentar crear la bombona
                              await _supplierService.createGasCylinder(
                                newCylinder,
                                widget.userId,
                                imageFile: _imageFile,
                              );

                              // Bombona creada exitosamente
                              if (mounted) {
                                Provider.of<UserProvider>(context, listen: false)
                                    .setGasCylindersCreated(true);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Bombona creada con éxito')),
                                );

                                Navigator.of(context).pop(true); // Notificar éxito
                              }
                            } catch (e) {
                              // Manejar errores
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            } finally {
                              // Asegurarse de cerrar el diálogo
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            }
                          }
                        },
                        tooltip: 'Crear Bombona',
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Bombona'),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],
                ),


      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
