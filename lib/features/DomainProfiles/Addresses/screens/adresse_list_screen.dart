import 'package:flutter/material.dart';
import 'package:zonix/features/DomainProfiles/Addresses/api/adresse_service.dart';
import 'package:zonix/features/DomainProfiles/Addresses/models/adresse.dart';
import 'package:zonix/features/DomainProfiles/Addresses/screens/adresse_create_screen.dart';
import 'package:zonix/features/DomainProfiles/Addresses/screens/adresse_edit_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/features/utils/app_colors.dart';
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
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            backgroundColor: isDark ? AppColors.backgroundDark : AppColors.scaffoldBgLight,
            appBar: _buildAppBar(context, addressModel),
            body: _buildBody(context, addressModel, isSmallScreen),
            floatingActionButton:
                _buildFloatingActionButtons(context, addressModel),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AddressModel addressModel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? AppColors.backgroundDark : AppColors.scaffoldBgLight;
    final fgColor = AppColors.primaryText(context);
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: barBg,
      foregroundColor: fgColor,
      title: Text(
        'Mi Dirección',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: fgColor,
        ),
      ),
      actions: [
        if (addressModel.address != null) ...[
          IconButton(
            onPressed: () => addressModel.refreshAddress(userId),
            icon: addressModel.isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                    ),
                  )
                : Icon(Icons.refresh, color: fgColor),
          ),
          IconButton(
            onPressed: () => _navigateToCreateAddress(context),
            icon: Icon(Icons.edit_location_alt, color: fgColor),
            tooltip: 'Editar ubicación',
          ),
        ],
      ],
    );
  }

  Widget _buildBody(
      BuildContext context, AddressModel addressModel, bool isSmallScreen) {
    if (addressModel.isLoading) {
      return _buildLoadingState(context);
    }

    if (addressModel.address == null) {
      return _buildEmptyState(context, isSmallScreen);
    }

    return _buildAddressContent(context, addressModel.address!, isSmallScreen);
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando dirección...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText(context),
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
                color: AppColors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.location_off_outlined,
                size: 60,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes dirección registrada',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primera dirección para comenzar',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryText(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateAddress(context),
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Agregar Dirección'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildAddressContent(
      BuildContext context, Address address, bool isSmallScreen) {
    return RefreshIndicator(
      onRefresh: () => context.read<AddressModel>().refreshAddress(userId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddressCard(context, address, isSmallScreen),
            const SizedBox(height: 12),
            _buildMapCard(address, context, isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(
      BuildContext context, Address address, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.slateBorder
              : AppColors.stitchBorder,
        ),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Residencial',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Detalles de la ubicación principal',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, 'Calle/Av.', address.street, false),
            _buildInfoRow(context, 'Número', address.houseNumber, false),
            _buildInfoRow(context, 'Código Postal', address.postalCode, false),
            _buildInfoRow(context, 'País', address.countryName ?? '—', false),
            _buildInfoRow(context, 'Estado', address.stateName ?? '—', false),
            _buildInfoRow(context, 'Ciudad', address.cityName ?? '—', false),
            _buildInfoRow(
                context,
                'Coordenadas',
                '${address.latitude.toStringAsFixed(6)}, ${address.longitude.toStringAsFixed(6)}',
                true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, String value, bool isLink) {
    final displayValue = value.trim().isEmpty ? '-' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isLink ? AppColors.blue : AppColors.primaryText(context),
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(
      Address address, BuildContext context, bool isSmallScreen) {
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.slateBorder
        : AppColors.stitchBorder;
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: OsmMapWidget(
              center: LatLng(address.latitude, address.longitude),
              zoom: 15.0,
              height: 220,
              markers: [
                MapMarker.create(
                  point: LatLng(address.latitude, address.longitude),
                  iconData: Icons.location_on,
                  color: AppColors.red,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
            Material(
            color: AppColors.cardBg(context),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () async {
                final url =
                    '${AppConfig.googleMapsPointUrl}=${address.latitude},${address.longitude}';
                try {
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('No se pudo abrir el mapa: $e'),
                        backgroundColor: AppColors.red,
                      ),
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, color: AppColors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Abrir en Google Maps',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButtons(
      BuildContext context, AddressModel addressModel) {
    final hasAddress = addressModel.address != null;
    if (hasAddress && !statusId) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusId) _buildStatusUpdateButton(context),
          if (!hasAddress) ...[
            if (statusId) const SizedBox(height: 16),
            _buildAddressButton(context, addressModel),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusUpdateButton(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'adresse_list_status',
      onPressed: () => _showStatusUpdateDialog(context),
      backgroundColor: AppColors.green,
      child: const Icon(Icons.check, color: AppColors.white),
    );
  }

  Widget _buildAddressButton(BuildContext context, AddressModel addressModel) {
    return FloatingActionButton.extended(
      heroTag: 'adresse_list_create',
      onPressed: () => _navigateToCreateAddress(context),
      backgroundColor: AppColors.blue,
      foregroundColor: AppColors.white,
      icon: const Icon(Icons.add_location_alt),
      label: const Text('Agregar Dirección'),
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
      ).then((updatedAddress) async {
        if (updatedAddress != null) {
          addressModel.updateAddress(updatedAddress);
          // Refrescar desde la API para obtener país/estado/ciudad (nombres) actualizados
          await addressModel.refreshAddress(userId);
        }
      });
    } else {
      // Navegar a la pantalla de creación
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterAddressScreen(userId: userId),
        ),
      ).then((newAddress) async {
        if (newAddress != null) {
          addressModel.updateAddress(newAddress);
          await addressModel.refreshAddress(userId);
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
            Icon(Icons.check_circle, color: AppColors.green),
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
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.white,
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
                Icon(Icons.check_circle, color: AppColors.white),
                SizedBox(width: 8),
                Text('Estado actualizado exitosamente'),
              ],
            ),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                const Icon(Icons.error, color: AppColors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }
}
