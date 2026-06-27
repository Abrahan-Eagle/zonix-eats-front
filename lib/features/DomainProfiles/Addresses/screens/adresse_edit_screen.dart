import 'package:flutter/material.dart';
import '../api/adresse_service.dart';
import '../models/adresse.dart';
import '../models/models.dart';

class EditAddressScreen extends StatefulWidget {
  final int userId;
  final Address address;

  const EditAddressScreen({super.key, required this.userId, required this.address});

  @override
  State<EditAddressScreen> createState() => EditAddressScreenState();
}

class EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _houseController = TextEditingController();
  final _postalController = TextEditingController();
  final _service = AddressService();

  List<Country> _countries = [];
  List<StateModel> _states = [];
  List<City> _cities = [];
  int? _countryId;
  int? _stateId;
  int? _cityId;
  bool _loading = false;
  bool _loadingGeo = true;

  @override
  void initState() {
    super.initState();
    _streetController.text = widget.address.street;
    _houseController.text = widget.address.houseNumber;
    _postalController.text = widget.address.postalCode;
    _cityId = widget.address.cityId;
    _loadCountries();
  }

  @override
  void dispose() {
    _streetController.dispose();
    _houseController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await _service.fetchCountries();
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _loadingGeo = false;
        if (_cityId != null) {
          for (final country in _countries) {
            for (final state in country.states) {
              for (final city in state.cities) {
                if (city.id == _cityId) {
                  _countryId = country.id;
                  _stateId = state.id;
                  _states = country.states;
                  _cities = state.cities;
                  return;
                }
              }
            }
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingGeo = false);
      _showError('$e');
    }
  }

  void _onCountryChanged(int? id) {
    setState(() {
      _countryId = id;
      _stateId = null;
      _cityId = null;
      _states = id == null ? [] : _countries.firstWhere((c) => c.id == id).states;
      _cities = [];
    });
  }

  void _onStateChanged(int? id) {
    setState(() {
      _stateId = id;
      _cityId = null;
      _cities = id == null ? [] : _states.firstWhere((s) => s.id == id).cities;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _cityId == null) {
      if (_cityId == null) _showError('Selecciona país, estado y ciudad');
      return;
    }

    setState(() => _loading = true);
    try {
      final updated = Address(
        id: widget.address.id,
        street: _streetController.text.trim(),
        houseNumber: _houseController.text.trim(),
        postalCode: _postalController.text.trim(),
        latitude: widget.address.latitude,
        longitude: widget.address.longitude,
        status: widget.address.status,
        profileId: widget.address.profileId,
        cityId: _cityId!,
      );
      await _service.updateAddress(updated, widget.userId);
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      _showError('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar dirección')),
      body: _loadingGeo
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<int>(
                    value: _countryId,
                    decoration: const InputDecoration(labelText: 'País', border: OutlineInputBorder()),
                    items: _countries
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: _onCountryChanged,
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _stateId,
                    decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                    items: _states
                        .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                        .toList(),
                    onChanged: _onStateChanged,
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _cityId,
                    decoration: const InputDecoration(labelText: 'Ciudad', border: OutlineInputBorder()),
                    items: _cities
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _cityId = v),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _streetController,
                    decoration: const InputDecoration(labelText: 'Calle', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _houseController,
                    decoration: const InputDecoration(labelText: 'Número / casa', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _postalController,
                    decoration: const InputDecoration(labelText: 'Código postal', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Actualizar'),
                  ),
                ],
              ),
            ),
    );
  }
}
