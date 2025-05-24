import 'package:flutter/material.dart';
import '../models/adresse.dart';
import '../models/models.dart';
import '../api/adresse_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'location_module.dart'; // Importa el módulo de ubicación
import 'package:geolocator/geolocator.dart'; // Importa la clase Position
import 'package:zonix_eats/features/utils/user_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';


final logger = Logger();
class RegisterAddressScreen extends StatefulWidget {
  final int userId;

  const RegisterAddressScreen({super.key, required this.userId});

  @override
  RegisterAddressScreenState createState() => RegisterAddressScreenState();
}

class RegisterAddressScreenState extends State<RegisterAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final AddressService _addressService = AddressService();
  final LocationModule _locationModule = LocationModule();

  List<Country> countries = [];
  List<StateModel> states = [];
  List<City> cities = [];
  Country? selectedCountry;
  StateModel? selectedState;
  City? selectedCity;

  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    logger.i('Console log para verificar el userId al inicio...... Recibiendo userId: ${widget.userId}'); // Console log para verificar el userId al inicio
    loadCountries();
    _captureLocation(); // Captura la ubicación automáticamente al iniciar
  }

  @override
  void dispose() {
    _streetController.dispose();
    _houseNumberController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }


Future<void> loadCountries() async {
  try {
    final data = await _addressService.fetchCountries();
    setState(() {
      countries = data;
    });

    if (countries.isNotEmpty) {
      // Seleccionar el país predeterminado (por ejemplo, el primer país o uno específico)
      final defaultCountry = countries.firstWhere(
        (country) => country.name == "Venezuela",
        orElse: () => countries.first, // Si no encuentra "Venezuela", usa el primer país
      );

      setState(() {
        selectedCountry = defaultCountry;
      });

      // Cargar los estados del país seleccionado automáticamente
      await loadStates(defaultCountry.id);
    }
  } catch (e) {
    _showError('Error al cargar países: $e');
  }
}



  Future<void> loadStates(int countryId) async {
    try {
      final data = await _addressService.fetchStates(countryId);
      setState(() {
        states = data;
        selectedState = null;
        selectedCity = null;
        cities.clear();
      });
    } catch (e) {
      _showError('Error al cargar estados: $e');
    }
  }

  Future<void> loadCities(int stateId) async {
    try {
      final data = await _addressService.fetchCitiesByState(stateId);
      setState(() {
        cities = data;
        selectedCity = null;
      });
    } catch (e) {
      _showError('Error al cargar ciudades: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _captureLocation() async {
    Position? position = await _locationModule.getCurrentLocation(context);
    if (position != null) {
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    } else {
      _showError('No se pudo capturar la ubicación.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('Registrar Dirección'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Registra tu nueva dirección aquí:',
              style: TextStyle(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            SvgPicture.asset(
              'assets/images/undraw_mention_re_k5xc.svg',
              height: MediaQuery.of(context).size.height * 0.2,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24.0),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildCountryDropdown(),
                  const SizedBox(height: 16.0),
                  if (selectedCountry != null) _buildStateDropdown(),
                  const SizedBox(height: 16.0),
                  if (selectedState != null) _buildCityDropdown(),
                  const SizedBox(height: 16.0),
                  // _buildTextField(_streetController, 'Dirección', 'Por favor ingresa la Dirección'),

                  _buildTextField(_streetController, 'Dirección', 'Por favor ingresa la Dirección', minLength: 10, maxLength: 100, ),

                  const SizedBox(height: 16.0),
                  // _buildTextField(_houseNumberController, 'N° casa', 'Por favor ingresa el número de la casa'),

                  _buildTextField(_houseNumberController, 'N° casa', 'Por favor ingresa el número de la casa', minLength: 1, maxLength: 10, ),

                  const SizedBox(height: 16.0),
                  _buildPostalCodeField(),
                  const SizedBox(height: 200.0),
           
                ],
              ),
            ),
          ],
        ),
      ),
    // Aquí es donde se coloca el FloatingActionButton
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min, // Minimiza el espacio ocupado por la columna
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8, // 80% del ancho de la pantalla
            child: FloatingActionButton.extended(
              onPressed: _createAddress, // Tu función para registrar la dirección
              tooltip: 'Registrar Dirección',
              icon: const Icon(Icons.add_location_alt), // Icono para registrar dirección
              label: const Text('Registrar Dirección'),
            ),
          ),
          const SizedBox(height: 16.0), // Espaciador
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Ubicación del botón flotante
    );
  }

  DropdownButtonFormField<Country> _buildCountryDropdown() {
    return DropdownButtonFormField<Country>(
      hint: const Text('Selecciona el país'),
      value: selectedCountry,
      items: countries.map((country) {
        return DropdownMenuItem(
          value: country,
          child: Text(country.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedCountry = value;
          selectedState = null;
          selectedCity = null;
          states.clear();
          cities.clear();
        });
        if (value != null) {
          loadStates(value.id);
        }
      },
      validator: (value) => value == null ? 'Por favor selecciona el país' : null,
    );
  }

  DropdownButtonFormField<StateModel> _buildStateDropdown() {
    return DropdownButtonFormField<StateModel>(
      hint: const Text('Selecciona el estado'),
      value: selectedState,
      items: states.map((state) {
        return DropdownMenuItem(
          value: state,
          child: Text(state.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedState = value;
          selectedCity = null;
          cities.clear();
        });
        if (value != null) {
          loadCities(value.id);
        }
      },
      validator: (value) => value == null ? 'Por favor selecciona el estado' : null,
    );
  }

  DropdownButtonFormField<City> _buildCityDropdown() {
    return DropdownButtonFormField<City>(
      hint: const Text('Selecciona la ciudad'),
      value: selectedCity,
      items: cities.map((city) {
        return DropdownMenuItem(
          value: city,
          child: Text(city.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedCity = value;
        });
      },
      validator: (value) => value == null ? 'Por favor selecciona la ciudad' : null,
    );
  }

  // TextFormField _buildPostalCodeField() {
  //   return TextFormField(
  //     controller: _postalCodeController,
  //     keyboardType: TextInputType.number,
  //     decoration: const InputDecoration(
  //       labelText: 'Cód. Postal',
  //       border: OutlineInputBorder(),
  //     ),
  //     validator: (value) {
  //       if (value == null || value.isEmpty) {
  //         return 'Por favor ingresa el código postal';
  //       }
  //       return null;
  //     },
  //   );
  // }


// TextFormField _buildPostalCodeField() {
//   return TextFormField(
//     controller: _postalCodeController,
//     keyboardType: TextInputType.number,
//     decoration: const InputDecoration(
//       labelText: 'Cód. Postal',
//       border: OutlineInputBorder(),
//     ),
//     inputFormatters: [
//       LengthLimitingTextInputFormatter(5), // Limita a 5 caracteres.
//       FilteringTextInputFormatter.digitsOnly, // Solo permite números.
//     ],
//     validator: (value) {
//       if (value == null || value.isEmpty) {
//         return 'Por favor ingresa el código postal';
//       }
//       if (value.length != 5) { // Valida exactamente 5 caracteres.
//         return 'El código postal debe tener 5 dígitos';
//       }
//       return null;
//     },
//   );
// }

TextFormField _buildPostalCodeField() {
  return TextFormField(
    controller: _postalCodeController,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
      labelText: 'Cód. Postal',
      border: OutlineInputBorder(),
    ),
    inputFormatters: [
      LengthLimitingTextInputFormatter(5), // Limita a 5 caracteres.
      FilteringTextInputFormatter.digitsOnly, // Solo permite números.
    ],
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Por favor ingresa el código postal';
      }
      if (value.length < 4 || value.length > 5) { // Valida entre 4 y 5 caracteres.
        return 'El código postal debe tener entre 4 y 5 dígitos';
      }
      return null;
    },
  );
}


  // TextFormField _buildTextField(TextEditingController controller, String label, String errorMessage) {
  //   return TextFormField(
  //     controller: controller,
  //     decoration: InputDecoration(
  //       labelText: label,
  //       border: const OutlineInputBorder(),
  //     ),
  //     validator: (value) {
  //       if (value == null || value.isEmpty) {
  //         return errorMessage;
  //       }
  //       return null;
  //     },
  //   );
  // }


  TextFormField _buildTextField(TextEditingController controller, String label, String errorMessage, {int? minLength, int? maxLength}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    inputFormatters: [
      if (maxLength != null) LengthLimitingTextInputFormatter(maxLength), // Limita el número máximo de caracteres
    ],
    validator: (value) {
      if (value == null || value.isEmpty) {
        return errorMessage;
      }
      if (minLength != null && value.length < minLength) {
        return 'Debe tener al menos $minLength caracteres';
      }
      if (maxLength != null && value.length > maxLength) {
        return 'No puede tener más de $maxLength caracteres';
      }
      return null;
    },
  );
}


  // Future<void> _createAddress() async {

  //   // Verifica si las coordenadas están disponibles antes de continuar
  //   if (latitude == null || longitude == null) {
  //     _showError('Por favor permite acceder a tu ubicación antes de continuar. Asegúrate de activar el GPS.');
  //     _captureLocation(); // Captura la ubicación automáticamente al iniciar
  //     return; // Detiene el proceso si la ubicación no está disponible
  //   }


  //   if (_formKey.currentState!.validate() && selectedCity != null) {
  //     double lat = latitude ?? 0.0;
  //     double lon = longitude ?? 0.0;
  //     String status = "activo";
      
      
  //     logger.i('Transformando userId (${widget.userId}) a profileId'); // Console log antes de usar profileId
  //     final address = Address(
  //       id: 0,
  //       profileId: widget.userId,
  //       street: _streetController.text,
  //       houseNumber: _houseNumberController.text,
  //       cityId: selectedCity!.id,
  //       postalCode: _postalCodeController.text,
  //       latitude: lat,
  //       longitude: lon,
  //       status: status,
  //     );

  //     try {
  //       await _addressService.createAddress(address, widget.userId);
        
        
  //       if (mounted) { // Verifica si el widget aún está montado
  //         Provider.of<UserProvider>(context, listen: false).setAdresseCreated(true);
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Dirección registrada exitosamente')),
  //         );
  //         // Navigator.of(context).pop();
  //         // Navigator.of(context).pop(true);
  //          Navigator.pop(context, address);

  //       }

  //     } catch (e) {
  //       _showError('Error: $e');
  //     }
  //   } else {
  //     _showError('Por favor completa todos los campos requeridos.');
  //   }
  // }
