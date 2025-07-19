import 'package:flutter/material.dart';
import '../models/adresse.dart';
import '../models/models.dart';
import '../api/adresse_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'location_module.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

final logger = Logger();

class EditAddressScreen extends StatefulWidget {
  final int userId;
  final Address address;

  const EditAddressScreen({super.key, required this.userId, required this.address});

  @override
  EditAddressScreenState createState() => EditAddressScreenState();
}

class EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _postalCodeController = TextEditingController();

  List<Country> _countries = [];
  List<StateModel> _states = [];
  List<City> _cities = [];

  Country? _selectedCountry;
  StateModel? _selectedState;
  City? _selectedCity;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLocationLoading = false;
  String _locationStatus = 'No ubicado';

  double _latitude = 0.0;
  double _longitude = 0.0;

  @override
  void initState() {
    super.initState();
    logger.i('Console log para verificar el userId al inicio...... Recibiendo userId: ${widget.userId}');
    
    // Pre-llenar los campos con los datos existentes
    _streetController.text = widget.address.street;
    _houseNumberController.text = widget.address.houseNumber;
    _postalCodeController.text = widget.address.postalCode;
    _latitude = widget.address.latitude;
    _longitude = widget.address.longitude;
    _locationStatus = 'Ubicación cargada';

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await loadCountries();
      if (_selectedCountry != null) {
        await loadStates();
        // Buscar el estado correcto basado en el cityId
        await _findCorrectStateAndCity();
      }
    } catch (e) {
      logger.e('Error cargando datos iniciales: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _findCorrectStateAndCity() async {
    // Buscar en qué estado está la ciudad
    for (var state in _states) {
      try {
        final citiesInState = await AddressService().fetchCitiesByState(state.id);
        final targetCityIndex = citiesInState.indexWhere(
          (city) => city.id == widget.address.cityId,
        );
        
        if (targetCityIndex != -1) {
          setState(() {
            _selectedState = state;
            _cities = citiesInState;
            _selectedCity = citiesInState[targetCityIndex];
          });
          return;
        }
      } catch (e) {
        continue;
      }
    }
    
    // Si no encontramos la ciudad, usar el primer estado y cargar sus ciudades
    if (_states.isNotEmpty) {
      _selectedState = _states.first;
      await loadCities();
      if (_cities.isNotEmpty) {
        _selectedCity = _cities.first;
      }
    }
  }

  Future<void> loadCountries() async {
    try {
      final countries = await AddressService().fetchCountries();
      setState(() {
        _countries = countries;
        // Seleccionar el país por defecto (Venezuela)
        _selectedCountry = countries.firstWhere((country) => country.name == 'Venezuela');
      });
    } catch (e) {
      logger.e('Error cargando países: $e');
    }
  }

  Future<void> loadStates() async {
    if (_selectedCountry == null) return;
    
    try {
      final states = await AddressService().fetchStates(_selectedCountry!.id);
      setState(() {
        _states = states;
        // Seleccionar el estado por defecto si existe
        if (states.isNotEmpty) {
          _selectedState = states.first;
        }
      });
    } catch (e) {
      logger.e('Error cargando estados: $e');
    }
  }

  Future<void> loadCities() async {
    if (_selectedState == null) return;
    
    try {
      final cities = await AddressService().fetchCitiesByState(_selectedState!.id);
      setState(() {
        _cities = cities;
        // Seleccionar la ciudad por defecto si existe
        if (cities.isNotEmpty) {
          _selectedCity = cities.first;
        }
      });
    } catch (e) {
      logger.e('Error cargando ciudades: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
      _locationStatus = 'Obteniendo ubicación...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'Servicios de ubicación deshabilitados';
          _isLocationLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'Permisos de ubicación denegados';
            _isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Permisos de ubicación permanentemente denegados';
          _isLocationLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationStatus = 'Ubicación obtenida';
        _isLocationLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Error obteniendo ubicación: $e';
        _isLocationLoading = false;
      });
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una ciudad')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedAddress = Address(
        id: widget.address.id,
        street: _streetController.text.trim(),
        houseNumber: _houseNumberController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        status: widget.address.status,
        profileId: widget.userId,
        cityId: _selectedCity!.id,
        createdAt: widget.address.createdAt,
        updatedAt: DateTime.now(),
      );

      await AddressService().updateAddress(updatedAddress, widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Dirección actualizada exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        );
        Navigator.pop(context, updatedAddress);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        title: const Text(
          'Editar Dirección',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildLocationStatus(),
                    const SizedBox(height: 24),
                    _buildAddressFields(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_location_alt,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar Ubicación',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Actualiza los datos de tu dirección',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isLocationLoading
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isLocationLoading ? Icons.location_searching : Icons.location_on,
              color: _isLocationLoading ? Colors.orange : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de Ubicación',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _locationStatus,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isLocationLoading ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _isLocationLoading ? null : _getCurrentLocation,
            icon: const Icon(Icons.my_location, size: 16),
            label: const Text('Obtener'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _streetController,
          label: 'Dirección',
          icon: Icons.home,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa la dirección';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _houseNumberController,
          label: 'Número de Casa',
          icon: Icons.numbers,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa el número de casa';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _postalCodeController,
          label: 'Código Postal',
          icon: Icons.mail,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa el código postal';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown<Country>(
          value: _selectedCountry,
          hint: 'Selecciona un país',
          items: _countries.map((country) => DropdownMenuItem(
            value: country,
            child: Text(country.name),
          )).toList(),
          onChanged: (Country? value) {
            setState(() {
              _selectedCountry = value;
              _selectedState = null;
              _selectedCity = null;
            });
            if (value != null) {
              loadStates();
            }
          },
          icon: Icons.public,
          label: 'País',
        ),
        const SizedBox(height: 16),
        _buildDropdown<StateModel>(
          value: _selectedState,
          hint: 'Selecciona un estado',
          items: _states.map((state) => DropdownMenuItem(
            value: state,
            child: Text(state.name),
          )).toList(),
          onChanged: (StateModel? value) {
            setState(() {
              _selectedState = value;
              _selectedCity = null;
            });
            if (value != null) {
              loadCities();
            }
          },
          icon: Icons.location_city,
          label: 'Estado',
        ),
        const SizedBox(height: 16),
        _buildDropdown<City>(
          value: _selectedCity,
          hint: 'Selecciona una ciudad',
          items: _cities.map((city) => DropdownMenuItem(
            value: city,
            child: Text(city.name),
          )).toList(),
          onChanged: (City? value) {
            setState(() {
              _selectedCity = value;
            });
          },
          icon: Icons.location_on,
          label: 'Ciudad',
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required IconData icon,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        hint: Text(hint, overflow: TextOverflow.ellipsis),
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        dropdownColor: Colors.white,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1976D2)),
        menuMaxHeight: 200,
        validator: (value) {
          if (value == null) {
            return 'Por favor selecciona un $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveAddress,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSaving
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Guardando...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save),
                  SizedBox(width: 8),
                  Text(
                    'Guardar Cambios',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _streetController.dispose();
    _houseNumberController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }
} 