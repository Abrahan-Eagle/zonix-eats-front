import 'package:flutter/material.dart';
import '../models/adresse.dart';
import '../models/models.dart';
import '../api/adresse_service.dart';
import 'location_module.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:zonix/features/utils/app_colors.dart';

final logger = Logger();

class RegisterAddressScreen extends StatefulWidget {
  final int userId;

  const RegisterAddressScreen({super.key, required this.userId});

  @override
  RegisterAddressScreenState createState() => RegisterAddressScreenState();
}

class RegisterAddressScreenState extends State<RegisterAddressScreen>
    with TickerProviderStateMixin {
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
  bool _isLoading = false;
  bool _isLocationLoading = false;
  bool _isSubmitting = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    logger.i(
        'Console log para verificar el userId al inicio...... Recibiendo userId: ${widget.userId}');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();

    _loadInitialData();
  }

  @override
  void dispose() {
    _streetController.dispose();
    _houseNumberController.dispose();
    _postalCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      await loadCountries();
      await _captureLocation();
    } catch (e) {
      _showError('Error al cargar datos iniciales: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> loadCountries() async {
    try {
      final data = await _addressService.fetchCountries();
      setState(() {
        countries = data;
      });

      if (countries.isNotEmpty) {
        final defaultCountry = countries.firstWhere(
          (country) => country.name == "Venezuela",
          orElse: () => countries.first,
        );

        setState(() {
          selectedCountry = defaultCountry;
        });

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
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: AppColors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _captureLocation() async {
    setState(() => _isLocationLoading = true);

    try {
      Position? position = await _locationModule.getCurrentLocation(context);
      if (position != null) {
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
        });
        _showSuccess('Ubicación capturada exitosamente');
      } else {
        _showError('No se pudo capturar la ubicación automáticamente');
      }
    } catch (e) {
      _showError('Error al capturar ubicación: $e');
    } finally {
      setState(() => _isLocationLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.blue,
      foregroundColor: AppColors.white,
      title: const Text(
        'Registrar Dirección',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      actions: [
        if (latitude != null && longitude != null)
          IconButton(
            onPressed: _captureLocation,
            icon: _isLocationLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : const Icon(Icons.my_location),
            tooltip: 'Actualizar ubicación',
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando formulario...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24.0),
              _buildLocationStatus(),
              const SizedBox(height: 24.0),
              _buildForm(),
              const SizedBox(height: 100), // Espacio para FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Icon(
            Icons.add_location_alt,
            size: 60,
            color: primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Registra tu nueva dirección',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Completa los datos para registrar tu dirección de entrega',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.secondaryText(context),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLocationStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: latitude != null && longitude != null
            ? AppColors.green.withValues(alpha: 0.1)
            : AppColors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: latitude != null && longitude != null
              ? AppColors.green.withValues(alpha: 0.3)
              : AppColors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            latitude != null && longitude != null
                ? Icons.location_on
                : Icons.location_off,
            color: latitude != null && longitude != null
                ? AppColors.green
                : AppColors.orange,
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
                    color: (latitude != null && longitude != null
                            ? AppColors.green
                            : AppColors.orange)
                        .withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  latitude != null && longitude != null
                      ? 'Ubicación capturada'
                      : 'Ubicación no disponible',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: latitude != null && longitude != null
                        ? AppColors.green
                        : AppColors.orange,
                  ),
                ),
                if (latitude != null && longitude != null)
                  Text(
                    '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray,
                    ),
                  ),
              ],
            ),
          ),
          if (latitude == null || longitude == null)
            TextButton.icon(
              onPressed: _captureLocation,
              icon: _isLocationLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 16),
              label: const Text('Capturar'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.orange,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildCountryDropdown(),
          const SizedBox(height: 16.0),
          if (selectedCountry != null) _buildStateDropdown(),
          const SizedBox(height: 16.0),
          if (selectedState != null) _buildCityDropdown(),
          const SizedBox(height: 16.0),
          _buildTextField(
            _streetController,
            'Dirección',
            'Ingresa la dirección completa',
            Icons.home,
            minLength: 10,
            maxLength: 100,
          ),
          const SizedBox(height: 16.0),
          _buildTextField(
            _houseNumberController,
            'Número de Casa',
            'Ingresa el número de la casa',
            Icons.numbers,
            minLength: 1,
            maxLength: 10,
          ),
          const SizedBox(height: 16.0),
          _buildPostalCodeField(),
        ],
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return _buildDropdown<Country>(
      value: selectedCountry,
      hint: 'Selecciona un país',
      items: countries.map((country) {
        return DropdownMenuItem<Country>(
          value: country,
          child: Text(country.name),
        );
      }).toList(),
      onChanged: (Country? newValue) async {
        setState(() {
          selectedCountry = newValue;
          selectedState = null;
          selectedCity = null;
          cities.clear();
        });
        if (newValue != null) {
          await loadStates(newValue.id);
        }
      },
      icon: Icons.public,
      label: 'País',
    );
  }

  Widget _buildStateDropdown() {
    return _buildDropdown<StateModel>(
      value: selectedState,
      hint: 'Selecciona un estado',
      items: states.map((state) {
        return DropdownMenuItem<StateModel>(
          value: state,
          child: Text(state.name),
        );
      }).toList(),
      onChanged: (StateModel? newValue) async {
        setState(() {
          selectedState = newValue;
          selectedCity = null;
          cities.clear();
        });
        if (newValue != null) {
          await loadCities(newValue.id);
        }
      },
      icon: Icons.location_city,
      label: 'Estado',
    );
  }

  Widget _buildCityDropdown() {
    return _buildDropdown<City>(
      value: selectedCity,
      hint: 'Selecciona una ciudad',
      items: cities.map((city) {
        return DropdownMenuItem<City>(
          value: city,
          child: Text(city.name),
        );
      }).toList(),
      onChanged: (City? newValue) {
        setState(() {
          selectedCity = newValue;
        });
      },
      icon: Icons.location_on,
      label: 'Ciudad',
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
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        hint: Text(hint),
        items: items,
        onChanged: onChanged,
        validator: (value) {
          if (value == null) {
            return 'Por favor selecciona un $label';
          }
          return null;
        },
        dropdownColor: AppColors.cardBg(context),
        icon: Icon(Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.primary),
        isExpanded: true,
        menuMaxHeight: 200,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    int? minLength,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        maxLength: maxLength,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingresa $label';
          }
          if (minLength != null && value.length < minLength) {
            return '$label debe tener al menos $minLength caracteres';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPostalCodeField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: TextFormField(
        controller: _postalCodeController,
        decoration: InputDecoration(
          labelText: 'Código Postal',
          hintText: 'Ingresa el código postal',
          prefixIcon:
              Icon(Icons.mail, color: Theme.of(context).colorScheme.primary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 10,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingresa el código postal';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: primary,
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _createAddress,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _isSubmitting
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
                  Text(
                    'Registrando...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_location_alt,
                    color: AppColors.white,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Registrar Dirección',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _createAddress() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Por favor completa todos los campos requeridos');
      return;
    }

    if (latitude == null || longitude == null) {
      _showError('Por favor captura la ubicación antes de continuar');
      return;
    }

    if (selectedCity == null) {
      _showError('Por favor selecciona una ciudad');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final address = Address(
        street: _streetController.text.trim(),
        houseNumber: _houseNumberController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        latitude: latitude!,
        longitude: longitude!,
        status: 'notverified',
        profileId: widget.userId,
        cityId: selectedCity!.id,
      );

      await _addressService.createAddress(address, widget.userId);

      if (mounted) {
        _showSuccess('Dirección registrada exitosamente');
        Navigator.of(context).pop(address);
      }
    } catch (e) {
      _showError('Error al registrar la dirección: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
