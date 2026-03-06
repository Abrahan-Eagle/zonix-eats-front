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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.scaffoldBgLight,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final fgColor = AppColors.primaryText(context);
    final barBg = Theme.of(context).brightness == Brightness.dark
        ? AppColors.backgroundDark
        : AppColors.scaffoldBgLight;
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: barBg,
      foregroundColor: fgColor,
      title: Text(
        'Registrar Dirección',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: fgColor,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _captureLocation,
          icon: _isLocationLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  ),
                )
              : Icon(Icons.my_location, color: fgColor),
          tooltip: 'Capturar ubicación',
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
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
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
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add_location_alt,
            size: 48,
            color: AppColors.blue,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Registra tu nueva dirección',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa los detalles para tus entregas de Zonix Eats.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.secondaryText(context),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLocationStatus() {
    if (latitude != null && longitude != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.my_location, color: AppColors.green, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ubicación capturada',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lat: ${latitude!.toStringAsFixed(4)}, Long: ${longitude!.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.green.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off, color: AppColors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ubicación no disponible. Usa el ícono de arriba para capturar.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.orange,
                fontWeight: FontWeight.w500,
              ),
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
        icon: Icon(Icons.arrow_drop_down, color: AppColors.blue),
        isExpanded: true,
        menuMaxHeight: menuHeight,
        borderRadius: BorderRadius.circular(12),
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
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.blue),
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
        controller: _postalCodeController,
        decoration: InputDecoration(
          labelText: 'Código Postal',
          hintText: '1010',
          prefixIcon: Icon(Icons.mail, color: AppColors.blue),
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
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppColors.blue,
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
