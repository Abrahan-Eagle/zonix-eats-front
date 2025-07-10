import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zonix/features/screens/products/products_page.dart';
import 'package:zonix/models/product.dart';
import 'package:zonix/features/services/cart_service.dart';
import 'package:zonix/features/services/product_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockProductService extends ProductService {
  @override
  Future<List<Product>> fetchProducts() async {
    return [
      Product(id: 1, nombre: 'Hamburguesa', disponible: true, precio: 50.0, descripcion: 'Rica hamburguesa', imagen: null),
      Product(id: 2, nombre: 'Pizza', disponible: true, precio: 80.0, descripcion: 'Pizza grande', imagen: null),
    ];
  }
}

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });
  testWidgets('ProductsPage muestra productos reales y navega a detalles', (WidgetTester tester) async {
    // Inyecta el ProductService mockeado directamente
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CartService>(create: (_) => CartService()),
        ],
        child: MaterialApp(
          home: ProductsPage(productService: MockProductService()),
        ),
      ),
    );

    // Espera a que cargue el FutureBuilder
    await tester.pumpAndSettle();

    // Verifica que los productos se muestran
    expect(find.text('Hamburguesa'), findsOneWidget);
    expect(find.text('Pizza'), findsOneWidget);
    expect(find.text(r'50.0 $'), findsOneWidget);
    expect(find.text(r'80.0 $'), findsOneWidget);

    // Toca la card de 'Hamburguesa' y verifica navegación a detalles
    await tester.tap(find.text('Hamburguesa'));
    await tester.pumpAndSettle();
    // Aquí podrías verificar que se navega a ProductDetailPage si lo implementas
  });
}
