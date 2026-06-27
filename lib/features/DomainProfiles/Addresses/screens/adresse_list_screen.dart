import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix_glasses/features/DomainProfiles/Addresses/api/adresse_service.dart';
import 'package:zonix_glasses/features/DomainProfiles/Addresses/models/adresse.dart';
import 'package:zonix_glasses/features/DomainProfiles/Addresses/screens/adresse_create_screen.dart';
import 'package:zonix_glasses/features/DomainProfiles/Addresses/screens/adresse_edit_screen.dart';

class AddressModel with ChangeNotifier {
  Address? _address;
  bool _isLoading = true;

  Address? get address => _address;
  bool get isLoading => _isLoading;

  Future<void> loadAddress(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _address = await AddressService().getAddressById(userId);
    } catch (_) {
      _address = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAddress(int userId) async {
    try {
      _address = await AddressService().getAddressById(userId);
    } catch (_) {
      _address = null;
    }
    notifyListeners();
  }

  void updateAddress(Address newAddress) {
    _address = newAddress;
    notifyListeners();
  }
}

class AddressPage extends StatelessWidget {
  final int userId;
  final bool statusId;

  const AddressPage({super.key, required this.userId, this.statusId = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddressModel()..loadAddress(userId),
      child: Consumer<AddressModel>(
        builder: (context, model, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mi dirección')),
            body: model.isLoading
                ? const Center(child: CircularProgressIndicator())
                : model.address == null
                    ? _emptyState(context)
                    : _addressCard(context, model.address!),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _openForm(context, model),
              icon: Icon(model.address == null ? Icons.add : Icons.edit),
              label: Text(model.address == null ? 'Agregar' : 'Editar'),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text('No tienes dirección registrada'),
          ],
        ),
      ),
    );
  }

  Widget _addressCard(BuildContext context, Address address) {
    final location = [
      address.street,
      address.houseNumber,
      address.cityName,
      address.stateName,
      address.countryName,
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(location.isEmpty ? 'Dirección' : location),
            subtitle: Text('CP: ${address.postalCode.isEmpty ? '—' : address.postalCode}'),
          ),
        ),
      ],
    );
  }

  Future<void> _openForm(BuildContext context, AddressModel model) async {
    if (model.address == null) {
      final created = await Navigator.push<Address>(
        context,
        MaterialPageRoute(builder: (_) => RegisterAddressScreen(userId: userId)),
      );
      if (created != null) {
        model.updateAddress(created);
        await model.refreshAddress(userId);
      }
    } else {
      final updated = await Navigator.push<Address>(
        context,
        MaterialPageRoute(
          builder: (_) => EditAddressScreen(userId: userId, address: model.address!),
        ),
      );
      if (updated != null) {
        model.updateAddress(updated);
        await model.refreshAddress(userId);
      }
    }
  }
}
