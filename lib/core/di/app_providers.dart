import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/services/supabase_auth_service.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/categories/data/repositories/supabase_category_repository.dart';
import '../../features/categories/providers/category_provider.dart';
import '../data/supabase/supabase_product_repository.dart';
import '../location/location_provider.dart';
import '../../features/products/providers/product_provider.dart';
import '../../features/explorer/providers/explorer_provider.dart';
import '../../features/explorer/services/explorer_service.dart';
import '../../features/manual_lists/providers/manual_list_provider.dart';
import '../../features/comparison/providers/comparison_provider.dart';

class AppProviders {
  static List<dynamic> get providers => [
        // ——— Auth ———
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: SupabaseAuthService(Supabase.instance.client),
          ),
        ),

        // ——— Products ———
        Provider(
          create: (_) =>
              SupabaseProductRepository(supabase: Supabase.instance.client),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ProductProvider(repository: _.read<SupabaseProductRepository>()),
        ),

        // ——— Categories ———
        Provider(
          create: (_) => SupabaseCategoryRepository(
            supabase: Supabase.instance.client,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(
            repository: _.read<SupabaseCategoryRepository>(),
          ),
        ),

        // ——— Explorer ———
        ChangeNotifierProvider(
          create: (_) => ExplorerProvider(
            service: ExplorerService(),
            productProvider: _.read<ProductProvider>(),
            categoryProvider: _.read<CategoryProvider>(),
            repository: _.read<SupabaseProductRepository>(),
          ),
        ),

        // ——— Comparison ———
        ChangeNotifierProvider(
          create: (_) => ComparisonProvider(
            productProvider: _.read<ProductProvider>(),
          ),
        ),

        // ——— Location (GPS) ———
        ChangeNotifierProvider(
          create: (_) => LocationProvider(),
        ),

        // ——— Manual Lists (Hive) ———
        ChangeNotifierProvider(
          create: (_) => ManualListProvider(
            productProvider: _.read<ProductProvider>(),
          ),
        ),
      ];
}
