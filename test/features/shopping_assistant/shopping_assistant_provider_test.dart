// ======================================================
// Archivo: test/features/shopping_assistant/
//   shopping_assistant_provider_test.dart
// Responsabilidad: Verifica que el asistente envíe la
//   ubicación actual del usuario al servicio y que, sin
//   ubicación, no envíe coordenadas (el servidor responde
//   precios sin distancias).
// Cómo correr: flutter test
// ======================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vibeshopping/core/location/location_provider.dart';
import 'package:vibeshopping/features/shopping_assistant/shopping_assistant_provider.dart';
import 'package:vibeshopping/features/shopping_assistant/shopping_assistant_service.dart';

SupabaseClient _client() => SupabaseClient(
      'https://example.supabase.co',
      'public-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

// Servicio falso: captura las coordenadas recibidas sin llamar a Supabase.
class _CapturingService extends ShoppingAssistantService {
  _CapturingService() : super(supabase: _client());

  double? latitude;
  double? longitude;

  @override
  Future<String> sendMessage(
    List<Map<String, String>> history, {
    double? latitude,
    double? longitude,
  }) async {
    this.latitude = latitude;
    this.longitude = longitude;
    return 'ok';
  }
}

// LocationProvider falso: no usa GPS, solo expone un estado fijo.
class _FakeLocation extends LocationProvider {
  _FakeLocation({this.statusValue = LocationStatus.granted, this.lat, this.lng});

  final LocationStatus statusValue;
  final double? lat;
  final double? lng;

  @override
  LocationStatus get status => statusValue;
  @override
  bool get isGranted => statusValue == LocationStatus.granted;
  @override
  bool get hasPosition => lat != null && lng != null;
  @override
  double? get latitude => lat;
  @override
  double? get longitude => lng;

  @override
  Future<void> initialize() async {}
  @override
  Future<Position?> refreshPosition() async => null;
}

void main() {
  test('envía la ubicación actual al servicio', () async {
    final service = _CapturingService();
    final provider = ShoppingAssistantProvider(
      service: service,
      locationProvider: _FakeLocation(lat: 9.1733, lng: -83.3374),
    );

    await provider.sendMessage('leche');

    expect(service.latitude, 9.1733);
    expect(service.longitude, -83.3374);
  });

  test('sin ubicación concedida no envía coordenadas', () async {
    final service = _CapturingService();
    final provider = ShoppingAssistantProvider(
      service: service,
      locationProvider: _FakeLocation(statusValue: LocationStatus.permissionDenied),
    );

    await provider.sendMessage('leche');

    expect(service.latitude, isNull);
    expect(service.longitude, isNull);
  });
}
