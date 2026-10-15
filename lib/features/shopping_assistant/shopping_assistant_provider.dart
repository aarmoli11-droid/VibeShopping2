import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import '../../core/location/location_provider.dart';
import 'shopping_assistant_service.dart';

class ShoppingAssistantMessage {
  final String text;
  final bool isUser;
  final bool isError;

  const ShoppingAssistantMessage({
    required this.text,
    this.isUser = false,
    this.isError = false,
  });
}

class ShoppingAssistantProvider extends ChangeNotifier {
  ShoppingAssistantProvider({
    required ShoppingAssistantService service,
    LocationProvider? locationProvider,
  })  : _service = service,
        _locationProvider = locationProvider;

  final ShoppingAssistantService _service;

  // Fuente única de la ubicación (GPS). Opcional: sin ella el asistente sigue
  // funcionando, pero sin distancias ni recomendación por cercanía.
  final LocationProvider? _locationProvider;

  final List<ShoppingAssistantMessage> _messages = [
    const ShoppingAssistantMessage(
      text: 'Pregúntame sobre tus compras y te ayudaré a elegir la mejor opción.',
    ),
  ];
  bool _isLoading = false;

  List<ShoppingAssistantMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  // Prepara la ubicación al abrir el asistente, sin pedir permiso: si ya se
  // concedió (por ejemplo desde el mapa), obtiene la posición actual. Si no,
  // el asistente responderá sin distancias hasta que el permiso exista.
  Future<void> prepareLocation() async {
    final location = _locationProvider;
    if (location == null) return;
    if (location.status == LocationStatus.initial) {
      await location.initialize();
    }
    if (location.isGranted && !location.hasPosition) {
      await location.refreshPosition();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    _messages.add(ShoppingAssistantMessage(text: text, isUser: true));
    _isLoading = true;
    notifyListeners();

    // Asegura coordenadas actuales antes de calcular distancias en el servidor.
    await prepareLocation();

    final history = _messages
        .where((m) => !m.isError)
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'text': m.text,
            })
        .toList();

    try {
      final response = await _service.sendMessage(
        history,
        latitude: _locationProvider?.latitude,
        longitude: _locationProvider?.longitude,
      );
      _messages.add(ShoppingAssistantMessage(text: response));
    } catch (e) {
      _messages.add(ShoppingAssistantMessage(
        text: _describeError(e),
        isError: true,
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _describeError(Object error) {
    if (error is FunctionException) {
      if (error.status == 429) {
        return 'En este momento el asistente alcanzó el límite temporal de consultas. '
            'Intenta nuevamente en unos segundos.';
      }
      if (error.status == 503) {
        return 'El asistente está saturado en este momento. '
            'Intenta nuevamente en unos segundos.';
      }
      final details = error.details;
      if (details is Map && details['error'] is String) {
        return details['error'] as String;
      }
      return 'Error ${error.status} · ${error.reasonPhrase}';
    }
    return 'No se pudo conectar con el asistente.';
  }
}
