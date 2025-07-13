import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';
import '../../../services/favorites_service.dart';
import '../../../models/product.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FavoritesService _favoritesService = FavoritesService();
  final Logger _logger = Logger();
  
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _logger.i('🔄 Cargando favoritos...');
      final favorites = await _favoritesService.getFavorites();
      
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });

      _logger.i('✅ Favoritos cargados: ${favorites.length} elementos');
    } catch (e) {
      _logger.e('❌ Error al cargar favoritos: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(int postId) async {
    try {
      await _favoritesService.toggleFavorite(postId);
      await _loadFavorites(); // Recargar la lista
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removido de favoritos')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredFavorites {
    if (_searchQuery.isEmpty) return _favorites;
    return _favorites.where((favorite) {
      final name = favorite['name']?.toString().toLowerCase() ?? '';
      final description = favorite['description']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase()) || 
             description.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              title: Container(
                height: 16,
                color: Colors.white,
              ),
              subtitle: Container(
                height: 12,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error al cargar favoritos',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Error desconocido',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFavorites,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tienes favoritos',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos a tus favoritos para verlos aquí',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> favorite) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            favorite['image'] ?? 'https://via.placeholder.com/50',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image, color: Colors.grey[600]),
              );
            },
          ),
        ),
        title: Text(
          favorite['name'] ?? 'Sin nombre',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              favorite['description'] ?? 'Sin descripción',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber),
                Text(
                  ' ${favorite['rating']?.toString() ?? '0.0'}',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${favorite['price']?.toString() ?? '0.00'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.favorite, color: Colors.red),
          onPressed: () => _removeFavorite(favorite['id']),
        ),
        onTap: () {
          // TODO: Navegar a detalles del producto
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Mis Favoritos',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar en favoritos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Lista de favoritos
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : _error != null
                    ? _buildErrorWidget()
                    : _filteredFavorites.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadFavorites,
                            child: ListView.builder(
                              itemCount: _filteredFavorites.length,
                              itemBuilder: (context, index) {
                                return _buildFavoriteCard(_filteredFavorites[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
} 