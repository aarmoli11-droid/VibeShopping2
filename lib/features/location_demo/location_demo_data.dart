// Datos del mapa de supermercados de San Isidro de El General.
// Las tiendas se cargan desde Supabase (tabla `supermarkets`) en
// location_demo_screen.dart; aquí quedan los tiles del mapa, la posición
// ficticia del usuario y el cálculo de distancia (Haversine).

import 'dart:math' as math;

abstract final class LocationDemoData {
  // Tiles de OpenStreetMap (sin API key).
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // User-Agent de las peticiones de tiles (buena práctica de OSM).
  static const String userAgentPackageName = 'com.example.vibeshopping';

  // Atribución requerida por la política de OSM. El widget la muestra como
  // 'flutter_map | © OpenStreetMap contributors'.
  static const String attribution = 'OpenStreetMap contributors';

  // Posición de referencia del usuario (centro de San Isidro).
  // En una versión real esto se reemplaza por la ubicación del GPS.
  static const double userLatitude = 9.3760;
  static const double userLongitude = -83.7025;

  // Zoom inicial para ver el usuario y todas las tiendas.
  static const double initialZoom = 13.5;

  // Límites de zoom del mapa.
  static const double minZoom = 10;
  static const double maxZoom = 18;

  // Supermercados reales de San Isidro de El General.
  // Se cargan desde Supabase (tabla `supermarkets`) en location_demo_screen.

  // Radio promedio de la Tierra en kilómetros.
  static const double _earthRadiusKm = 6371.0;

  // Distancia en línea recta entre dos coordenadas (Haversine).
  static double haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    double toRad(double deg) => deg * math.pi / 180;

    final dLat = toRad(lat2 - lat1);
    final dLon = toRad(lon2 - lon1);

    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(toRad(lat1)) *
            math.cos(toRad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);

    return 2 * _earthRadiusKm * math.asin(math.sqrt(a));
  }
}