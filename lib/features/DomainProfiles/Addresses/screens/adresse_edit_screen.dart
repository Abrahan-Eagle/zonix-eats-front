import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/features/utils/app_colors.dart';
import '../api/adresse_service.dart';
import '../models/adresse.dart';
import '../models/models.dart';

final logger = Logger();

class EditAddressScreen extends StatefulWidget {
  final int userId;
  final Address address;

  const EditAddressScreen(
      {super.key, required this.userId, required this.address});

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

  final MapController _mapController = MapController();
  bool _skipNextReverseGeocode = false;
  DateTime? _lastGeocodingCall;
  Timer? _streetDebounceTimer;

  @override
  void initState() {
    super.initState();
    logger.i(
        'Console log para verificar el userId al inicio...... Recibiendo userId: ${widget.userId}');

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
        await _findCorrectStateAndCity();
      }
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(LatLng(_latitude, _longitude), 15);
        });
      }
    } catch (e) {
      logger.e('Error cargando datos iniciales: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyCountriesFallback() {
    if (!mounted) return;
    setState(() {
      _countries = const [
        Country(id: 1, name: 'Venezuela', states: []),
        Country(id: 2, name: 'Colombia', states: []),
        Country(id: 3, name: 'Brasil', states: []),
      ];
      _selectedCountry = _countries.first;
      _states = [];
      _cities = [];
      _selectedState = null;
      _selectedCity = null;
    });
    loadStates();
  }

  Future<void> _findCorrectStateAndCity() async {
    // Buscar en qué estado está la ciudad
    for (var state in _states) {
      try {
        final citiesInState =
            await AddressService().fetchCitiesByState(state.id);
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
      final data = await AddressService().fetchCountries();
      if (!mounted) return;
      if (data.isEmpty) {
        _applyCountriesFallback();
        return;
      }
      setState(() {
        _countries = data;
        _selectedCountry = _countries.firstWhere(
          (c) => c.name.toLowerCase().contains('venezuela'),
          orElse: () => _countries.first,
        );
        _states = [];
        _cities = [];
        _selectedState = null;
        _selectedCity = null;
      });
      await loadStates();
    } catch (e) {
      logger.e('Error cargando países: $e');
      if (mounted) _applyCountriesFallback();
    }
  }

  Future<void> loadStates() async {
    if (_selectedCountry == null) return;
    try {
      final data = await AddressService().fetchStates(_selectedCountry!.id);
      if (!mounted) return;
      setState(() {
        _states = data;
        _selectedState = data.isNotEmpty ? data.first : null;
        _cities = [];
        _selectedCity = null;
      });
    } catch (e) {
      logger.e('Error cargando estados: $e');
      if (mounted) setState(() {
        _states = [];
        _selectedState = null;
        _cities = [];
        _selectedCity = null;
      });
    }
  }

  Future<void> loadCities() async {
    if (_selectedState == null) return;
    try {
      final data = await AddressService().fetchCitiesByState(_selectedState!.id);
      if (!mounted) return;
      setState(() {
        _cities = data;
        _selectedCity = data.isNotEmpty ? data.first : null;
      });
    } catch (e) {
      logger.e('Error cargando ciudades: $e');
      if (mounted) setState(() {
        _cities = [];
        _selectedCity = null;
      });
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
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationStatus = 'Ubicación obtenida';
        _isLocationLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(LatLng(_latitude, _longitude), 15);
        } catch (_) {}
      });
      await _autoFillFromLocation(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _locationStatus = 'Error obteniendo ubicación: $e';
        _isLocationLoading = false;
      });
    }
  }

  Future<void> _moveMapToAddress() async {
    final parts = <String>[];
    final street = _streetController.text.trim();
    if (street.isNotEmpty) parts.add(street);
    if (_selectedCity != null) parts.add(_selectedCity!.name);
    if (_selectedState != null) parts.add(_selectedState!.name);
    if (_selectedCountry != null) parts.add(_selectedCountry!.name);
    if (parts.isEmpty) return;

    final address = parts.join(', ');
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty || !mounted) return;

      final loc = locations.first;
      _skipNextReverseGeocode = true;
      setState(() {
        _latitude = loc.latitude;
        _longitude = loc.longitude;
      });
      _mapController.move(LatLng(loc.latitude, loc.longitude), 15);
    } catch (_) {}
  }

  void _onStreetChanged(String? value) {
    _streetDebounceTimer?.cancel();
    _streetDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (_selectedCity != null ||
          _selectedState != null ||
          _selectedCountry != null) {
        _moveMapToAddress();
      }
    });
  }

  Future<void> _autoFillFromLocation(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty || !mounted) return;
      final placemark = placemarks.first;

      String? mainStreet;
      if (placemark.street != null &&
          placemark.street!.isNotEmpty &&
          !placemark.street!.contains('+') &&
          placemark.street!.length > 3) {
        mainStreet = placemark.street;
      } else if (placemark.thoroughfare != null &&
          placemark.thoroughfare!.isNotEmpty &&
          !placemark.thoroughfare!.contains('+') &&
          placemark.thoroughfare!.length > 3) {
        mainStreet = placemark.thoroughfare;
      }

      final houseNumber = placemark.subThoroughfare != null &&
              placemark.subThoroughfare!.trim().isNotEmpty &&
              !placemark.subThoroughfare!.contains('+')
          ? placemark.subThoroughfare!.trim()
          : '';
      final postalCode = placemark.postalCode != null &&
              placemark.postalCode!.trim().isNotEmpty &&
              !placemark.postalCode!.contains('+')
          ? placemark.postalCode!.trim()
          : '';

      if (mounted) {
        setState(() {
          if (mainStreet != null && mainStreet.isNotEmpty) {
            _streetController.text = mainStreet;
          }
          if (houseNumber.isNotEmpty) {
            _houseNumberController.text = houseNumber;
          }
          if (postalCode.isNotEmpty) {
            _postalCodeController.text = postalCode;
          }
        });
      }

      if (placemark.country != null && placemark.country!.isNotEmpty) {
        await _selectCountryByName(placemark.country!);
        await Future.delayed(const Duration(milliseconds: 400));
      }
      if (_selectedCountry != null &&
          placemark.administrativeArea != null &&
          placemark.administrativeArea!.isNotEmpty) {
        await _selectStateByName(placemark.administrativeArea!);
        await Future.delayed(const Duration(milliseconds: 400));
      }
      if (_selectedState != null && placemark.locality != null && placemark.locality!.isNotEmpty) {
        await _selectCityByName(placemark.locality!);
      } else if (_selectedState != null &&
          placemark.subAdministrativeArea != null &&
          placemark.subAdministrativeArea!.isNotEmpty) {
        await _selectCityByName(placemark.subAdministrativeArea!);
      }
    } catch (_) {}
  }

  String _normalizeString(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }

  Future<void> _selectCountryByName(String countryName) async {
    if (_countries.isEmpty) return;
    final normalizedSearch = _normalizeString(countryName);
    Country? found;
    try {
      found = _countries.firstWhere(
        (c) {
          final normalizedName = _normalizeString(c.name);
          return normalizedName == normalizedSearch ||
              normalizedName.contains(normalizedSearch) ||
              normalizedSearch.contains(normalizedName);
        },
        orElse: () => _countries.firstWhere(
          (c) => c.name.toLowerCase().contains(countryName.toLowerCase()),
          orElse: () => _countries.first,
        ),
      );
    } catch (_) {
      found = _countries.first;
    }
    if (!mounted) return;
    setState(() {
      _selectedCountry = found;
      _selectedState = null;
      _selectedCity = null;
      _states = [];
      _cities = [];
    });
    await loadStates();
  }

  Future<void> _selectStateByName(String stateName) async {
    if (_selectedCountry == null || _states.isEmpty) return;
    final normalizedSearch = _normalizeString(stateName);
    StateModel? found;
    try {
      found = _states.firstWhere(
        (s) {
          final normalizedName = _normalizeString(s.name);
          return normalizedName == normalizedSearch ||
              normalizedName.contains(normalizedSearch) ||
              normalizedSearch.contains(normalizedName);
        },
        orElse: () => _states.firstWhere(
          (s) => s.name.toLowerCase().contains(stateName.toLowerCase()),
          orElse: () => _states.first,
        ),
      );
    } catch (_) {
      found = _states.first;
    }
    if (!mounted) return;
    setState(() {
      _selectedState = found;
      _selectedCity = null;
      _cities = [];
    });
    await loadCities();
  }

  Future<void> _selectCityByName(String cityName) async {
    if (_selectedState == null || _cities.isEmpty) return;
    final normalizedSearch = _normalizeString(cityName);
    City? found;
    try {
      found = _cities.firstWhere(
        (c) {
          final normalizedName = _normalizeString(c.name);
          return normalizedName == normalizedSearch ||
              normalizedName.contains(normalizedSearch) ||
              normalizedSearch.contains(normalizedName);
        },
        orElse: () => _cities.firstWhere(
          (c) => c.name.toLowerCase().contains(cityName.toLowerCase()),
          orElse: () => _cities.first,
        ),
      );
    } catch (_) {
      found = _cities.first;
    }
    if (!mounted) return;
    setState(() => _selectedCity = found);
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
                Icon(Icons.check_circle, color: AppColors.white),
                SizedBox(width: 8),
                Text('Dirección actualizada exitosamente'),
              ],
            ),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8))),
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
                const Icon(Icons.error, color: AppColors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.scaffoldBgLight,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.scaffoldBgLight,
        foregroundColor: AppColors.primaryText(context),
        title: Text(
          'Editar Dirección',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppColors.primaryText(context),
          ),
        ),
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryText(context)),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
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
                    _buildMapCard(),
                    const SizedBox(height: 24),
                    if (_latitude != 0.0 || _longitude != 0.0) ...[
                      _buildLocationCapturedCard(),
                      const SizedBox(height: 16),
                    ],
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
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_location_alt,
              size: 40,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Edita tu dirección',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Actualiza los detalles para tus entregas espaciales',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryText(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    const mapHeight = 220.0;
    final center = LatLng(
      _latitude != 0.0 ? _latitude : 10.4806,
      _longitude != 0.0 ? _longitude : -66.9036,
    );
    final borderRadius = BorderRadius.circular(16);

    return Container(
      height: mapHeight,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.slateBorder
              : AppColors.stitchBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom,
                ),
                onMapEvent: (event) {
                  if (event is MapEventMove) {
                    if (_skipNextReverseGeocode) {
                      _skipNextReverseGeocode = false;
                      return;
                    }
                    final newCenter = _mapController.camera.center;
                    setState(() {
                      _latitude = newCenter.latitude;
                      _longitude = newCenter.longitude;
                    });
                    final now = DateTime.now();
                    if (_lastGeocodingCall == null ||
                        now.difference(_lastGeocodingCall!).inMilliseconds >
                            500) {
                      _lastGeocodingCall = now;
                      _autoFillFromLocation(
                        newCenter.latitude,
                        newCenter.longitude,
                      );
                    }
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConfig.osmTileUrl,
                  userAgentPackageName: 'com.zonix.eats',
                ),
              ],
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.red,
                    size: 46,
                  ),
                  Container(
                    width: 16,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Material(
                color: AppColors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _getCurrentLocation,
                  child: const SizedBox(
                    height: 38,
                    width: 38,
                    child: Icon(Icons.my_location, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCapturedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.green, size: 24),
          const SizedBox(width: 12),
          Text(
            'Ubicación capturada',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.green,
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
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.slateBorder
              : AppColors.stitchBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: AppColors.blue,
            size: 24,
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
                    color: AppColors.secondaryText(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _locationStatus,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isLocationLoading ? AppColors.orange : AppColors.primaryText(context),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _isLocationLoading ? null : _getCurrentLocation,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  'Obtener',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UBICACIÓN REGIONAL',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.blue,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildDropdown<Country>(
          value: _selectedCountry,
          hint: 'Selecciona un país',
          items: _countries
              .map((country) => DropdownMenuItem(
                    value: country,
                    child: Text(country.name),
                  ))
              .toList(),
          onChanged: (Country? value) async {
            setState(() {
              _selectedCountry = value;
              _selectedState = null;
              _selectedCity = null;
              _states = [];
              _cities = [];
            });
            if (value != null) {
              await loadStates();
              if (mounted) _moveMapToAddress();
            }
          },
          icon: Icons.public,
          label: 'País',
        ),
        const SizedBox(height: 16),
        _buildDropdown<StateModel>(
          value: _selectedState,
          hint: 'Selecciona un estado',
          items: _states
              .map((state) => DropdownMenuItem(
                    value: state,
                    child: Text(state.name),
                  ))
              .toList(),
          onChanged: (StateModel? value) async {
            setState(() {
              _selectedState = value;
              _selectedCity = null;
              _cities = [];
            });
            if (value != null) {
              await loadCities();
              if (mounted) _moveMapToAddress();
            }
          },
          icon: Icons.location_city,
          label: 'Estado',
        ),
        const SizedBox(height: 16),
        _buildDropdown<City>(
          value: _selectedCity,
          hint: 'Selecciona una ciudad',
          items: _cities
              .map((city) => DropdownMenuItem(
                    value: city,
                    child: Text(city.name),
                  ))
              .toList(),
          onChanged: (City? value) {
            setState(() {
              _selectedCity = value;
            });
            if (value != null) _moveMapToAddress();
          },
          icon: Icons.location_on,
          label: 'Ciudad',
        ),
        const SizedBox(height: 24),
        Text(
          'DETALLES DE LA DIRECCIÓN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.blue,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _streetController,
          label: 'Dirección',
          icon: Icons.home,
          onChanged: _onStreetChanged,
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
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    void Function(String)? onChanged,
  }) {
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.slateBorder
        : AppColors.stitchBorder;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.blue),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.slateBorder
        : AppColors.stitchBorder;
    final screenHeight = MediaQuery.of(context).size.height;
    final menuHeight = (screenHeight * 0.5).clamp(280.0, 400.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.blue),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        hint: Text(hint, overflow: TextOverflow.ellipsis),
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        dropdownColor: AppColors.cardBg(context),
        icon: Icon(Icons.arrow_drop_down, color: AppColors.blue),
        menuMaxHeight: menuHeight,
        borderRadius: BorderRadius.circular(12),
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
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.white,
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
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
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
    _streetDebounceTimer?.cancel();
    _streetController.dispose();
    _houseNumberController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }
}
