// Lógica pura del mapa de Ubicación: filtro por radio, mapeo de tiendas con
// coordenadas válidas y resolución del estado a mostrar.
// Sin UI ni GPS: todo es testeable con ubicaciones simuladas.

import '../../core/location/location_provider.dart';
import '../../core/vibe_transport.dart';
import '../explorer/domain/store_model.dart';
import 'location_demo_data.dart';
import 'location_demo_store.dart';

// Estados de contenido que la pantalla debe distinguir.
enum MapContentState {
  loadingStores, // Cargando supermercados desde Supabase.
  storesError, // Error de conexión o consulta a Supabase.
  acquiringLocation, // Permiso concedido, obteniendo la posición.
  serviceDisabled, // Servicios de ubicación desactivados.
  permissionDenied, // Permiso denegado (se puede volver a pedir).
  permissionDeniedForever, // Denegado permanentemente (solo Ajustes).
  locationError, // Error al obtener la ubicación.
  noNearby, // Ubicación disponible pero sin supermercados en el radio.
  ready, // Supermercados cargados correctamente.
}

abstract final class LocationDemoLogic {
  // Radios de búsqueda, ampliables manualmente: 5 km → 10 km → 15 km.
  static const List<double> radiusStepsKm = [5.0, 10.0, 15.0];
  static const double initialRadiusKm = 5.0;

  // Convierte los supermercados de Supabase en tiendas del mapa, descartando
  // los que no tengan coordenadas válidas.
  static List<DemoStore> demoStoresFromModels(List<StoreModel> stores) {
    final result = <DemoStore>[];
    for (final store in stores) {
      final lat = store.latitude;
      final lng = store.longitude;
      if (!_isValidCoordinate(lat, lng)) continue;
      result.add(DemoStore(
        name: store.name,
        branchName: store.branchName,
        address: store.locations.isNotEmpty
            ? store.locations.first.address ?? ''
            : '',
        latitude: lat!,
        longitude: lng!,
        photoUrl: store.photoUrl,
        phone: store.phone,
        openingHours: store.openingHours,
      ));
    }
    return result;
  }

  // Tiendas dentro del radio, usando la función Haversine existente.
  static List<DemoStore> storesWithinRadius({
    required List<DemoStore> stores,
    required double userLatitude,
    required double userLongitude,
    required double radiusKm,
  }) {
    final result = <DemoStore>[];
    for (final store in stores) {
      final distance = LocationDemoData.haversineKm(
        userLatitude,
        userLongitude,
        store.latitude,
        store.longitude,
      );
      if (distance <= radiusKm) result.add(store);
    }
    return result;
  }

  // ¿Se puede ampliar el radio? (5 → 10 → 15, y 15 es el máximo).
  static bool canExpandRadius(double currentRadiusKm) =>
      currentRadiusKm < radiusStepsKm.last;

  // Siguiente radio de la secuencia, o el máximo si ya está en el tope.
  static double nextRadiusKm(double currentRadiusKm) {
    for (final radius in radiusStepsKm) {
      if (radius > currentRadiusKm) return radius;
    }
    return radiusStepsKm.last;
  }

  // Estimaciones de traslado a una sucursal desde las coordenadas GPS actuales.
  // Usa la función Haversine existente y las velocidades de VibeTransport.
  // Devuelve la MISMA distancia en línea recta para todos los medios (no hay
  // routing aún) con su tiempo estimado; un futuro servicio de rutas solo debe
  // sustituir esta función sin rediseñar la pantalla.
  static List<TransportEstimate> transportEstimates({
    required DemoStore store,
    required double userLatitude,
    required double userLongitude,
  }) {
    final distance = LocationDemoData.haversineKm(
      userLatitude,
      userLongitude,
      store.latitude,
      store.longitude,
    );
    const speeds = [
      (TransportMode.car, VibeTransport.carKmh),
      (TransportMode.bus, VibeTransport.busKmh),
      (TransportMode.moto, VibeTransport.motoKmh),
      (TransportMode.bike, VibeTransport.bikeKmh),
      (TransportMode.walking, VibeTransport.walkingKmh),
    ];
    return [
      for (final entry in speeds)
        TransportEstimate(
          mode: entry.$1,
          distanceKm: distance,
          minutes: VibeTransport.travelMinutes(distance, entry.$2),
        ),
    ];
  }

  // Determina qué estado mostrar a partir del estado de datos y de ubicación.
  static MapContentState resolveContentState({
    required bool storesLoading,
    required bool storesError,
    required LocationStatus locationStatus,
    required bool hasPosition,
    required int visibleStoreCount,
  }) {
    if (storesLoading) return MapContentState.loadingStores;
    if (storesError) return MapContentState.storesError;

    switch (locationStatus) {
      case LocationStatus.initial:
      case LocationStatus.granted:
        if (!hasPosition) return MapContentState.acquiringLocation;
        return visibleStoreCount > 0
            ? MapContentState.ready
            : MapContentState.noNearby;
      case LocationStatus.serviceDisabled:
        return MapContentState.serviceDisabled;
      case LocationStatus.permissionDenied:
        return MapContentState.permissionDenied;
      case LocationStatus.permissionDeniedForever:
        return MapContentState.permissionDeniedForever;
      case LocationStatus.error:
        return MapContentState.locationError;
    }
  }

  static bool _isValidCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    // (0, 0) es casi siempre un marcador de posición ausente.
    if (lat == 0 && lng == 0) return false;
    return true;
  }
}

// Medio de transporte con estimación de traslado a una sucursal.
enum TransportMode { car, bus, moto, bike, walking }

// Estimación de un medio de transporte: distancia en línea recta (común a
// todos los medios) y tiempo estimado con la velocidad de VibeTransport.
class TransportEstimate {
  const TransportEstimate({
    required this.mode,
    required this.distanceKm,
    required this.minutes,
  });

  final TransportMode mode;
  final double distanceKm;
  final int minutes;
}