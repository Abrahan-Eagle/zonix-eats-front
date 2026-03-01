import 'package:flutter/material.dart';
import 'package:zonix/features/DomainProfiles/Addresses/api/adresse_service.dart';
import 'package:zonix/features/DomainProfiles/Addresses/models/adresse.dart';
import 'package:zonix/features/DomainProfiles/Addresses/screens/adresse_create_screen.dart';
import 'package:zonix/features/DomainProfiles/Addresses/screens/adresse_edit_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zonix/widgets/osm_map_widget.dart';
import 'package:latlong2/latlong.dart';

class AddressModel with ChangeNotifier {
  Address? _address;
  bool _isLoading = true;
  bool _isRefreshing = false;

  Address? get address => _address;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;

  Future<void> loadAddress(int userId) async {
    if (_address != null && _address!.id == userId) return;

    _isLoading = true;
    notifyListeners();

    try {
      _address = await AddressService().getAddressById(userId);
    } catch (e) {
      _address = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAddress(int userId) async {
    _isRefreshing = true;
    notifyListeners();

    try {
      _address = await AddressService().getAddressById(userId);
    } catch (e) {
      _address = null;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
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
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 600;

    return ChangeNotifierProvider(
      create: (_) => AddressModel()..loadAddress(userId),
      child: Consumer<AddressModel>(
        builder: (context, addressModel, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: _buildAppBar(context, addressModel),
            body: _buildBody(context, addressModel, isSmallScreen),
            floatingActionButton: _buildFloatingActionButtons(context, addressModel),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AddressModel addressModel) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1976D2),
      foregroundColor: Colors.white,
      title: const Text(
        'Mi Dirección',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      actions: [
        if (addressModel.address != null)
          IconButton(
            onPressed: () => addressModel.refreshAddress(userId),
            icon: addressModel.isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AddressModel addressModel, bool isSmallScreen) {
    if (addressModel.isLoading) {
      return _buildLoadingState();
    }

    if (addressModel.address == null) {
      return _buildEmptyState(context, isSmallScreen);
    }

    return _buildAddressContent(context, addressModel.address!, isSmallScreen);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando dirección...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 20.0 : 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.location_off_outlined,
                size: 60,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No tienes dirección registrada',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega tu primera dirección para comenzar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateAddress(context),
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Agregar Dirección'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressContent(BuildContext context, Address address, bool isSmallScreen) {
    return RefreshIndicator(
      onRefresh: () => context.read<AddressModel>().refreshAddress(userId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddressCard(address, isSmallScreen),
            const SizedBox(height: 12),
            _buildMapCard(address, context, isSmallScreen),
          ],
        ),
      ),
    );
  }



  Widget _buildAddressCard(Address address, bool isSmallScreen) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Información de Dirección',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Dirección', address.street, Icons.home),
            _buildInfoRow('Número de Casa', address.houseNumber, Icons.numbers),
            _buildInfoRow('Código Postal', address.postalCode, Icons.mail),
            _buildInfoRow('País', 'Venezuela', Icons.flag),
            _buildInfoRow('Estado', 'Carabobo', Icons.location_city),
            _buildInfoRow('Ciudad', 'Valencia', Icons.location_on),
            _buildInfoRow('Coordenadas', '${address.latitude.toStringAsFixed(6)}, ${address.longitude.toStringAsFixed(6)}', Icons.gps_fixed),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(Address address, BuildContext context, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mapa usando OpenStreetMap (como en CorralX)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: OsmMapWidget(
              center: LatLng(address.latitude, address.longitude),
              zoom: 15.0,
              height: 200,
              markers: [
                MapMarker.create(
                  point: LatLng(address.latitude, address.longitude),
                  iconData: Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Botón para abrir en navegador externo
          GestureDetector(
            onTap: () async {
              final url = 'https://www.openstreetmap.org/?mlat=${address.latitude}&mlon=${address.longitude}&zoom=15';
              try {
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No se pudo abrir el mapa: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Abrir en OpenStreetMap',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButtons(BuildContext context, AddressModel addressModel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusId) _buildStatusUpdateButton(context),
          const SizedBox(height: 16),
          _buildAddressButton(context, addressModel),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateButton(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'adresse_list_status',
      onPressed: () => _showStatusUpdateDialog(context),
      backgroundColor: Colors.green,
      child: const Icon(Icons.check, color: Colors.white),
    );
  }

  Widget _buildAddressButton(BuildContext context, AddressModel addressModel) {
    final hasAddress = addressModel.address != null;
    
    return FloatingActionButton.extended(
      heroTag: 'adresse_list_create',
      onPressed: () => _navigateToCreateAddress(context),
      backgroundColor: hasAddress ? Colors.orange : const Color(0xFF1976D2),
      foregroundColor: Colors.white,
      icon: Icon(hasAddress ? Icons.edit_location : Icons.add_location_alt),
      label: Text(hasAddress ? 'Editar Ubicación' : 'Agregar Dirección'),
    );
  }

  void _navigateToCreateAddress(BuildContext context) {
    final addressModel = context.read<AddressModel>();
    final hasAddress = addressModel.address != null;
    
    if (hasAddress) {
      // Navegar a la pantalla de edición
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditAddressScreen(
            userId: userId,
            address: addressModel.address!,
          ),
        ),
      ).then((updatedAddress) {
        if (updatedAddress != null) {
          addressModel.updateAddress(updatedAddress);
        }
      });
    } else {
      // Navegar a la pantalla de creación
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterAddressScreen(userId: userId),
        ),
      ).then((newAddress) {
        if (newAddress != null) {
          addressModel.updateAddress(newAddress);
        }
      });
    }
  }

  Future<void> _showStatusUpdateDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Confirmar Aprobación'),
          ],
        ),
        content: const Text('¿Deseas aprobar esta solicitud de dirección?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        await _updateStatus(context);
      }
    });
  }

  Future<void> _updateStatus(BuildContext context) async {
    try {
      await AddressService().updateStatusCheckScanner(userId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Estado actualizado exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }
}