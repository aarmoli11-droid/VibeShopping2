// Pruebas unitarias del modelo de tienda del mapa (DemoStore): título
// mostrado y mapeo de los datos de sucursal (branch_name, foto, teléfono y
// horarios) desde Supabase. Sin UI ni GPS.

import 'package:test/test.dart';

import 'package:vibeshopping/core/opening_hours.dart';
import 'package:vibeshopping/features/explorer/domain/store_location.dart';
import 'package:vibeshopping/features/explorer/domain/store_model.dart';
import 'package:vibeshopping/features/location_demo/location_demo_logic.dart';
import 'package:vibeshopping/features/location_demo/location_demo_store.dart';

void main() {
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