Future<void> _createAddress() async {
  if (latitude == null || longitude == null) {
    _showError(
      'Por favor permite acceder a tu ubicación antes de continuar. Asegúrate de activar el GPS.',
    );
    _captureLocation(); // Captura la ubicación automáticamente al iniciar
    return; // Detiene el proceso si la ubicación no está disponible
  }

  if (_formKey.currentState!.validate() && selectedCity != null) {
    double lat = latitude ?? 0.0;
    double lon = longitude ?? 0.0;
    String status = "activo";

    final address = Address(
      id: 0,
      profileId: widget.userId,
      street: _streetController.text,
      houseNumber: _houseNumberController.text,
      cityId: selectedCity!.id,
      postalCode: _postalCodeController.text,
      latitude: lat,
      longitude: lon,
      status: status,
    );

    // Mostrar diálogo de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _addressService.createAddress(address, widget.userId);

      if (mounted) {
        // Actualizar el estado de UserProvider
        Provider.of<UserProvider>(context, listen: false)
            .setAdresseCreated(true);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dirección registrada exitosamente')),
        );

        // Cerrar el diálogo y regresar la dirección creada
        Navigator.of(context).pop(); // Cerrar el diálogo
        Navigator.of(context).pop(true); // Regresar al anterior con éxito
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      // Asegurarnos de cerrar el diálogo de progreso
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Cerrar el diálogo
      }
    }
  } else {
    _showError('Por favor completa todos los campos requeridos.');
  }
}




}
