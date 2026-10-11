// Pruebas unitarias de la lógica pura del mapa de Ubicación:
// filtro por radio, ampliación de radio, mapeo de tiendas válidas y
// resolución de estados. Usa ubicaciones simuladas (sin GPS real).

import 'package:test/test.dart';

import 'package:vibeshopping/core/location/location_provider.dart';
import 'package:vibeshopping/core/opening_hours.dart';
import 'package:vibeshopping/features/explorer/domain/store_location.dart';
import 'package:vibeshopping/features/explorer/domain/store_model.dart';
import 'package:vibeshopping/features/location_demo/location_demo_data.dart';
import 'package:vibeshopping/features/location_demo/location_demo_logic.dart';
import 'package:vibeshopping/features/location_demo/location_demo_store.dart';

const double _userLat = 9.3760;
const double _userLng = -83.7025;

DemoStore _storeAt(String name, double lat, double lng) =>
    DemoStore(name: name, address: name, latitude: lat, longitude: lng);

MapContentState _resolve({
  bool storesLoading = false,
  bool storesError = false,
  LocationStatus locationStatus = LocationStatus.initial,
  bool hasPosition = false,
  int visibleStoreCount = 0,
}) =>
    LocationDemoLogic.resolveContentState(
      storesLoading: storesLoading,
      storesError: storesError,
      locationStatus: locationStatus,
      hasPosition: hasPosition,
      visibleStoreCount: visibleStoreCount,
    );

