import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/opening_hours.dart';
import '../../../features/products/models/product.dart';
import '../../../features/explorer/domain/store_model.dart';
import '../../../features/explorer/domain/store_location.dart';

// Acceso a los productos desde la vista de Supabase.
class SupabaseProductRepository {
  SupabaseProductRepository({required SupabaseClient supabase})
      : _supabase = supabase;

  final SupabaseClient _supabase;

  // Consulta los productos aplicando los filtros opcionales.
  Future<List<ProductEntity>> listProducts({
    List<String>? categoryIds,
    String? search,
    List<String>? storeIds,
  }) async {
    var query = _supabase.from('v_products_complete').select('*');

    if (categoryIds != null && categoryIds.isNotEmpty) {
      query = categoryIds.length == 1
          ? query.eq('category_id', categoryIds.first)
          : query.inFilter('category_id', categoryIds);
    }

    if (search != null && search.isNotEmpty) {
      query = query.ilike('canonical_name', '%$search%');
    }

    if (storeIds != null && storeIds.isNotEmpty) {
      query = storeIds.length == 1
          ? query.eq('supermarket_id', storeIds.first)
          : query.inFilter('supermarket_id', storeIds);
    }

    final response = await query;
    final rows = response as List<dynamic>;
    return rows
        .map((e) => ProductEntity.fromViewMap(e as Map<String, dynamic>))
        .toList();
  }

  // Supermercados con coordenadas reales para distancias del asistente.
  Future<List<StoreModel>> listSupermarkets() async {
    final response = await _supabase
        .from('supermarkets')
        .select('id,name,logo_url,latitude,longitude,address,'
            'branch_name,photo_url,phone,opening_hours');
    return (response as List<dynamic>).map((e) {
      final map = e as Map<String, dynamic>;
      final lat = (map['latitude'] as num?)?.toDouble();
      final lng = (map['longitude'] as num?)?.toDouble();
      return StoreModel(
        id: map['id']?.toString() ?? '',
        name: map['name'] as String? ?? '',
        logoUrl: map['logo_url'] as String?,
        branchName: map['branch_name'] as String?,
        photoUrl: map['photo_url'] as String?,
        phone: map['phone'] as String?,
        openingHours: OpeningHours.tryParse(map['opening_hours']),
        locations: (lat != null && lng != null)
            ? [
                StoreLocation(
                    latitude: lat,
                    longitude: lng,
                    address: map['address'] as String?),
              ]
            : const [],
      );
    }).toList();
  }
}
