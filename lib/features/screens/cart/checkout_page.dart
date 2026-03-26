import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix/config/app_config.dart';
import 'package:zonix/features/services/address_service.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/location_service.dart';
import 'package:zonix/features/services/order_service.dart';
import 'package:zonix/features/services/promotion_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/safe_parse.dart';
import 'package:zonix/features/screens/orders/order_detail_page.dart';
import 'package:zonix/features/utils/network_image_with_fallback.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _loading = false;
  String? _error;
  String _deliveryType = 'pickup';
  String? _selectedAddress;
  double? _selectedDeliveryLat;
  double? _selectedDeliveryLng;
  bool _isUsingCurrentLocation = false;
  bool _loadingCurrentLocation = false;
  List<Map<String, dynamic>> _addresses = [];
  final _couponController = TextEditingController();
  Map<String, dynamic>? _appliedCoupon;
  double _couponDiscount = 0.0;
  bool _validatingCoupon = false;
  final _promotionService = PromotionService();
  double? _calculatedDeliveryFee;
  bool _deliveryFeeLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _recalculateDeliveryFee() async {
    final cartService = Provider.of<CartService>(context, listen: false);
    final orderService = Provider.of<OrderService>(context, listen: false);
    if (_deliveryType != 'delivery' ||
        _selectedDeliveryLat == null ||
        _selectedDeliveryLng == null ||
        cartService.items.isEmpty) {
      setState(() {
        _calculatedDeliveryFee = null;
        _deliveryFeeLoading = false;
      });
      return;
    }
    final commerceId = cartService.items.first.commerceId;
    if (commerceId == null) {
      setState(() {
        _calculatedDeliveryFee = null;
        _deliveryFeeLoading = false;
      });
      return;
    }
    setState(() => _deliveryFeeLoading = true);
    final result = await orderService.calculateDeliveryFee(
      commerceId: commerceId,
      deliveryLatitude: _selectedDeliveryLat!,
      deliveryLongitude: _selectedDeliveryLng!,
    );
    if (!mounted) return;
    setState(() {
      _deliveryFeeLoading = false;
      _calculatedDeliveryFee = result != null ? safeDouble(result['delivery_fee']) : null;
    });
  }

  Future<void> _loadAddresses() async {
    try {
      final list = await AddressService().getUserAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = list;
        if (_addresses.isNotEmpty &&
            _selectedAddress == null &&
            !_isUsingCurrentLocation) {
          final defaultAddr = _addresses.firstWhere(
            (a) => a['is_default'] == true,
            orElse: () => _addresses.first,
          );
          _selectedAddress = (defaultAddr['formatted_address'] as String?) ??
              _formatAddressFromMap(defaultAddr);
          _selectedDeliveryLat = _latFromMap(defaultAddr);
          _selectedDeliveryLng = _lngFromMap(defaultAddr);
        }
      });
      if (_deliveryType == 'delivery') _recalculateDeliveryFee();
    } catch (_) {
      // Sin direcciones guardadas
    }
  }

  /// Obtiene la ubicación actual del dispositivo y la usa como dirección de entrega.
  Future<void> _useCurrentDeviceLocation() async {
    setState(() => _loadingCurrentLocation = true);
    try {
      final location = await LocationService().getCurrentLocation();
      if (!mounted) return;
      final address = location['address'] as String?;
      final lat = location['latitude'] != null ? safeDouble(location['latitude']) : null;
      final lng = location['longitude'] != null ? safeDouble(location['longitude']) : null;
      final addressText = address?.trim().isNotEmpty == true
          ? address!
          : (lat != null && lng != null
              ? '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'
              : null);
      setState(() {
        _loadingCurrentLocation = false;
        _isUsingCurrentLocation = true;
        _selectedAddress = addressText;
        _selectedDeliveryLat = lat?.toDouble();
        _selectedDeliveryLng = lng?.toDouble();
      });
      _recalculateDeliveryFee();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCurrentLocation = false;
        _error =
            'No se pudo obtener la ubicación. Revisa permisos o usa una dirección guardada.';
      });
    }
  }

  double? _latFromMap(Map<String, dynamic> m) {
    final v = m['latitude'];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  double? _lngFromMap(Map<String, dynamic> m) {
    final v = m['longitude'];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String _formatAddressFromMap(Map<String, dynamic> addr) {
    final parts = <String>[];
    if (addr['address_line_1'] != null) {
      parts.add(addr['address_line_1'].toString());
    }
    if (addr['address_line_2'] != null &&
        addr['address_line_2'].toString().isNotEmpty) {
      parts.add(addr['address_line_2'].toString());
    }
    if (addr['city'] != null) {
      parts.add(addr['city'].toString());
    }
    if (addr['state'] != null) {
      parts.add(addr['state'].toString());
    }
    if (addr['postal_code'] != null) {
      parts.add(addr['postal_code'].toString());
    }
    if (addr['country'] != null) {
      parts.add(addr['country'].toString());
    }
    return parts.join(', ');
  }

  Future<void> _handleCheckout() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final cartService = Provider.of<CartService>(context, listen: false);
    final orderService = Provider.of<OrderService>(context, listen: false);
    try {
      String? deliveryAddress;
      if (_deliveryType == 'delivery') {
        deliveryAddress = _selectedAddress;
        if (deliveryAddress == null || deliveryAddress.trim().isEmpty) {
          setState(() {
            _error = 'Selecciona o agrega una dirección de entrega';
            _loading = false;
          });
          return;
        }
      }
      final deliveryFee = _deliveryType == 'delivery'
          ? (_calculatedDeliveryFee ?? AppConfig.defaultDeliveryFee)
          : 0.0;
      final order = await orderService.createOrder(
        cartService.items.toList(),
        deliveryType: _deliveryType,
        deliveryAddress: deliveryAddress,
        deliveryLatitude:
            _deliveryType == 'delivery' ? _selectedDeliveryLat : null,
        deliveryLongitude:
            _deliveryType == 'delivery' ? _selectedDeliveryLng : null,
        deliveryFee: deliveryFee,
      );
      if (_appliedCoupon != null) {
        final cid = _appliedCoupon!['coupon_id'];
        if (cid != null) {
          final couponId = cid is int ? cid : int.tryParse(cid.toString());
          if (couponId != null) {
            await _promotionService.applyCouponToOrder(
                couponId: couponId, orderId: order.id);
          }
        }
      }
      cartService.clearCart();
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderDetailPage(
            orderId: order.id,
            order: order,
            showCreatedDialog: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final cartItems = cartService.items;
    final subtotal = cartItems.fold<double>(
        0, (sum, item) => sum + (item.precio ?? 0) * item.quantity);
    const tax = 0.0;
    final delivery = _deliveryType == 'delivery'
        ? (_calculatedDeliveryFee ?? AppConfig.defaultDeliveryFee)
        : 0.0;
    final totalPayment = (subtotal + tax + delivery - _couponDiscount)
        .clamp(0.0, double.infinity);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.scaffoldBg(context),
        title: const Text(
          'Finalizar pedido',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.grayDark
                      : AppColors.grayLight.withValues(alpha: 0.7),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Resumen del pedido',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Zonix Eats',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...cartService.items.map(
                    (item) {
                      final imageUrl = (item.image ?? item.imagen ?? '').toString();
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: imageUrl.isNotEmpty
                                    ? NetworkImageWithFallback(
                                        imageUrl: imageUrl,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(12),
                                      )
                                    : Container(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.grayDark
                                            : AppColors.grayLight,
                                        child: const Icon(
                                          Icons.fastfood,
                                          color: AppColors.gray,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nombre,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (item.notes != null &&
                                      item.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.notes!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.gray,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Text(
                                        'Cantidad: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity:
                                            VisualDensity.compact,
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 20,
                                        ),
                                        onPressed: item.quantity > 1
                                            ? () => cartService
                                                .decrementQuantity(item)
                                            : null,
                                      ),
                                      Text('${item.quantity}'),
                                      IconButton(
                                        visualDensity:
                                            VisualDensity.compact,
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            cartService.incrementQuantity(item),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${((item.precio ?? 0) * item.quantity).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tipo de entrega',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.gray.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                          setState(() => _deliveryType = 'delivery');
                          _recalculateDeliveryFee();
                        },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          color: _deliveryType == 'delivery'
                              ? AppColors.orange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delivery_dining,
                              size: 18,
                              color: _deliveryType == 'delivery'
                                  ? Colors.white
                                  : AppColors.secondaryText(context),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Domicilio',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _deliveryType == 'delivery'
                                    ? Colors.white
                                    : AppColors.secondaryText(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() {
                            _deliveryType = 'pickup';
                            _calculatedDeliveryFee = null;
                          }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          color: _deliveryType == 'pickup'
                              ? AppColors.cardBg(context)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.storefront,
                              size: 18,
                              color: _deliveryType == 'pickup'
                                  ? AppColors.primaryText(context)
                                  : AppColors.secondaryText(context),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Recoger',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _deliveryType == 'pickup'
                                    ? AppColors.primaryText(context)
                                    : AppColors.secondaryText(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cupón de descuento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: 'Código de cupón',
                      isDense: true,
                      suffixIcon: _appliedCoupon != null
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _appliedCoupon = null;
                                  _couponDiscount = 0.0;
                                  _couponController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    enabled: _appliedCoupon == null,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _appliedCoupon != null || _validatingCoupon
                      ? null
                      : () => _validateCoupon(subtotal),
                  child: _validatingCoupon
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_appliedCoupon != null ? 'Aplicado' : 'Aplicar'),
                ),
              ],
            ),
            if (_appliedCoupon != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cupón aplicado: -\$${_couponDiscount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: AppColors.green, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_deliveryType == 'delivery') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dirección de entrega',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () {
                      // Abrir selector de dirección existente (GPS + direcciones)
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (ctx) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(ctx).viewInsets.bottom + 16,
                              top: 16,
                              left: 16,
                              right: 16,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Elige una dirección',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Card(
                                    color: _isUsingCurrentLocation
                                        ? Theme.of(ctx)
                                            .colorScheme
                                            .primaryContainer
                                        : null,
                                    child: ListTile(
                                      leading: _loadingCurrentLocation
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child:
                                                  CircularProgressIndicator(
                                                      strokeWidth: 2))
                                          : const Icon(Icons.my_location),
                                      title: const Text(
                                          'Ubicación GPS del dispositivo'),
                                      subtitle: Text(
                                        _isUsingCurrentLocation &&
                                                _selectedAddress != null
                                            ? _selectedAddress!
                                            : 'Usar mi ubicación actual ahora',
                                      ),
                                      trailing: _isUsingCurrentLocation
                                          ? const Icon(Icons.check_circle)
                                          : null,
                                      onTap: _loadingCurrentLocation
                                          ? null
                                          : () async {
                                              Navigator.of(ctx).pop();
                                              await _useCurrentDeviceLocation();
                                            },
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (_addresses.isEmpty)
                                    const Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                            'No tienes direcciones guardadas. Usa "Ubicación GPS del dispositivo" o agrega una en tu perfil.'),
                                      ),
                                    )
                                  else
                                    ..._addresses.map((addr) {
                                      final formatted =
                                          addr['formatted_address']
                                                  as String? ??
                                              _formatAddressFromMap(addr);
                                      final isDefault =
                                          addr['is_default'] == true;
                                      final isSelected =
                                          !_isUsingCurrentLocation &&
                                              _selectedAddress == formatted;
                                      return Card(
                                        color: isSelected
                                            ? Theme.of(ctx)
                                                .colorScheme
                                                .primaryContainer
                                            : null,
                                        child: ListTile(
                                          leading: Icon(isDefault
                                              ? Icons.home
                                              : Icons.location_on),
                                          title: Text(isDefault
                                              ? 'Mi casa'
                                              : (addr['name']?.toString() ??
                                                  'Otra ubicación')),
                                          subtitle: Text(formatted),
                                          trailing: isSelected
                                              ? const Icon(Icons.check_circle)
                                              : null,
                                          onTap: () {
                                            setState(() {
                                              _selectedAddress = formatted;
                                              _isUsingCurrentLocation = false;
                                              _selectedDeliveryLat =
                                                  _latFromMap(addr);
                                              _selectedDeliveryLng =
                                                  _lngFromMap(addr);
                                            });
                                            Navigator.of(ctx).pop();
                                            _recalculateDeliveryFee();
                                          },
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: const Text('Editar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gray.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isUsingCurrentLocation
                                ? 'Ubicación actual'
                                : 'Mi Casa',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedAddress ??
                                'Selecciona o agrega una dirección',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.gray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Estimado: 25-35 min',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.gray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Método de pago (UI alineada con template; selección real se hace al subir comprobante)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Método de pago',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Seleccionarás el método de pago al subir el comprobante.'),
                      ),
                    );
                  },
                  child: const Text('Cambiar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.gray.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.grayDark
                          : AppColors.grayLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.credit_card,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Definir en el siguiente paso',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Verás las opciones del comercio al subir el comprobante.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.gray.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                  _buildSummaryRow(
                    'Costo de envío',
                    _deliveryType == 'delivery' && _deliveryFeeLoading
                        ? 'Calculando...'
                        : (delivery <= 0
                            ? 'Gratis'
                            : '\$${delivery.toStringAsFixed(2)}'),
                    isDiscount: delivery <= 0 && !_deliveryFeeLoading,
                  ),
                  _buildSummaryRow(
                    'Impuestos (8%)',
                    '\$${tax.toStringAsFixed(2)}',
                  ),
                  if (_couponDiscount > 0)
                    _buildSummaryRow(
                      'Descuento cupón',
                      '-\$${_couponDiscount.toStringAsFixed(2)}',
                      isDiscount: true,
                    ),
                  const Divider(height: 24, thickness: 1),
                  _buildSummaryRow(
                    'Total',
                    '\$${totalPayment.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.red)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _loading ? null : _handleCheckout,
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Confirmar Pedido',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.white,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Al confirmar, aceptas nuestros términos de servicio y políticas de entrega.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.gray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateCoupon(double subtotal) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() => _validatingCoupon = true);
    try {
      final cartService = Provider.of<CartService>(context, listen: false);
      final commerceId = cartService.items.isNotEmpty
          ? cartService.items.first.commerceId
          : null;
      final result = await _promotionService.validateCoupon(
        couponCode: code,
        orderAmount: subtotal,
        commerceId: commerceId,
      );
      final discount = safeDouble(result['discount']);
      setState(() {
        _appliedCoupon = result;
        _couponDiscount = discount;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _validatingCoupon = false);
    }
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false, bool isDiscount = false}) {
    final color =
        isTotal ? AppColors.green : (isDiscount ? AppColors.red : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
