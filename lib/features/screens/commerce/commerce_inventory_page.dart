import 'package:flutter/material.dart';
import 'package:zonix/models/cart_item.dart';

class CommerceInventoryPage extends StatefulWidget {
  const CommerceInventoryPage({Key? key}) : super(key: key);

  @override
  State<CommerceInventoryPage> createState() => _CommerceInventoryPageState();
}

class _CommerceInventoryPageState extends State<CommerceInventoryPage> {
  bool _isLoading = true;
  List<CartItem> _products = [];
  String _selectedCategory = 'Todas';
  final List<String> _categories = ['Todas', 'Comida', 'Bebidas', 'Postres', 'Snacks'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInventoryData();
  }

  Future<void> _loadInventoryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simular carga de datos del inventario
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _products = [
          CartItem(
            id: 1,
            nombre: 'Hamburguesa Clásica',
            precio: 3500.0,
            quantity: 1,
            stock: 25,
            category: 'Comida',
            image: 'https://via.placeholder.com/150',
          ),
          CartItem(
            id: 2,
            nombre: 'Pizza Margherita',
            precio: 4500.0,
            quantity: 1,
            stock: 15,
            category: 'Comida',
            image: 'https://via.placeholder.com/150',
          ),
          CartItem(
            id: 3,
            nombre: 'Coca Cola',
            precio: 800.0,
            quantity: 1,
            stock: 50,
            category: 'Bebidas',
            image: 'https://via.placeholder.com/150',
          ),
          CartItem(
            id: 4,
            nombre: 'Tarta de Chocolate',
            precio: 1200.0,
            quantity: 1,
            stock: 8,
            category: 'Postres',
            image: 'https://via.placeholder.com/150',
          ),
          CartItem(
            id: 5,
            nombre: 'Papas Fritas',
            precio: 1500.0,
            quantity: 1,
            stock: 30,
            category: 'Snacks',
            image: 'https://via.placeholder.com/150',
          ),
          CartItem(
            id: 6,
            nombre: 'Agua Mineral',
            precio: 500.0,
            quantity: 1,
            stock: 100,
            category: 'Bebidas',
            image: 'https://via.placeholder.com/150',
          ),
        ];
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar inventario: $e')),
      );
    }
  }

  List<CartItem> get _filteredProducts {
    return _products.where((product) {
      bool matchesCategory = _selectedCategory == 'Todas' || product.category == _selectedCategory;
      bool matchesSearch = product.nombre.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Widget _buildProductCard(CartItem product) {
        Color stockColor = (product.stock ?? 0) > 10 
        ? Colors.green
        : (product.stock ?? 0) > 0 
            ? Colors.orange
            : Colors.red;
    
        String stockText = (product.stock ?? 0) > 10 
        ? 'En Stock'
        : (product.stock ?? 0) > 0 
            ? 'Stock Bajo'
            : 'Sin Stock';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Imagen del producto
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.image ?? '',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category ?? 'Sin categoría',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₡${product.precio?.toStringAsFixed(0) ?? '0'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: stockColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${product.stock} unidades',
                          style: TextStyle(
                            fontSize: 12,
                            color: stockColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Botones de acción
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editProduct(product),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteProduct(product),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editProduct(CartItem product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${product.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Nombre'),
              controller: TextEditingController(text: product.nombre),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Precio'),
              controller: TextEditingController(text: product.precio?.toString()),
              keyboardType: TextInputType.number,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Stock'),
              controller: TextEditingController(text: product.stock.toString()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.nombre} actualizado')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(CartItem product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de que quieres eliminar "${product.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _products.remove(product);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.nombre} eliminado')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _addNewProduct() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Nuevo Producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Nombre del producto'),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Stock inicial'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: _categories.where((cat) => cat != 'Todas').map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Producto agregado')),
              );
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventoryData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de búsqueda y filtros
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Barra de búsqueda
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar productos...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Filtro de categorías
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((category) {
                            bool isSelected = _selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                                selectedColor: Colors.blue[100],
                                checkmarkColor: Colors.blue,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Estadísticas rápidas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Productos',
                          '${_products.length}',
                          Icons.inventory,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Stock Bajo',
                          '${_products.where((p) => (p.stock ?? 0) <= 10).length}',
                          Icons.warning,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Sin Stock',
                          '${_products.where((p) => p.stock == 0).length}',
                          Icons.error,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Lista de productos
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron productos',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(_filteredProducts[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewProduct,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 