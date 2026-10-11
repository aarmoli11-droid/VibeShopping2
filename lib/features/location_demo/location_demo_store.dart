// Supermercado del mapa demostrativo, con los campos opcionales de la
// sucursal (Fase 3).

import '../../../core/opening_hours.dart';

class DemoStore {
  final String name;

  // Localidad o identificación de la sucursal (p. ej. "Buenos Aires").
  final String? branchName;

  final String address;
  final double latitude;
  final double longitude;

  // Fotografía real del establecimiento (no el logo).
  final String? photoUrl;

  // Teléfono de contacto de la sucursal.
  final String? phone;

  // Horarios propios de la sucursal. Null si no hay información.
  final OpeningHours? openingHours;

  const DemoStore({
    required this.name,
    this.branchName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    this.phone,
    this.openingHours,
  });

  // Título del encabezado: "BM" sin sucursal o "BM · Buenos Aires" con ella.
  String get displayTitle =>
      branchName == null ? name : '$name · $branchName';
}
