// Pruebas de widget de la composición responsive del explorador.
//
// Verifican que el catálogo usa carruseles en móvil y cuadrícula en
// tablet/escritorio, sin desbordamientos, con providers falsos (sin red).
//
// Cómo correr: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vibeshopping/core/data/supabase/supabase_product_repository.dart';
import 'package:vibeshopping/features/categories/data/repositories/supabase_category_repository.dart';
import 'package:vibeshopping/features/categories/domain/category_model.dart';
import 'package:vibeshopping/features/categories/providers/category_provider.dart';
import 'package:vibeshopping/features/comparison/providers/comparison_provider.dart';
import 'package:vibeshopping/features/explorer/domain/store_model.dart';
import 'package:vibeshopping/features/explorer/providers/explorer_provider.dart';
import 'package:vibeshopping/features/explorer/screens/market_explorer_view.dart';
import 'package:vibeshopping/features/explorer/services/explorer_service.dart';
import 'package:vibeshopping/features/products/models/product.dart';
import 'package:vibeshopping/features/products/providers/product_provider.dart';

// Cliente sin red: los repositorios solo se usan como dependencia de
// construcción y nunca consultan en estas pruebas. Se desactiva el refresco
// automático de sesión para no dejar temporizadores pendientes.
SupabaseClient _client() => SupabaseClient(
      'https://example.supabase.co',
      'public-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

ProductProvider _productProvider() =>
    ProductProvider(repository: SupabaseProductRepository(supabase: _client()));

// Provider de explorador con datos controlados; no carga nada de Supabase.
class _FakeExplorerProvider extends ExplorerProvider {
  _FakeExplorerProvider(this._grouped)
      : super(
          service: ExplorerService(),
          productProvider: _productProvider(),
          categoryProvider: CategoryProvider(
            repository: SupabaseCategoryRepository(supabase: _client()),
          ),
          repository: SupabaseProductRepository(supabase: _client()),
        );

  final Map<String, List<ProductEntity>> _grouped;

  @override
  bool get initialized => true;
  @override
  Map<String, List<ProductEntity>> get groupedProducts => _grouped;
  @override
  bool get productsLoading => false;
  @override
  List<CategoryModel> get categories => const [];
  @override
  String get categoryId => 'todo';
  @override
  List<StoreModel> get stores => const [];
  @override
  bool get allStores => true;
  @override
  Set<String> get selectedStoreIds => const {};
  @override
  String get storeFilterLabel => 'Todos los supermercados';
  @override
  Future<void> initialize() async {}
}

ProductEntity _product(String id, String name) => ProductEntity(
      id: id,
      categoryId: 'cat-1',
      subcategory: 'Bebidas',
      name: name,
      imageUrls: const [],
      prices: const [
        ProductPrice(
          storeId: 'store-1',
          storeName: 'Tienda Uno',
          price: 1000,
          currency: 'CRC',
        ),
      ],
      createdAt: '2026-01-01T00:00:00Z',
    );

Widget _host(ExplorerProvider explorer) {
  final productProvider = _productProvider();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ExplorerProvider>.value(value: explorer),
      ChangeNotifierProvider<ComparisonProvider>(
        create: (_) => ComparisonProvider(productProvider: productProvider),
      ),
    ],
    child: const MaterialApp(home: MarketExplorerView()),
  );
}

final Map<String, List<ProductEntity>> _grouped = {
  'Bebidas': [
    _product('p1', 'Agua 1L'),
    _product('p2', 'Jugo 1L'),
    _product('p3', 'Café 250g'),
  ],
};

Future<void> _pumpAt(WidgetTester tester, double width) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_host(_FakeExplorerProvider(_grouped)));
  await tester.pump();
}

void main() {
  testWidgets('móvil (390): usa carruseles horizontales', (tester) async {
    await _pumpAt(tester, 390);

    expect(find.byKey(const Key('explorer-carousel')), findsOneWidget);
    expect(find.byKey(const Key('explorer-grid')), findsNothing);
    expect(find.text('Bebidas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet (800): usa cuadrícula adaptativa', (tester) async {
    await _pumpAt(tester, 800);

    expect(find.byKey(const Key('explorer-grid')), findsOneWidget);
    expect(find.byKey(const Key('explorer-carousel')), findsNothing);
    expect(find.text('Bebidas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('escritorio (1440): usa cuadrícula adaptativa', (tester) async {
    await _pumpAt(tester, 1440);

    expect(find.byKey(const Key('explorer-grid')), findsOneWidget);
    expect(find.byKey(const Key('explorer-carousel')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
