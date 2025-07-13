import 'package:flutter/material.dart';

class NetworkImageWithFallback extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? title;
  final IconData? fallbackIcon;
  final Color? fallbackColor;

  const NetworkImageWithFallback({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.title,
    this.fallbackIcon,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget = imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingPlaceholder();
            },
            errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
          )
        : _buildErrorPlaceholder();

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade300,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 8),
            Text(
              'Cargando...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    final color = fallbackColor ?? Colors.orange;
    
    // Convertir a MaterialColor para usar shades, o usar colores predefinidos
    final materialColor = color is MaterialColor ? color : Colors.orange;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            materialColor.shade100,
            materialColor.shade200,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              fallbackIcon ?? Icons.restaurant,
              size: height * 0.2,
              color: materialColor.shade600,
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title!,
                style: TextStyle(
                  fontSize: height * 0.06,
                  fontWeight: FontWeight.bold,
                  color: materialColor.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Imagen no disponible',
            style: TextStyle(
              fontSize: height * 0.04,
              color: materialColor.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget específico para productos
class ProductImage extends StatelessWidget {
  final String imageUrl;
  final String productName;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkImageWithFallback(
      imageUrl: imageUrl,
      width: width,
      height: height,
      title: productName,
      fallbackIcon: Icons.restaurant,
      fallbackColor: Colors.orange,
      borderRadius: borderRadius,
    );
  }
}

// Widget específico para restaurantes
class RestaurantImage extends StatelessWidget {
  final String imageUrl;
  final String restaurantName;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const RestaurantImage({
    super.key,
    required this.imageUrl,
    required this.restaurantName,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkImageWithFallback(
      imageUrl: imageUrl,
      width: width,
      height: height,
      title: restaurantName,
      fallbackIcon: Icons.store,
      fallbackColor: Colors.blue,
      borderRadius: borderRadius,
    );
  }
} 