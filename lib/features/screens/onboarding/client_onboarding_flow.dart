import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:image_picker/image_picker.dart';

import 'onboarding_provider.dart';
import 'package:zonix/features/services/commerce_data_service.dart';
import 'onboarding_service.dart';
import 'package:zonix/features/utils/user_provider.dart';
import 'package:zonix/features/DomainProfiles/Profiles/models/profile_model.dart';
import 'package:zonix/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix/features/DomainProfiles/Addresses/models/adresse.dart';
import 'package:zonix/features/DomainProfiles/Addresses/models/models.dart';
import 'package:zonix/features/DomainProfiles/Addresses/api/adresse_service.dart';
import 'package:zonix/features/DomainProfiles/Phones/models/phone.dart';
import 'package:zonix/features/DomainProfiles/Phones/api/phone_service.dart';
import 'package:zonix/main.dart';

/// Flujo completo de onboarding para CLIENTE (`users`).
///
/// - Paso 1: datos personales mínimos (solo memoria).
/// - Paso 2: dirección principal (solo memoria + GPS para autocompletar).
/// - Paso 3: teléfono de contacto (solo memoria).
///
/// No se escribe nada en la base de datos hasta que el usuario pulsa "Finalizar"
/// en el último paso. Hasta entonces todo se guarda solo en memoria
/// (OnboardingProvider y controladores). Al finalizar se hacen las únicas
/// llamadas de escritura al backend: crear Profile, Address, Phone y marcar
/// completed_onboarding.
///
/// El parámetro [isCommerce] permite reutilizar este flujo para el rol
/// comerciante, cambiando solo el paso final (navegación).
class ClientOnboardingFlow extends StatefulWidget {
  const ClientOnboardingFlow({super.key, this.isCommerce = false});

  /// Cuando es `true`, al terminar se navega al flujo de registro de comercio
  /// en lugar de completar el onboarding del comprador.
  final bool isCommerce;

  @override
  State<ClientOnboardingFlow> createState() => _ClientOnboardingFlowState();
}

