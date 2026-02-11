import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:image_picker/image_picker.dart';

import 'onboarding_provider.dart';
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
class ClientOnboardingFlow extends StatefulWidget {
  const ClientOnboardingFlow({super.key});

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

  // STEP 3 – Teléfono
  final _phoneController = TextEditingController();
  List<Map<String, dynamic>> _operatorCodes = [];
  Map<String, dynamic>? _selectedOperator;
  bool _isLoadingOperators = false;

  // Foto y términos
  XFile? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _prefillFromProvider();
    _loadCountries();
    _getCurrentLocation();
    _loadOperatorCodes();
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
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _secondLastNameController.dispose();
    _streetController.dispose();
    _houseNumberController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _mapController.dispose();
    super.dispose();
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
    }
  }

  void _onCityChanged(City? value) {
    setState(() {
      _selectedCity = value;
      _cityId = value?.id;
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
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
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

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

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
        sex: _selectedSex!,
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

      await _handleSubmit();
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

      // 4) Marcar onboarding completado
      final onboardingService = OnboardingService();
      await onboardingService.completeOnboarding(userId, role: 'users');
      userProvider.setCompletedOnboarding(true);

      onboarding.setRole('users');

      if (!mounted) return;
      if (dialogShown) Navigator.of(context).pop(); // Cerrar solo el diálogo de progreso

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onboarding completado exitosamente.'),
        ),
      );

      if (!mounted) return;
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
    // Errores específicos por área
    if (msg.contains('Error al crear el perfil') || msg.contains('profiles')) {
      return 'Hubo un problema al guardar tus datos personales. Revisa nombre, fecha de nacimiento y género.';
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu cuenta Zonix Eats'),
        automaticallyImplyLeading: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / 2,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Paso ${_currentStep + 1} de 2'),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(size),
                _buildStep2(size),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleNext,
              child: Text(
                _currentStep < 1 ? 'Continuar' : 'Finalizar',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(Size size) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const primaryColor = Color(0xFFF18805);
    final isTablet = size.width > 600;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : 16,
        vertical: 16,
      ),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Cabecera tipo CorralX: icono + título + subtítulo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: colorScheme.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cuéntanos más de ti',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Completa tus datos para terminar de crear tu cuenta. Los campos con * son obligatorios.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¿Cómo te llamas?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _firstNameController,
              onChanged: (value) {
                final normalized = _normalizeName(value);
                if (normalized != value) {
                  _firstNameController.value = TextEditingValue(
                    text: normalized,
                    selection: TextSelection.collapsed(offset: normalized.length),
                  );
                }
              },
              decoration: InputDecoration(
                labelText: 'Nombre(s) *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.error, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 16,
                  vertical: isTablet ? 20 : 16,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tu nombre';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameController,
              onChanged: (value) {
                final normalized = _normalizeName(value);
                if (normalized != value) {
                  _lastNameController.value = TextEditingValue(
                    text: normalized,
                    selection: TextSelection.collapsed(offset: normalized.length),
                  );
                }
              },
              decoration: InputDecoration(
                labelText: 'Apellido(s) *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.error, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 16,
                  vertical: isTablet ? 20 : 16,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tu apellido';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 24),
            Text(
              '¿Cuándo naciste?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickBirthDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: 'DD/MM/AAAA',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : 16,
                    vertical: isTablet ? 20 : 16,
                  ),
                ),
                child: Text(
                  _birthDate == null
                      ? 'Selecciona tu fecha de nacimiento'
                      : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                  style: TextStyle(
                    color: _birthDate == null
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¿Con qué género te identificas?',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildGenderChip('F', 'Femenino'),
                _buildGenderChip('M', 'Masculino'),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Datos de contacto',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Te contactaremos solo si necesitamos comunicarte algo importante sobre tus pedidos.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingOperators)
              const Center(child: CircularProgressIndicator())
            else if (_operatorCodes.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedOperator,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Código de país',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 20 : 16,
                          vertical: isTablet ? 20 : 16,
                        ),
                      ),
                      items: _operatorCodes
                          .map(
                            (code) => DropdownMenuItem<Map<String, dynamic>>(
                              value: code,
                              child: Text(
                                '0${code['code'] ?? ''}',
                              ),
                            ),
                          )
                          .toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona un código';
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (value) {
                        setState(() => _selectedOperator = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _phoneController,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(7),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Número de celular *',
                        hintText: 'Ej: 4149055',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.error, width: 2),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 20 : 16,
                          vertical: isTablet ? 20 : 16,
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa un número de teléfono';
                        }
                        final clean = value.trim();
                        if (clean.length != 7) {
                          return 'Debe tener exactamente 7 dígitos';
                        }
                        // El input formatter ya restringe a dígitos, así que no
                        // es necesario validar caracteres no numéricos aquí.
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            // Foto de perfil (similar a create_profile_page pero simplificada)
            Text(
              'Tu foto de perfil',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: colorScheme.surfaceVariant,
                  backgroundImage: _selectedPhoto != null
                      ? FileImage(File(_selectedPhoto!.path))
                      : null,
                  child: _selectedPhoto == null
                      ? const Icon(Icons.person_outline, size: 32)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Toma una foto clara de tu rostro.'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _pickProfilePhoto,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Tomar foto'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderChip(String value, String label) {
    final isSelected = _selectedSex == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedSex = value);
      },
    );
  }

  Widget _buildStep2(Size size) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const primaryColor = Color(0xFFF18805);
    final isTablet = size.width > 600;

    // Si llegamos al paso de dirección y aún no hay países: mostrar fallback de inmediato y recargar desde API
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
        horizontal: isTablet ? 32 : 16,
        vertical: 16,
      ),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Cabecera tipo CorralX para paso dirección
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: colorScheme.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dirección de entrega',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confirma en el mapa y completa tu dirección principal para tus pedidos.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mapa interactivo con pin centrado
            _buildMapCard(context),
            const SizedBox(height: 24),

            // Sección: UBICACIÓN REGIONAL
            _buildSectionHeader(
              icon: Icons.public,
              label: 'UBICACIÓN REGIONAL',
              color: primaryColor,
            ),
            const SizedBox(height: 12),
            _buildTwoColumnRow(
              _buildCountryDropdown(theme.colorScheme),
              _selectedCountry != null
                  ? _buildStateDropdown(theme.colorScheme)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            _buildTwoColumnRow(
              _selectedState != null
                  ? _buildCityDropdown(theme.colorScheme)
                  : const SizedBox.shrink(),
              const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Sección: DETALLES DE LA DIRECCIÓN
            _buildSectionHeader(
              icon: Icons.location_on_outlined,
              label: 'DETALLES DE LA DIRECCIÓN',
              color: primaryColor,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _streetController,
              decoration: InputDecoration(
                labelText: 'Dirección *',
                hintText: 'Ej: C. las Torres, Urb. Centro',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.error, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 16,
                  vertical: isTablet ? 20 : 16,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa una dirección';
                }
                if (value.trim().length < 5) {
                  return 'La dirección parece muy corta';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _houseNumberController,
              decoration: InputDecoration(
                labelText: 'Número de piso / Apartamento / Casa',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 16,
                  vertical: isTablet ? 20 : 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _postalCodeController,
              decoration: InputDecoration(
                labelText: 'Código postal',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 16,
                  vertical: isTablet ? 20 : 16,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeName(String input) {
    final cleaned =
        input.replaceAll(RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ\\s]'), '');
    final parts = cleaned.toLowerCase().trim().split(RegExp(r'\\s+'));
    return parts
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Widget _buildMapCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(20);

    final hasCoords = _latitude != null && _longitude != null;
    final centerPoint = latLng.LatLng(
      _latitude ?? 10.4806,
      _longitude ?? -66.9036,
    );

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                      final newCenter = _mapController.camera.center;
                      setState(() {
                        _latitude = newCenter.latitude;
                        _longitude = newCenter.longitude;
                      });

                      final now = DateTime.now();
                      if (_lastGeocodingCall == null ||
                          now
                                  .difference(_lastGeocodingCall!)
                                  .inMilliseconds >
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.zonix.eats',
                  ),
                ],
              )
            else
              Container(
                color: colorScheme.surfaceVariant,
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
                        color: Colors.black.withOpacity(0.25),
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
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.7)),
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
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF1B1B1F),
          ),
        ),
      ],
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

  Widget _buildCountryDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<Country>(
      value: _selectedCountry,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'País',
      ),
      items: _countries
          .map(
            (c) => DropdownMenuItem<Country>(
              value: c,
              child: Text(c.name),
            ),
          )
          .toList(),
      onChanged: (value) => _onCountryChanged(value),
      validator: (value) {
        if (value == null) {
          return 'Selecciona un país';
        }
        return null;
      },
    );
  }

  Widget _buildStateDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<StateModel>(
      value: _selectedState,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Estado',
      ),
      items: _states
          .map(
            (s) => DropdownMenuItem<StateModel>(
              value: s,
              child: Text(s.name),
            ),
          )
          .toList(),
      onChanged: (value) => _onStateChanged(value),
      validator: (value) {
        if (value == null) {
          return 'Selecciona un estado';
        }
        return null;
      },
    );
  }

  Widget _buildCityDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<City>(
      value: _selectedCity,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Ciudad',
      ),
      items: _cities
          .map(
            (c) => DropdownMenuItem<City>(
              value: c,
              child: Text(c.name),
            ),
          )
          .toList(),
      onChanged: (value) => _onCityChanged(value),
      validator: (value) {
        if (value == null) {
          return 'Selecciona una ciudad';
        }
        return null;
      },
    );
  }

}

