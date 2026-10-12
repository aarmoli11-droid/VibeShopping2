import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

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
  ShoppingAssistantProvider({required ShoppingAssistantService service})
      : _service = service;

  final ShoppingAssistantService _service;

  final List<ShoppingAssistantMessage> _messages = [
    const ShoppingAssistantMessage(
      text: 'Pregúntame sobre tus compras y te ayudaré a elegir la mejor opción.',
    ),
  ];
  bool _isLoading = false;

  List<ShoppingAssistantMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    _messages.add(ShoppingAssistantMessage(text: text, isUser: true));
    _isLoading = true;
    notifyListeners();

    final history = _messages
        .where((m) => !m.isError)
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'text': m.text,
            })
        .toList();

    try {
      final response = await _service.sendMessage(history);
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