class _ClientOnboardingFlowState extends State<ClientOnboardingFlow> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // STEP 1 – Perfil
  final _step1FormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _secondLastNameController = TextEditingController();
  DateTime? _birthDate;
  String? _selectedSex; // 'F' o 'M'

  // STEP 2 – Dirección
  final _step2FormKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _postalCodeController = TextEditingController();
  int? _cityId;

  // Servicio y modelos para País / Estado / Ciudad
  final AddressService _addressService = AddressService();
  final MapController _mapController = MapController();

  List<Country> _countries = [];
  List<StateModel> _states = [];
  List<City> _cities = [];
  Country? _selectedCountry;
  StateModel? _selectedState;
  City? _selectedCity;

  // Coordenadas actuales (centradas en el mapa)
  double? _latitude;
  double? _longitude;
  DateTime? _lastGeocodingCall;
  bool _isLoadingLocation = false;
  bool _skipNextReverseGeocode = false; // Evitar loop al mover mapa desde inputs
  Timer? _streetDebounceTimer; // Debounce para geocodificar al cambiar calle

  // STEP 2 (commerce): dirección del dueño — se guarda en provider, no se persiste hasta el final.

  // STEP 3 (solo commerce) – Datos del comercio (tabla commerces)
  final _step3FormKey = GlobalKey<FormState>();
  final _commerceNameController = TextEditingController();
  final _commerceTaxIdController = TextEditingController();
  final _commerceOwnerCiController = TextEditingController();
  final _commercePhoneController = TextEditingController();
  bool _commerceOpen = false;
  Map<String, Map<String, String>> _commerceSchedule = {};

  // STEP 4 (solo commerce) – Dirección del establecimiento (misma vista que paso 2, role commerce)
  final _step4FormKey = GlobalKey<FormState>();
  final _streetCommerceController = TextEditingController();
  final _houseNumberCommerceController = TextEditingController();
  final _postalCodeCommerceController = TextEditingController();

  // STEP 1 incluye teléfono
  final _phoneController = TextEditingController();
  List<Map<String, dynamic>> _operatorCodes = [];
  Map<String, dynamic>? _selectedOperator;
  bool _isLoadingOperators = false;

  // Foto
  XFile? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _prefillFromProvider();
    _loadCountries();
    _getCurrentLocation();
    _loadOperatorCodes();
    _streetController.addListener(_onStreetChanged);
    _streetCommerceController.addListener(_onStreetChanged);
    if (widget.isCommerce) {
      _commerceSchedule = {
        'lunes': {'inicio': '', 'fin': '', 'cerrado': 'false'},
        'martes': {'inicio': '', 'fin': '', 'cerrado': 'false'},
        'miercoles': {'inicio': '', 'fin': '', 'cerrado': 'false'},
        'jueves': {'inicio': '', 'fin': '', 'cerrado': 'false'},
        'viernes': {'inicio': '', 'fin': '', 'cerrado': 'false'},
        'sabado': {'inicio': '', 'fin': '', 'cerrado': 'false'},
        'domingo': {'inicio': '', 'fin': '', 'cerrado': 'false'},
      };
    }
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedPhoto = pickedFile;
        });
        context.read<OnboardingProvider>().setPhotoPath(pickedFile.path);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se tomó ninguna foto.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al tomar la foto: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _streetController.removeListener(_onStreetChanged);
    _streetCommerceController.removeListener(_onStreetChanged);
    _streetDebounceTimer?.cancel();
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _secondLastNameController.dispose();
    _streetController.dispose();
    _houseNumberController.dispose();
    _postalCodeController.dispose();
    _commerceNameController.dispose();
    _commerceTaxIdController.dispose();
    _commerceOwnerCiController.dispose();
    _commercePhoneController.dispose();
    _streetCommerceController.dispose();
    _houseNumberCommerceController.dispose();
    _postalCodeCommerceController.dispose();
    _phoneController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _prefillStep4FromUserAddress() {
    if (_step4PrefilledFromUser) return;
    final provider = context.read<OnboardingProvider>();
    if (provider.street == null && provider.houseNumber == null && provider.postalCode == null) return;
    setState(() {
      if (provider.street != null) _streetController.text = provider.street!;
      if (provider.houseNumber != null) _houseNumberController.text = provider.houseNumber!;
      if (provider.postalCode != null) _postalCodeController.text = provider.postalCode!;
      if (provider.latitude != null) _latitude = provider.latitude;
      if (provider.longitude != null) _longitude = provider.longitude;
      _step4PrefilledFromUser = true;
    });
  }

  void _prefillFromProvider() {
    final provider = context.read<OnboardingProvider>();
    if (provider.firstName != null) {
      _firstNameController.text = provider.firstName!;
    }
    if (provider.lastName != null) {
      _lastNameController.text = provider.lastName!;
    }
    if (provider.secondLastName != null) {
      _secondLastNameController.text = provider.secondLastName!;
    }
    _birthDate = provider.dateOfBirth;
    _selectedSex = provider.sex;

    if (provider.street != null) {
      _streetController.text = provider.street!;
    }
    if (provider.houseNumber != null) {
      _houseNumberController.text = provider.houseNumber!;
    }
    if (provider.postalCode != null) {
      _postalCodeController.text = provider.postalCode!;
    }
    _cityId = provider.cityId;
    _latitude = provider.latitude;
    _longitude = provider.longitude;

    if (provider.rawPhone != null) {
      _phoneController.text = provider.rawPhone!;
    }

    if (provider.photoPath != null && provider.photoPath!.isNotEmpty) {
      _selectedPhoto = XFile(provider.photoPath!);
    }
  }

  // -----------------------------
  // Carga de País / Estado / Ciudad
  // -----------------------------

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
    _loadStates();
  }

  Future<void> _loadCountries() async {
    try {
      final data = await _addressService.fetchCountries();
      if (!mounted) return;

      // Si el backend no tiene países o devuelve vacío, usamos fallback
      if (data.isEmpty) {
        _applyCountriesFallback();
      } else {
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
        await _loadStates();
      }
    } catch (_) {
      // Si la API falla (302, sin token, red, etc.), mostrar al menos los selects con fallback
      _applyCountriesFallback();
    }
  }

  Future<void> _loadStates() async {
    if (_selectedCountry == null) return;
    try {
      final data = await _addressService.fetchStates(_selectedCountry!.id);
      if (!mounted) return;
      setState(() {
        _states = data;
        _selectedState = null;
        _cities = [];
        _selectedCity = null;
      });
    } catch (_) {}
  }

  Future<void> _loadCities() async {
    if (_selectedState == null) return;
    try {
      final data = await _addressService.fetchCitiesByState(_selectedState!.id);
      if (!mounted) return;
      setState(() {
        _cities = data;
        _selectedCity = null;
      });
    } catch (_) {}
  }

  void _onCountryChanged(Country? value) {
    setState(() {
      _selectedCountry = value;
      _selectedState = null;
      _selectedCity = null;
      _states = [];
      _cities = [];
    });
    if (value != null) {
      _loadStates();
      _moveMapToAddress();
    }
  }

  void _onStateChanged(StateModel? value) {
    setState(() {
      _selectedState = value;
      _selectedCity = null;
      _cities = [];
    });
    if (value != null) {
      _loadCities();
      _moveMapToAddress();
    }
  }

  void _onCityChanged(City? value) {
    setState(() {
      _selectedCity = value;
      _cityId = value?.id;
    });
    if (value != null) {
      _moveMapToAddress();
    }
  }

  /// Geocodificación directa: mueve el mapa a la ubicación indicada por los selects/inputs.
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
      _mapController.move(latLng.LatLng(loc.latitude, loc.longitude), 15);
    } catch (_) {
      // Geocoding falló (red, límite, etc.) – ignorar silenciosamente
    }
  }

  void _onStreetChanged() {
    _streetDebounceTimer?.cancel();
    _streetDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (_selectedCity != null || _selectedState != null || _selectedCountry != null) {
        _moveMapToAddress();
      }
    });
  }

  static List<Map<String, dynamic>> _fallbackOperatorCodes() {
    return [
      {'id': 1, 'name': '0412', 'code': '412'},
      {'id': 2, 'name': '0414', 'code': '414'},
      {'id': 3, 'name': '0424', 'code': '424'},
      {'id': 4, 'name': '0416', 'code': '416'},
      {'id': 5, 'name': '0426', 'code': '426'},
    ];
  }

  Future<void> _loadOperatorCodes() async {
    setState(() => _isLoadingOperators = true);
    try {
      final service = PhoneService();
      final codes = await service.fetchOperatorCodes();
      if (!mounted) return;
      setState(() {
        _operatorCodes = codes.isNotEmpty ? codes : _fallbackOperatorCodes();
        // Que el usuario esté obligado a elegir un código explícitamente.
        _selectedOperator = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _operatorCodes = _fallbackOperatorCodes();
        _selectedOperator = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingOperators = false);
      }
    }
  }

  // -----------------------------
  // Geolocalización y mapa
  // -----------------------------

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setDefaultLocation();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _setDefaultLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(
            latLng.LatLng(_latitude!, _longitude!),
            15,
          );
        } catch (_) {}
      });

      await _autoFillFromLocation(position.latitude, position.longitude);
    } catch (_) {
      _setDefaultLocation();
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _setDefaultLocation() {
    if (!mounted) return;
    setState(() {
      _latitude = 10.4806;
      _longitude = -66.9036;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.move(
          latLng.LatLng(_latitude!, _longitude!),
          15,
        );
      } catch (_) {}
    });
  }

  Future<void> _autoFillFromLocation(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty || !mounted) return;

      final placemark = placemarks.first;

      // -----------------------------
      // 1) Autocompletar texto de dirección
      //    (inspirado en CorralX OnboardingPage2)
      // -----------------------------
      String? mainStreet;
      String? crossStreet;

      // Prioridad 1: street (dirección completa más confiable)
      if (placemark.street != null &&
          placemark.street!.isNotEmpty &&
          !placemark.street!.contains('+') &&
          placemark.street!.length > 3) {
        mainStreet = placemark.street!;

        // Intentar extraer cruce si el street contiene información de cruce
        if (!(mainStreet.toLowerCase().contains(' con ') ||
            mainStreet.toLowerCase().contains(' c/c ') ||
            mainStreet.toLowerCase().contains(' y '))) {
          // Buscar calles cercanas en otros placemarks para construir cruce
          if (placemarks.length > 1) {
            for (var pm in placemarks.skip(1)) {
              if (pm.thoroughfare != null &&
                  pm.thoroughfare!.isNotEmpty &&
                  pm.thoroughfare != placemark.thoroughfare &&
                  !pm.thoroughfare!.contains('+') &&
                  pm.thoroughfare!.length > 3) {
                crossStreet = pm.thoroughfare;
                break;
              }
            }
          }
        }
      }
      // Prioridad 2: thoroughfare (nombre de calle/avenida)
      else if (placemark.thoroughfare != null &&
          placemark.thoroughfare!.isNotEmpty &&
          !placemark.thoroughfare!.contains('+') &&
          placemark.thoroughfare!.length > 3) {
        mainStreet = placemark.thoroughfare!;

        if (placemarks.length > 1) {
          for (var pm in placemarks.skip(1)) {
            if (pm.thoroughfare != null &&
                pm.thoroughfare!.isNotEmpty &&
                pm.thoroughfare != mainStreet &&
                !pm.thoroughfare!.contains('+') &&
                pm.thoroughfare!.length > 3) {
              crossStreet = pm.thoroughfare;
              break;
            }
          }
        }
      }

      if (mounted) {
        final addressParts = <String>[];

        // Urbanización / subLocality primero (como en CorralX)
        String? urb;
        if (placemark.subLocality != null &&
            placemark.subLocality!.isNotEmpty &&
            !placemark.subLocality!.contains('+')) {
          final normalizedSubLocality = placemark.subLocality!.trim();
          if (normalizedSubLocality.toLowerCase().startsWith('urb')) {
            urb = normalizedSubLocality;
          } else {
            urb = 'Urb $normalizedSubLocality';
          }
        }

        if (urb != null) {
          addressParts.add(urb);
        }

        if (mainStreet != null && mainStreet.isNotEmpty) {
          addressParts.add(mainStreet);
        }

        if (crossStreet != null && crossStreet.isNotEmpty) {
          addressParts.add('c/c $crossStreet');
        }

        // Número de casa/piso desde subThoroughfare (ej. número de edificio)
        final houseNumber = placemark.subThoroughfare != null &&
                placemark.subThoroughfare!.trim().isNotEmpty &&
                !placemark.subThoroughfare!.contains('+')
            ? placemark.subThoroughfare!.trim()
            : '';

        // Código postal
        final postalCode = placemark.postalCode != null &&
                placemark.postalCode!.trim().isNotEmpty &&
                !placemark.postalCode!.contains('+')
            ? placemark.postalCode!.trim()
            : '';

        setState(() {
          if (addressParts.isNotEmpty) {
            _streetController.text = addressParts.join(', ');
          }
          if (houseNumber.isNotEmpty) {
            _houseNumberController.text = houseNumber;
          }
          if (postalCode.isNotEmpty) {
            _postalCodeController.text = postalCode;
          }
        });
      }

      // -----------------------------
      // 2) Auto-seleccionar País / Estado / Ciudad
      //    usando los datos de las tablas (countries, states, cities)
      // -----------------------------

      // País
      if (placemark.country != null && placemark.country!.isNotEmpty) {
        await _selectCountryByName(placemark.country!);
        // Pequeña espera para permitir que se carguen los estados
        await Future.delayed(const Duration(milliseconds: 400));
      }

      // Estado / región administrativa
      if (_selectedCountry != null &&
          placemark.administrativeArea != null &&
          placemark.administrativeArea!.isNotEmpty) {
        await _selectStateByName(placemark.administrativeArea!);
        // Esperar a que se carguen las ciudades
        await Future.delayed(const Duration(milliseconds: 400));
      }

      // Ciudad (locality o subAdministrativeArea)
      if (_selectedState != null &&
          placemark.locality != null &&
          placemark.locality!.isNotEmpty) {
        await _selectCityByName(placemark.locality!);
      } else if (_selectedState != null &&
          placemark.subAdministrativeArea != null &&
          placemark.subAdministrativeArea!.isNotEmpty) {
        await _selectCityByName(placemark.subAdministrativeArea!);
      }
    } catch (_) {
      // El reverse geocoding es opcional; si falla no bloquea el flujo.
    }
  }

  // -----------------------------
  // Helpers para selección automática
  // -----------------------------

  Future<void> _selectCountryByName(String countryName) async {
    if (_countries.isEmpty) {
      await _loadCountries();
    }

    if (_countries.isEmpty) return;

    final normalizedSearch = _normalizeString(countryName);
    Country? found;

    try {
      found = _countries.firstWhere(
        (c) {
          final name = c.name;
          final normalizedName = _normalizeString(name);
          return normalizedName == normalizedSearch ||
              normalizedName.contains(normalizedSearch) ||
              normalizedSearch.contains(normalizedName);
        },
        orElse: () => _countries.firstWhere(
          (c) {
            final name = c.name;
            return name.toLowerCase().contains(countryName.toLowerCase());
          },
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

    await _loadStates();
  }

  Future<void> _selectStateByName(String stateName) async {
    if (_selectedCountry == null) return;
    if (_states.isEmpty) {
      await _loadStates();
    }
    if (_states.isEmpty) return;

    final normalizedSearch = _normalizeString(stateName);
    StateModel? found;

    try {
      found = _states.firstWhere(
        (s) {
          final name = s.name;
          final normalizedName = _normalizeString(name);
          return normalizedName == normalizedSearch ||
              normalizedName.contains(normalizedSearch) ||
              normalizedSearch.contains(normalizedName);
        },
        orElse: () => _states.firstWhere(
          (s) {
            final name = s.name;
            return name.toLowerCase().contains(stateName.toLowerCase());
          },
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

    await _loadCities();
  }

  Future<void> _selectCityByName(String cityName) async {
    if (_selectedState == null) return;
    if (_cities.isEmpty) {
      await _loadCities();
    }
    if (_cities.isEmpty) return;

    final normalizedSearch = _normalizeString(cityName);
    City? found;

    try {
      found = _cities.firstWhere(
        (c) {
          final name = c.name;
          final normalizedName = _normalizeString(name);
          return normalizedName == normalizedSearch ||
              normalizedName.contains(normalizedSearch) ||
              normalizedSearch.contains(normalizedName);
        },
        orElse: () => _cities.firstWhere(
          (c) {
            final name = c.name;
            return name.toLowerCase().contains(cityName.toLowerCase());
          },
          orElse: () => _cities.first,
        ),
      );
    } catch (_) {
      found = _cities.first;
    }

    if (!mounted) return;

    final city = found;
    setState(() {
      _selectedCity = city;
      _cityId = city.id;
    });
  }

  /// Normaliza un string para comparación (sin acentos, minúsculas)
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

  bool _step4PrefilledFromUser = false;

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    // Pre-llenar Step 4 (dirección establecimiento) con la dirección del usuario
    if (widget.isCommerce && step == 3 && !_step4PrefilledFromUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _prefillStep4FromUserAddress();
      });
    }
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  int get _totalSteps => widget.isCommerce ? 4 : 2;

  Future<void> _handleNext() async {
    if (_currentStep == 0) {
      if (_step1FormKey.currentState?.validate() != true || _birthDate == null || _selectedSex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor completa tus datos personales.'),
          ),
        );
        return;
      }

      final provider = context.read<OnboardingProvider>();
      provider.setProfileData(
        firstName: _firstNameController.text.trim(),
        middleName: null,
        lastName: _lastNameController.text.trim(),
        secondLastName: _secondLastNameController.text.trim().isEmpty
            ? null
            : _secondLastNameController.text.trim(),
        dateOfBirth: _birthDate!,
        sex: (_selectedSex == 'F' || _selectedSex == 'M') ? _selectedSex! : 'M',
      );
      provider.setRawPhone(_phoneController.text.trim());

      _goToStep(1);
    } else if (_currentStep == 1) {
      if (_step2FormKey.currentState?.validate() != true ||
          _selectedCity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completa todos los campos de dirección (país, estado, ciudad y dirección).'),
          ),
        );
        return;
      }

      if (_latitude == null || _longitude == null) {
        _latitude = 0.0;
        _longitude = 0.0;
      }

      final provider = context.read<OnboardingProvider>();
      provider.setAddressDetails(
        street: _streetController.text.trim(),
        houseNumber: _houseNumberController.text.trim().isEmpty
            ? null
            : _houseNumberController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty
            ? null
            : _postalCodeController.text.trim(),
        cityId: _selectedCity?.id ?? _cityId ?? 0,
      );
      provider.setLocationCoordinates(
        latitude: _latitude!,
        longitude: _longitude!,
      );

      if (widget.isCommerce) {
        _goToStep(2);
        return;
      }
      await _handleSubmit();
    } else if (widget.isCommerce && _currentStep == 2) {
      if (_step3FormKey.currentState?.validate() != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completa los datos de tu comercio (nombre del local y teléfono).'),
          ),
        );
        return;
      }
      _goToStep(3);
    } else if (widget.isCommerce && _currentStep == 3) {
      if (_step4FormKey.currentState?.validate() != true ||
          _selectedCity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completa la dirección del establecimiento (país, estado, ciudad y dirección).'),
          ),
        );
        return;
      }
      await _handleSubmitCommerce();
    }
  }

  Future<void> _handleSubmit() async {
    final onboarding = context.read<OnboardingProvider>();

    setState(() => _isSubmitting = true);
    bool dialogShown = false;

    try {
      final userProvider = context.read<UserProvider>();
      int userId = userProvider.userId;

      if (userId <= 0) {
        try {
          final details = await userProvider.getUserDetails(forceRefresh: true);
          userId = details['userId'] ?? userProvider.userId;
        } catch (_) {}
      }

      if (userId <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo identificar tu cuenta. Cierra sesión e inicia de nuevo.'),
            ),
          );
        }
        return;
      }

      // Validar foto antes de llamar a la API
      if (_selectedPhoto == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agrega una foto de perfil para continuar.'),
            ),
          );
        }
        return;
      }

      // Mostrar diálogo de carga solo después de validar userId
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      dialogShown = true;

      // 1) Crear perfil
      final profile = Profile(
        id: 0,
        userId: userId,
        firstName: onboarding.firstName ?? _firstNameController.text.trim(),
        middleName: onboarding.middleName ?? '',
        lastName: onboarding.lastName ?? _lastNameController.text.trim(),
        secondLastName: onboarding.secondLastName ?? _secondLastNameController.text.trim(),
        photo: null,
        dateOfBirth: (onboarding.dateOfBirth ?? _birthDate)!
            .toIso8601String()
            .split('T')
            .first,
        maritalStatus: 'single',
        sex: onboarding.sex ?? _selectedSex ?? 'M',
        status: 'notverified',
        phone: null,
        address: null,
        businessName: null,
        businessType: null,
        taxId: null,
        vehicleType: null,
        licenseNumber: null,
      );

      final profileService = ProfileService();
      final profileId = await profileService.createProfile(
        profile,
        userId,
        imageFile: File(_selectedPhoto!.path),
      );
      if (profileId <= 0) {
        throw Exception('No se pudo obtener el perfil.');
      }

      // 2) Crear dirección
      final address = Address(
        id: null,
        street: onboarding.street ?? _streetController.text.trim(),
        houseNumber: onboarding.houseNumber ?? _houseNumberController.text.trim(),
        postalCode: onboarding.postalCode ?? _postalCodeController.text.trim(),
        latitude: onboarding.latitude ?? _latitude ?? 0.0,
        longitude: onboarding.longitude ?? _longitude ?? 0.0,
        status: 'notverified',
        profileId: profileId,
        cityId: onboarding.cityId ?? _cityId ?? 0,
      );
      final addressService = AddressService();
      await addressService.createAddress(address, userId);

      // 3) Crear teléfono (exactamente 7 dígitos)
      final number = _phoneController.text.trim();
      if (number.length == 7) {
        final op = _selectedOperator ?? (_operatorCodes.isNotEmpty ? _operatorCodes.first : null);
        final operatorId = op?['id'] ?? 0;
        final operatorName = op?['code']?.toString() ?? op?['name']?.toString() ?? '';

        if (operatorId > 0) {
          final phone = Phone(
            id: 0,
            profileId: profileId,
            operatorCodeId: operatorId is int ? operatorId : int.tryParse(operatorId.toString()) ?? 0,
            operatorCodeName: operatorName,
            number: number,
            isPrimary: true,
            status: true,
          );
          final phoneService = PhoneService();
          await phoneService.createPhone(phone, userId);
          userProvider.setPhoneCreated(true);
        }
      }

      // 4) Flujo comprador: marcar onboarding completado y llevar al MainRouter
      if (!mounted) return;
      if (dialogShown) Navigator.of(context).pop();

      final onboardingService = OnboardingService();
      await onboardingService.completeOnboarding(userId, role: 'users');
      userProvider.setCompletedOnboarding(true);
      onboarding.setRole('users');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onboarding completado exitosamente.'),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainRouter()),
        (route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint('Onboarding error: $e');
      debugPrint('$stackTrace');
      if (!mounted) return;
      if (dialogShown) {
        try { Navigator.of(context).pop(); } catch (_) {}
      }
      final message = _userFriendlyErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Flujo comercio: guarda todo al final (perfil, dirección dueño, teléfono, comercio, dirección establecimiento).
  Future<void> _handleSubmitCommerce() async {
    final onboarding = context.read<OnboardingProvider>();

    setState(() => _isSubmitting = true);
    bool dialogShown = false;

    try {
      final userProvider = context.read<UserProvider>();
      int userId = userProvider.userId;
      if (userId <= 0) {
        try {
          final details = await userProvider.getUserDetails(forceRefresh: true);
          userId = details['userId'] ?? userProvider.userId;
        } catch (_) {}
      }
      if (userId <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo identificar tu cuenta. Cierra sesión e inicia de nuevo.'),
            ),
          );
        }
        return;
      }
      if (_selectedPhoto == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agrega una foto de perfil para continuar.'),
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      dialogShown = true;

      // 1) Crear perfil
      final profile = Profile(
        id: 0,
        userId: userId,
        firstName: onboarding.firstName ?? _firstNameController.text.trim(),
        middleName: onboarding.middleName ?? '',
        lastName: onboarding.lastName ?? _lastNameController.text.trim(),
        secondLastName: onboarding.secondLastName ?? _secondLastNameController.text.trim(),
        photo: null,
        dateOfBirth: (onboarding.dateOfBirth ?? _birthDate)!.toIso8601String().split('T').first,
        maritalStatus: 'single',
        sex: onboarding.sex ?? _selectedSex ?? 'M',
        status: 'notverified',
        phone: null,
        address: null,
        businessName: null,
        businessType: null,
        taxId: null,
        vehicleType: null,
        licenseNumber: null,
      );
      final profileService = ProfileService();
      final profileId = await profileService.createProfile(
        profile,
        userId,
        imageFile: File(_selectedPhoto!.path),
      );
      if (profileId <= 0) throw Exception('No se pudo obtener el perfil.');

      // 2) Dirección del dueño (formulario 2)
      final addressOwner = Address(
        id: null,
        street: onboarding.street ?? _streetController.text.trim(),
        houseNumber: onboarding.houseNumber ?? _houseNumberController.text.trim(),
        postalCode: onboarding.postalCode ?? _postalCodeController.text.trim(),
        latitude: onboarding.latitude ?? _latitude ?? 0.0,
        longitude: onboarding.longitude ?? _longitude ?? 0.0,
        status: 'notverified',
        profileId: profileId,
        cityId: onboarding.cityId ?? _cityId ?? 0,
      );
      final addressService = AddressService();
      await addressService.createAddress(addressOwner, userId);

      // 3) Teléfono
      final number = _phoneController.text.trim();
      if (number.length == 7) {
        final op = _selectedOperator ?? (_operatorCodes.isNotEmpty ? _operatorCodes.first : null);
        final operatorId = op?['id'] ?? 0;
        final operatorName = op?['code']?.toString() ?? op?['name']?.toString() ?? '';
        if (operatorId > 0) {
          final phone = Phone(
            id: 0,
            profileId: profileId,
            operatorCodeId: operatorId is int ? operatorId : int.tryParse(operatorId.toString()) ?? 0,
            operatorCodeName: operatorName,
            number: number,
            isPrimary: true,
            status: true,
          );
          final phoneService = PhoneService();
          await phoneService.createPhone(phone, userId);
          userProvider.setPhoneCreated(true);
        }
      }

      // 4) Crear comercio (tabla commerces; la dirección va en addresses con role commerce)
      final addressEstablishmentStr = '${_streetController.text.trim()} ${_houseNumberController.text.trim()}'.trim();
      // Teléfono del comercio: mismo formato que el del usuario (0 + código + 7 dígitos)
      String commercePhone = _commercePhoneController.text.trim();
      final opCommerce = _selectedOperator ?? (_operatorCodes.isNotEmpty ? _operatorCodes.first : null);
      final opCode = opCommerce?['code']?.toString();
      if (opCode != null && opCode.isNotEmpty && commercePhone.length == 7) {
        commercePhone = '0$opCode$commercePhone';
      }
      final commerceResult = await CommerceDataService.createCommerceForExistingProfile(
        profileId,
        {
          'business_name': _commerceNameController.text.trim(),
          'business_type': 'Restaurante',
          'tax_id': _commerceTaxIdController.text.trim().isEmpty
              ? 'N/A'
              : _commerceTaxIdController.text.trim(),
          'address': addressEstablishmentStr,
          'open': _commerceOpen,
          'schedule': _commerceSchedule.isEmpty ? '' : jsonEncode(_commerceSchedule),
          'owner_ci': _commerceOwnerCiController.text.trim(),
        },
      );
      if (commerceResult['success'] != true) {
        throw Exception(commerceResult['message'] ?? 'No se pudo registrar el comercio');
      }
      // Id del comercio recién creado para vincular la dirección del establecimiento.
      final commerceId = commerceResult['data']?['id'] is int
          ? commerceResult['data']['id'] as int
          : (commerceResult['data']?['id'] != null
              ? int.tryParse(commerceResult['data']['id'].toString())
              : null);

      // 5) Dirección del establecimiento (formulario 4) en addresses con role commerce y commerce_id.
      final addressEstablishment = Address(
        id: null,
        street: _streetController.text.trim(),
        houseNumber: _houseNumberController.text.trim().isEmpty ? '' : _houseNumberController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty ? '' : _postalCodeController.text.trim(),
        latitude: _latitude ?? 0.0,
        longitude: _longitude ?? 0.0,
        status: 'notverified',
        profileId: profileId,
        cityId: _selectedCity?.id ?? _cityId ?? 0,
      );
      await addressService.createAddress(
        addressEstablishment,
        userId,
        role: 'commerce',
        commerceId: commerceId,
      );

      if (!mounted) return;
      if (dialogShown) Navigator.of(context).pop();

      final onboardingService = OnboardingService();
      await onboardingService.completeOnboarding(userId, role: 'commerce');
      userProvider.setCompletedOnboarding(true);
      onboarding.setRole('commerce');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comercio registrado. Onboarding completado.'),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainRouter()),
        (route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint('Onboarding commerce error: $e');
      debugPrint('$stackTrace');
      if (!mounted) return;
      if (dialogShown) {
        try { Navigator.of(context).pop(); } catch (_) {}
      }
      final message = _userFriendlyErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Convierte excepciones de API/red en mensajes entendibles para el usuario.
  String _userFriendlyErrorMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection') || msg.contains('Failed host lookup')) {
      return 'Sin conexión. Revisa tu internet e intenta de nuevo.';
    }
    if (msg.contains('401') || msg.contains('Unauthorized')) {
      return 'Sesión expirada. Cierra sesión e inicia de nuevo.';
    }
    if (msg.contains('409')) {
      return 'Ya tienes datos registrados. Si el problema continúa, contacta soporte.';
    }
    if (msg.contains('(401)') || msg.contains('Unauthenticated')) {
      return 'Sesión expirada o no autorizado. Cierra sesión e inicia de nuevo.';
    }
    if (msg.contains('(404)')) {
      return 'No se encontró la ruta del servidor. Revisa que la API esté en /api/profiles/add-commerce.';
    }
    // Errores específicos por área
    if (msg.contains('Error al crear el perfil') || msg.contains('profiles')) {
      return 'Hubo un problema al guardar tus datos personales. Revisa nombre, fecha de nacimiento y género.';
    }
    if (msg.contains('Error al crear comercio') || msg.contains('add-commerce')) {
      return 'Hubo un problema al registrar el comercio. Revisa nombre, RIF y dirección del local.';
    }
    if (msg.contains('Error al crear dirección') || msg.contains('/buyer/addresses')) {
      return 'Hubo un problema con tu dirección. Revisa país, estado, ciudad y calle antes de intentar de nuevo.';
    }
    if (msg.contains('Error al crear teléfono')) {
      return 'Hubo un problema al guardar tu teléfono. Verifica el código 0XXX y el número de 7 dígitos.';
    }
    if (msg.contains('400')) {
      return 'Hay datos no válidos. Revisa teléfono y dirección e intenta de nuevo.';
    }
    if (msg.contains('422') || msg.contains('validation')) {
      return 'Revisa los datos ingresados e intenta de nuevo.';
    }
    if (msg.contains('500') || msg.contains('Server')) {
      return 'Error del servidor. Intenta más tarde.';
    }
    if (e is Exception && msg.length < 120) return msg;
    return 'No se pudo completar el registro. Intenta de nuevo.';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  // Colores Stitch (6) - Datos Personales
  static const Color _kBackgroundDark = Color(0xFF101922);
  static const Color _kSurfaceDark = Color(0xFF1A2633);
  static const Color _kPrimary = Color(0xFF3399FF);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final progress = (_currentStep + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: _kBackgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header: back + título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: _kSurfaceDark,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _currentStep == 0 ? 'Datos Personales' : _stepTitle(_currentStep),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Paso ${_currentStep + 1} de $_totalSteps',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: _kSurfaceDark,
                      valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: widget.isCommerce
                    ? [
                        _buildStep1(size),
                        _buildStep2(size),
                        _buildStep3Commerce(size),
                        _buildStep4Address(size),
                      ]
                    : [
                        _buildStep1(size),
                        _buildStep2(size),
                      ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _kBackgroundDark.withValues(alpha: 0),
              _kBackgroundDark,
            ],
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _kPrimary.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentStep < _totalSteps - 1 ? 'Siguiente' : 'Finalizar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stepTitle(int step) {
    if (widget.isCommerce) {
      switch (step) {
        case 1: return 'Dirección';
        case 2: return 'Datos del Comercio';
        case 3: return 'Dirección del Establecimiento';
      }
    } else {
      if (step == 1) return 'Dirección';
    }
    return 'Datos Personales';
  }

  Widget _buildStep1(Size size) {
    final isTablet = size.width > 600;
    final isSmall = size.width < 360;
    final inputPadding = EdgeInsets.symmetric(
      horizontal: isTablet ? 20 : (isSmall ? 12 : 16),
      vertical: isSmall ? 12 : 14,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : (isSmall ? 16 : 24),
        vertical: isSmall ? 12 : 16,
      ),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: isSmall ? 8 : 16),
            // Profile photo placeholder (Stitch 6)
            Center(
              child: GestureDetector(
                onTap: _pickProfilePhoto,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: isSmall ? 96 : 112,
                      height: isSmall ? 96 : 112,
                      decoration: BoxDecoration(
                        color: _kSurfaceDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: _selectedPhoto != null
                          ? ClipOval(
                              child: Image.file(
                                File(_selectedPhoto!.path),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: isSmall ? 40 : 48,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(isSmall ? 6 : 8),
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _kBackgroundDark,
                            width: 4,
                          ),
                        ),
                        child: Icon(
                          Icons.photo_camera,
                          color: Colors.white,
                          size: isSmall ? 18 : 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ¡Hola! Empecemos.
            Text(
              '¡Hola! Empecemos.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa tus datos para crear tu experiencia única en Zonix Eats.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            // Nombre + Apellido (grid 2 cols)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDarkInput(
                    label: 'Nombre',
                    controller: _firstNameController,
                    hint: 'Juan',
                    onChanged: (v) {
                      final n = _normalizeName(v);
                      if (n != v) {
                        _firstNameController.value = TextEditingValue(
                          text: n,
                          selection: TextSelection.collapsed(offset: n.length),
                        );
                      }
                    },
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                  ),
                ),
                SizedBox(width: isSmall ? 12 : 16),
                Expanded(
                  child: _buildDarkInput(
                    label: 'Apellido',
                    controller: _lastNameController,
                    hint: 'Pérez',
                    onChanged: (v) {
                      final n = _normalizeName(v);
                      if (n != v) {
                        _lastNameController.value = TextEditingValue(
                          text: n,
                          selection: TextSelection.collapsed(offset: n.length),
                        );
                      }
                    },
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Ingresa tu apellido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Fecha de Nacimiento
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    'Fecha de Nacimiento',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                InkWell(
                  onTap: _pickBirthDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      hintText: 'mm/dd/yyyy',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                      ),
                      contentPadding: inputPadding,
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _birthDate == null
                          ? ''
                          : '${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.year}',
                      style: GoogleFonts.plusJakartaSans(
                        color: _birthDate == null
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Sexo dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    'Sexo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedSex,
                  isExpanded: true,
                  dropdownColor: _kSurfaceDark,
                  icon: Icon(Icons.expand_more, color: Colors.white.withValues(alpha: 0.6)),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                    ),
                    contentPadding: inputPadding,
                  ),
                  hint: Text(
                    'Selecciona tu sexo',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'M', child: Text('Masculino', style: TextStyle(color: Colors.white))),
                    const DropdownMenuItem(value: 'F', child: Text('Femenino', style: TextStyle(color: Colors.white))),
                    const DropdownMenuItem(value: 'O', child: Text('Otro', style: TextStyle(color: Colors.white))),
                    const DropdownMenuItem(value: 'X', child: Text('Prefiero no decir', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (v) => setState(() => _selectedSex = v),
                  validator: (v) =>
                      v == null ? 'Selecciona tu sexo' : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Teléfono (operator + number)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    'Teléfono',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                if (_isLoadingOperators)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: _kPrimary),
                    ),
                  )
                else if (_operatorCodes.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedOperator,
                          isExpanded: true,
                          dropdownColor: _kSurfaceDark,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          items: _operatorCodes
                              .map(
                                (c) => DropdownMenuItem<Map<String, dynamic>>(
                                  value: c,
                                  child: Text(
                                    '0${c['code'] ?? ''}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          validator: (v) => v == null ? 'Código' : null,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onChanged: (v) => setState(() => _selectedOperator = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(7),
                          ],
                          style: GoogleFonts.plusJakartaSans(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '600 000 000',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                            ),
                            contentPadding: inputPadding,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Ingresa el número';
                            if (v.trim().length != 7) return '7 dígitos';
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }

  // Colores Stitch (7) - Dirección
  static const Color _kAddressPrimary = Color(0xFFFFC105);
  static const Color _kAddressSurface = Color(0xFF252B3B);

  Widget _buildStep2(Size size) {
    final isTablet = size.width > 600;
    final isSmall = size.width < 360;
    final mapHeight = isSmall ? 160.0 : 192.0;

    if (_countries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_countries.isEmpty) {
          _applyCountriesFallback();
          _loadCountries();
        }
      });
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : (isSmall ? 16 : 24),
        vertical: isSmall ? 12 : 16,
      ),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isSmall ? 4 : 8),
            // Título y subtítulo (Stitch 7)
            Text(
              'Dirección de entrega',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¿Dónde debemos llevar tu comida?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: isSmall ? 16 : 24),

            // Mapa con botón "Usar mi ubicación actual"
            _buildMapCardStep2(context, mapHeight),
            const SizedBox(height: 24),

            // Calle
            _buildAddressField(
              label: 'Calle',
              controller: _streetController,
              hint: 'Ej. Avenida Reforma',
              icon: Icons.signpost,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa una dirección';
                if (v.trim().length < 5) return 'La dirección parece muy corta';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Número + Código Postal (grid)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildAddressField(
                    label: 'Número',
                    controller: _houseNumberController,
                    hint: '123',
                    icon: Icons.tag,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: isSmall ? 12 : 16),
                Expanded(
                  child: _buildAddressField(
                    label: 'Código Postal',
                    controller: _postalCodeController,
                    hint: '00000',
                    icon: Icons.markunread_mailbox,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // País
            _buildAddressDropdownCountry(),
            if (_selectedCountry != null) ...[
              const SizedBox(height: 16),
              _buildAddressDropdownState(),
            ],
            if (_selectedState != null) ...[
              const SizedBox(height: 16),
              _buildAddressDropdownCity(),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCardStep2(BuildContext context, [double mapHeight = 192]) {
    final hasCoords = _latitude != null && _longitude != null;
    final centerPoint = latLng.LatLng(
      _latitude ?? 10.4806,
      _longitude ?? -66.9036,
    );

    return Container(
      height: mapHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (hasCoords)
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: centerPoint,
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
                          now.difference(_lastGeocodingCall!).inMilliseconds > 500) {
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
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.zonix.eats',
                  ),
                ],
              )
            else
              Container(
                color: _kAddressSurface,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: _kAddressPrimary),
                    const SizedBox(height: 12),
                    Text(
                      _isLoadingLocation ? 'Obteniendo ubicación...' : 'Esperando ubicación',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            // Overlay gradiente (IgnorePointer para no bloquear arrastre del mapa)
            if (hasCoords)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          _kBackgroundDark.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Pin amarillo central (IgnorePointer para no bloquear arrastre del mapa)
            if (hasCoords)
              IgnorePointer(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _kAddressPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _kAddressPrimary.withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFF1A1F2B),
                          size: 28,
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 6,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.4)),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kAddressPrimary, width: 2),
            ),
            filled: true,
            fillColor: _kAddressSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: keyboardType,
        ),
      ],
    );
  }

  Widget _buildAddressDropdownCountry() {
    return _buildAddressDropdownWrapper(
      label: 'País',
      icon: Icons.public,
      child: DropdownButtonFormField<Country>(
        value: _selectedCountry,
        isExpanded: true,
        dropdownColor: _kAddressSurface,
        icon: Icon(Icons.expand_more, color: Colors.white.withValues(alpha: 0.6)),
        decoration: _addressInputDecoration(prefixIcon: Icons.public),
        items: _countries
            .map(
              (c) => DropdownMenuItem<Country>(
                value: c,
                child: Text(c.name, style: const TextStyle(color: Colors.white)),
              ),
            )
            .toList(),
        onChanged: (v) => _onCountryChanged(v),
        validator: (v) => v == null ? 'Selecciona un país' : null,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  Widget _buildAddressDropdownState() {
    return _buildAddressDropdownWrapper(
      label: 'Estado',
      icon: Icons.map_outlined,
      child: DropdownButtonFormField<StateModel>(
        value: _selectedState,
        isExpanded: true,
        dropdownColor: _kAddressSurface,
        icon: Icon(Icons.expand_more, color: Colors.white.withValues(alpha: 0.6)),
        decoration: _addressInputDecoration(prefixIcon: Icons.map_outlined),
        items: _states
            .map(
              (s) => DropdownMenuItem<StateModel>(
                value: s,
                child: Text(s.name, style: const TextStyle(color: Colors.white)),
              ),
            )
            .toList(),
        onChanged: (v) => _onStateChanged(v),
        validator: (v) => v == null ? 'Selecciona un estado' : null,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  Widget _buildAddressDropdownCity() {
    return _buildAddressDropdownWrapper(
      label: 'Ciudad',
      icon: Icons.apartment,
      child: DropdownButtonFormField<City>(
        value: _selectedCity,
        isExpanded: true,
        dropdownColor: _kAddressSurface,
        icon: Icon(Icons.expand_more, color: Colors.white.withValues(alpha: 0.6)),
        decoration: _addressInputDecoration(prefixIcon: Icons.apartment),
        items: _cities
            .map(
              (c) => DropdownMenuItem<City>(
                value: c,
                child: Text(c.name, style: const TextStyle(color: Colors.white)),
              ),
            )
            .toList(),
        onChanged: (v) => _onCityChanged(v),
        validator: (v) => v == null ? 'Selecciona una ciudad' : null,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  Widget _buildAddressDropdownWrapper({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
        child,
      ],
    );
  }

  InputDecoration _addressInputDecoration({required IconData prefixIcon}) {
    return InputDecoration(
      prefixIcon: Icon(
        prefixIcon,
        size: 20,
        color: Colors.white.withValues(alpha: 0.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kAddressPrimary, width: 2),
      ),
      filled: true,
      fillColor: _kAddressSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  /// Input estilo Stitch 8: icono a la izquierda, fondo oscuro, rounded-2xl
  Widget _buildCommerceInput({
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(
            icon,
            size: 22,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        filled: true,
        fillColor: _kSurfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildStep3Commerce(Size size) {
    final isTablet = size.width > 600;
    final isSmall = size.width < 360;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : (isSmall ? 16 : 24),
        vertical: isSmall ? 12 : 16,
      ),
      child: Form(
        key: _step3FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isSmall ? 4 : 8),
            // Sección: Basic Info (estilo Stitch 8)
            // Nombre del local
            _buildCommerceInput(
              icon: Icons.storefront_outlined,
              controller: _commerceNameController,
              hint: 'Nombre del local',
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'El nombre del local es obligatorio';
                if (text.length < 3) return 'Mínimo 3 caracteres';
                if (text.length > 150) return 'Máximo 150 caracteres';
                if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s\-.]+$').hasMatch(text)) {
                  return 'Caracteres no válidos';
                }
                return null;
              },
            ),
            SizedBox(height: isSmall ? 12 : 16),
            // RIF (Opcional)
            _buildCommerceInput(
              icon: Icons.badge_outlined,
              controller: _commerceTaxIdController,
              hint: 'RIF / NIT (Opcional) - Ej: J-12345678-9',
              inputFormatters: [_RIFVenezuelaInputFormatter()],
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final rif = value.trim().toUpperCase();
                  final rifRegex = RegExp(r'^(V|J)-\d{8}-\d$');
                  if (!rifRegex.hasMatch(rif)) return 'Formato: V-12345678-9 o J-12345678-9';
                  final digits = rif.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.length != 9) return 'Debe tener 9 dígitos';
                }
                return null;
              },
            ),
            SizedBox(height: isSmall ? 12 : 16),
            // CI *
            _buildCommerceInput(
              icon: Icons.person_outline,
              controller: _commerceOwnerCiController,
              hint: 'CI del titular - V-12345678',
              keyboardType: TextInputType.number,
              inputFormatters: [_CIVenezuelaInputFormatter()],
              onChanged: (value) {
                if (!value.startsWith('V-')) {
                  _commerceOwnerCiController.value = TextEditingValue(
                    text: 'V-',
                    selection: const TextSelection.collapsed(offset: 2),
                  );
                }
              },
              validator: (value) {
                final ci = (value ?? '').trim().toUpperCase();
                if (ci.isEmpty || ci == 'V-') return 'La CI es obligatoria';
                if (!RegExp(r'^[VE]-\d{7,8}$').hasMatch(ci)) {
                  return 'Formato: V-12345678 o E-12345678';
                }
                return null;
              },
            ),
            SizedBox(height: isSmall ? 12 : 16),
            // Teléfono del local (Código + Número)
            if (_isLoadingOperators)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: _kPrimary.withValues(alpha: 0.8)),
                ),
              )
            else if (_operatorCodes.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedOperator,
                      isExpanded: true,
                      dropdownColor: _kSurfaceDark,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.6)),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 8),
                          child: Icon(
                            Icons.phone_outlined,
                            size: 22,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 44),
                        filled: true,
                        fillColor: _kSurfaceDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _kPrimary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      hint: Text(
                        'Código',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      items: _operatorCodes
                          .map(
                            (code) => DropdownMenuItem<Map<String, dynamic>>(
                              value: code,
                              child: Text(
                                '0${code['code'] ?? ''}',
                                style: GoogleFonts.plusJakartaSans(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      validator: (v) => v == null ? 'Código' : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (v) => setState(() => _selectedOperator = v),
                    ),
                  ),
                  SizedBox(width: isSmall ? 12 : 16),
                  Expanded(
                    flex: 2,
                    child: _buildCommerceInput(
                      icon: Icons.smartphone_outlined,
                      controller: _commercePhoneController,
                      hint: 'Teléfono del local',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(7),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el teléfono';
                        }
                        if (value.trim().length != 7) return '7 dígitos';
                        return null;
                      },
                    ),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
            SizedBox(height: isSmall ? 20 : 24),
            // Sección: Estado de la tienda (card estilo Stitch 8)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: _kSurfaceDark,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.door_front_door_outlined, color: _kPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado de la tienda',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Abierto para recibir pedidos',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _commerceOpen,
                    onChanged: (v) => setState(() => _commerceOpen = v),
                    activeColor: _kPrimary,
                    activeTrackColor: _kPrimary.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmall ? 12 : 16),
            // Sección: Horarios de atención (expandable estilo Stitch 8)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: _kSurfaceDark,
                collapsedBackgroundColor: _kSurfaceDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.schedule, color: Colors.white.withValues(alpha: 0.7), size: 22),
                ),
                title: Text(
                  'Horarios de atención',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                trailing: Icon(
                  Icons.expand_more,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        Text(
                          'Edita el horario en el siguiente paso o desde tu panel de comercio.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: _kPrimary.withValues(alpha: 0.15),
                              foregroundColor: _kPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Editar Horario Semanal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmall ? 20 : 24),
            // Sección: Información de Pago (estilo Stitch 8)
            Text(
              'Información de Pago',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, color: _kPrimary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tus datos bancarios están protegidos. Usamos encriptación de grado bancario para todas las transacciones.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Address(Size size) {
    final isTablet = size.width > 600;
    final isSmall = size.width < 360;
    final mapHeight = isSmall ? 180.0 : 220.0;

    if (_countries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_countries.isEmpty) {
          _applyCountriesFallback();
          _loadCountries();
        }
      });
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : (isSmall ? 16 : 24),
        vertical: isSmall ? 12 : 16,
      ),
      child: Form(
        key: _step4FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isSmall ? 4 : 8),
            _buildMapCard(context, mapHeight),
            const SizedBox(height: 24),
            _buildSectionHeader(
              icon: Icons.public,
              label: 'UBICACIÓN REGIONAL',
              color: _kPrimary,
              darkStyle: true,
            ),
            const SizedBox(height: 12),
            _buildTwoColumnRow(
              _buildCountryDropdownDark(),
              _selectedCountry != null
                  ? _buildStateDropdownDark()
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            _buildTwoColumnRow(
              _selectedState != null
                  ? _buildCityDropdownDark()
                  : const SizedBox.shrink(),
              const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(
              icon: Icons.location_on_outlined,
              label: 'DETALLES DE LA DIRECCIÓN',
              color: _kPrimary,
              darkStyle: true,
            ),
            const SizedBox(height: 12),
            _buildCommerceInput(
              icon: Icons.signpost_outlined,
              controller: _streetController,
              hint: 'Ej: Av. Principal, Local 1',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa una dirección';
                if (v.trim().length < 5) return 'La dirección parece muy corta';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildCommerceInput(
              icon: Icons.tag_outlined,
              controller: _houseNumberController,
              hint: 'Número / Local',
            ),
            const SizedBox(height: 12),
            _buildCommerceInput(
              icon: Icons.markunread_mailbox_outlined,
              controller: _postalCodeController,
              hint: 'Código postal',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeName(String input) {
    final cleaned =
        input.replaceAll(RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'), '');
    final parts = cleaned.toLowerCase().trim().split(RegExp(r'\s+'));
    return parts
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Widget _buildMapCard(BuildContext context, [double mapHeight = 220]) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(20);

    final hasCoords = _latitude != null && _longitude != null;
    final centerPoint = latLng.LatLng(
      _latitude ?? 10.4806,
      _longitude ?? -66.9036,
    );

    return Container(
      height: mapHeight,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            if (hasCoords)
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: centerPoint,
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
                          now.difference(_lastGeocodingCall!).inMilliseconds > 500) {
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.zonix.eats',
                  ),
                ],
              )
            else
              Container(
                color: colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isLoadingLocation ? 'Obteniendo ubicación...' : 'Esperando ubicación',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            if (hasCoords)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: colorScheme.primary,
                      size: 46,
                    ),
                    Container(
                      width: 16,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                ),
                child: const Text(
                  'Ubicación del PIN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Material(
                color: Colors.white,
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
                    child: Icon(
                      Icons.my_location,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String label,
    required Color color,
    bool darkStyle = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: darkStyle ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF1B1B1F),
          ),
        ),
      ],
    );
  }

  InputDecoration _commerceDropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.6)),
      filled: true,
      fillColor: _kSurfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildCountryDropdownDark() {
    return DropdownButtonFormField<Country>(
      value: _selectedCountry,
      isExpanded: true,
      dropdownColor: _kSurfaceDark,
      decoration: _commerceDropdownDecoration('País'),
      icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.6)),
      items: _countries
          .map(
            (c) => DropdownMenuItem<Country>(
              value: c,
              child: Text(
                c.name,
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: (value) => _onCountryChanged(value),
      validator: (value) => value == null ? 'Selecciona un país' : null,
    );
  }

  Widget _buildStateDropdownDark() {
    return DropdownButtonFormField<StateModel>(
      value: _selectedState,
      isExpanded: true,
      dropdownColor: _kSurfaceDark,
      decoration: _commerceDropdownDecoration('Estado'),
      icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.6)),
      items: _states
          .map(
            (s) => DropdownMenuItem<StateModel>(
              value: s,
              child: Text(
                s.name,
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: (value) => _onStateChanged(value),
      validator: (value) => value == null ? 'Selecciona un estado' : null,
    );
  }

  Widget _buildCityDropdownDark() {
    return DropdownButtonFormField<City>(
      value: _selectedCity,
      isExpanded: true,
      dropdownColor: _kSurfaceDark,
      decoration: _commerceDropdownDecoration('Ciudad'),
      icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.6)),
      items: _cities
          .map(
            (c) => DropdownMenuItem<City>(
              value: c,
              child: Text(
                c.name,
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: (value) => _onCityChanged(value),
      validator: (value) => value == null ? 'Selecciona una ciudad' : null,
    );
  }

  Widget _buildTwoColumnRow(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }

}

/// Formatter para CI venezolana (V-12345678) inspirado en CorralX.
class _CIVenezuelaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.toUpperCase();

    // Asegurar prefijo V-
    if (!text.startsWith('V-')) {
      text = 'V-';
    }

    // Tomar solo dígitos después de V-
    final digits = text.substring(2).replaceAll(RegExp(r'[^0-9]'), '');

    // Limitar a 8 dígitos
    final limitedDigits =
        digits.length > 8 ? digits.substring(0, 8) : digits;

    final result = 'V-$limitedDigits';

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

/// Formatter para RIF venezolano (V- o J-12345678-9) copiado de CorralX.
class _RIFVenezuelaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.toUpperCase();

    if (text.isEmpty) {
      return newValue;
    }

    final isDeleting = newValue.text.length < oldValue.text.length;

    if (isDeleting && (text.length <= 2 || text == 'V' || text == 'J')) {
      if (text == 'V') {
        return TextEditingValue(
          text: 'V-',
          selection: const TextSelection.collapsed(offset: 2),
        );
      } else if (text == 'J') {
        return TextEditingValue(
          text: 'J-',
          selection: const TextSelection.collapsed(offset: 2),
        );
      }
      if (text.length <= 1) {
        return newValue;
      }
    }

    String? prefix;
    if (text.startsWith('V-')) {
      prefix = 'V-';
    } else if (text.startsWith('J-')) {
      prefix = 'J-';
    } else if (text.startsWith('V')) {
      return TextEditingValue(
        text: 'V-',
        selection: const TextSelection.collapsed(offset: 2),
      );
    } else if (text.startsWith('J')) {
      return TextEditingValue(
        text: 'J-',
        selection: const TextSelection.collapsed(offset: 2),
      );
    } else {
      return oldValue;
    }

    String numbers = text.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbers.length > 9) {
      numbers = numbers.substring(0, 9);
    }

    if (numbers.isEmpty) {
      return TextEditingValue(
        text: prefix,
        selection: TextSelection.collapsed(offset: prefix.length),
      );
    }

    String formattedText;
    if (numbers.length <= 8) {
      formattedText = '$prefix$numbers';
    } else {
      formattedText =
          '$prefix${numbers.substring(0, 8)}-${numbers.substring(8)}';
    }

    final cursorPosition = formattedText.length;

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
