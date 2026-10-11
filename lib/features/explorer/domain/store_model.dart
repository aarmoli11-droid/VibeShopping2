import '../../../core/opening_hours.dart';
import 'store_location.dart';

// Supermercado derivado de los precios del catálogo.
class StoreModel {
  final String id;
  final String name;

  // Nombre de la localidad o identificación de la sucursal (p. ej.
  // "Buenos Aires", "Boston"). Null si no está registrado.
  final String? branchName;

  // Fotografía real del establecimiento (no el logo). Null si no está.
  final String? photoUrl;

  // Teléfono de contacto de la sucursal. Null si no está registrado.
  final String? phone;

  // Horarios propios de la sucursal. Null si no hay información.
  final OpeningHours? openingHours;

  final String? logoUrl;
  final List<StoreLocation> locations;

  const StoreModel({
    required this.id,
    required this.name,
    this.branchName,
    this.photoUrl,
    this.phone,
    this.openingHours,
    this.logoUrl,
    this.locations = const [],
  });

  double? get latitude =>
      locations.isNotEmpty ? locations.first.latitude : null;
  double? get longitude =>
      locations.isNotEmpty ? locations.first.longitude : null;
}