void main() {
  group('LocationDemoLogic.storesWithinRadius', () {
    final stores = [
      _storeAt('Cerca', 9.3760, -83.6900), // ~1.4 km
      _storeAt('Medio', 9.3760, -83.6700), // ~3.6 km
      _storeAt('Lejos', 9.3760, -83.5500), // ~16.7 km
    ];

    test('incluye solo las tiendas dentro del radio', () {
      final result = LocationDemoLogic.storesWithinRadius(
        stores: stores,
        userLatitude: _userLat,
        userLongitude: _userLng,
        radiusKm: 5,
      );
      expect(result.map((s) => s.name), containsAll(['Cerca', 'Medio']));
      expect(result.map((s) => s.name), isNot(contains('Lejos')));
      expect(result.length, 2);
    });

    test('un radio mayor incluye más tiendas', () {
      final result = LocationDemoLogic.storesWithinRadius(
        stores: stores,
        userLatitude: _userLat,
        userLongitude: _userLng,
        radiusKm: 20,
      );
      expect(result.length, 3);
    });

    test('devuelve vacío si nada cae en el radio', () {
      final result = LocationDemoLogic.storesWithinRadius(
        stores: stores,
        userLatitude: _userLat,
        userLongitude: _userLng,
        radiusKm: 0.1,
      );
      expect(result, isEmpty);
    });
  });

  group('Haversine existente con ubicaciones simuladas', () {
    test('la distancia conocida coincide con la función existente', () {
      final distance =
          LocationDemoData.haversineKm(_userLat, _userLng, 9.3760, -83.6900);
      expect(distance, closeTo(1.37, 0.05));
    });
  });

  group('Ampliación de radio', () {
    test('la secuencia es 5 → 10 → 15', () {
      expect(LocationDemoLogic.nextRadiusKm(5), 10);
      expect(LocationDemoLogic.nextRadiusKm(10), 15);
    });

    test('no amplía más allá de 15 km', () {
      expect(LocationDemoLogic.nextRadiusKm(15), 15);
      expect(LocationDemoLogic.canExpandRadius(15), isFalse);
      expect(LocationDemoLogic.canExpandRadius(10), isTrue);
    });
  });

  group('LocationDemoLogic.demoStoresFromModels', () {
    test('descarta tiendas sin coordenadas válidas', () {
      final models = [
        const StoreModel(id: 'a', name: 'Con coords', locations: [
          StoreLocation(latitude: 9.38, longitude: -83.70),
        ]),
        const StoreModel(id: 'b', name: 'Sin coords'),
        const StoreModel(id: 'c', name: 'Cero', locations: [
          StoreLocation(latitude: 0, longitude: 0),
        ]),
      ];
      final result = LocationDemoLogic.demoStoresFromModels(models);
      expect(result.length, 1);
      expect(result.single.name, 'Con coords');
    });
  });

  group('LocationDemoLogic.resolveContentState', () {
    test('cargando supermercados', () {
      expect(_resolve(storesLoading: true), MapContentState.loadingStores);
    });

    test('error de supermercados', () {
      expect(_resolve(storesError: true), MapContentState.storesError);
    });

    test('servicios de ubicación desactivados', () {
      expect(_resolve(locationStatus: LocationStatus.serviceDisabled),
          MapContentState.serviceDisabled);
    });

    test('permiso denegado', () {
      expect(_resolve(locationStatus: LocationStatus.permissionDenied),
          MapContentState.permissionDenied);
    });

    test('permiso denegado permanentemente', () {
      expect(_resolve(locationStatus: LocationStatus.permissionDeniedForever),
          MapContentState.permissionDeniedForever);
    });

    test('error de ubicación', () {
      expect(_resolve(locationStatus: LocationStatus.error),
          MapContentState.locationError);
    });

    test('obteniendo ubicación (permiso concedido sin posición)', () {
      expect(_resolve(locationStatus: LocationStatus.granted),
          MapContentState.acquiringLocation);
    });

    test('sin supermercados cercanos', () {
      expect(
          _resolve(
            locationStatus: LocationStatus.granted,
            hasPosition: true,
            visibleStoreCount: 0,
          ),
          MapContentState.noNearby);
    });

    test('supermercados cargados', () {
      expect(
          _resolve(
            locationStatus: LocationStatus.granted,
            hasPosition: true,
            visibleStoreCount: 3,
          ),
          MapContentState.ready);
    });
  });

  group('DemoStore.displayTitle', () {
    test('con branch_name muestra "nombre · sucursal"', () {
      final store = DemoStore(
        name: 'BM',
        branchName: 'Buenos Aires',
        address: 'Centro',
        latitude: 9.38,
        longitude: -83.70,
      );
      expect(store.displayTitle, 'BM · Buenos Aires');
    });

    test('sin branch_name muestra solo el nombre', () {
      final store = DemoStore(
        name: 'BM',
        address: 'Centro',
        latitude: 9.38,
        longitude: -83.70,
      );
      expect(store.displayTitle, 'BM');
    });
  });

  group('LocationDemoLogic.transportEstimates (ubicaciones simuladas)', () {
    test('usa Haversine y las velocidades existentes de VibeTransport', () {
      final estimates = LocationDemoLogic.transportEstimates(
        store: _storeAt('Tienda', 9.3760, -83.6900),
        userLatitude: _userLat,
        userLongitude: _userLng,
      );
      expect(estimates, hasLength(5));
      expect(
          estimates.map((e) => e.mode).toSet(),
          {
            TransportMode.car,
            TransportMode.bus,
            TransportMode.moto,
            TransportMode.bike,
            TransportMode.walking,
          });

      // Sin routing: la misma distancia en línea recta para todos los medios.
      for (final estimate in estimates) {
        expect(estimate.distanceKm, closeTo(1.37, 0.05));
      }

      // Tiempos con car 30 / bus 20 / moto 35 / bici 15 / a pie 5 km/h.
      final byMode = {for (final e in estimates) e.mode: e.minutes};
      expect(byMode[TransportMode.car], 3);
      expect(byMode[TransportMode.bus], 5);
      expect(byMode[TransportMode.moto], 3);
      expect(byMode[TransportMode.bike], 6);
      expect(byMode[TransportMode.walking], 17);
    });
  });

  group('LocationDemoLogic.demoStoresFromModels con campos opcionales', () {
    test('mapea branch_name, photo_url, phone y opening_hours', () {
      final models = [
        StoreModel(
          id: 'a',
          name: 'BM',
          branchName: 'Buenos Aires',
          photoUrl: 'https://ejemplo/foto.jpg',
          phone: '+506 2222 0000',
          openingHours: OpeningHours.tryParse({
            'monday': [
              {'open': '08:00', 'close': '17:00'},
            ],
          }),
          locations: const [
            StoreLocation(latitude: 9.38, longitude: -83.70, address: 'Centro'),
          ],
        ),
      ];
      final store = LocationDemoLogic.demoStoresFromModels(models).single;
      expect(store.name, 'BM');
      expect(store.branchName, 'Buenos Aires');
      expect(store.photoUrl, 'https://ejemplo/foto.jpg');
      expect(store.phone, '+506 2222 0000');
      expect(store.openingHours, isNotNull);
      expect(store.openingHours!.forDay('monday'), hasLength(1));
    });

    test('campos nulos se mantienen nulos (no se inventa información)', () {
      final models = [
        const StoreModel(id: 'a', name: 'BM', locations: [
          StoreLocation(latitude: 9.38, longitude: -83.70),
        ]),
      ];
      final store = LocationDemoLogic.demoStoresFromModels(models).single;
      expect(store.branchName, isNull);
      expect(store.photoUrl, isNull);
      expect(store.phone, isNull);
      expect(store.openingHours, isNull);
      expect(store.displayTitle, 'BM');
    });
  });
}