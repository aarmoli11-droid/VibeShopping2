import 'package:supabase_flutter/supabase_flutter.dart';

class ShoppingAssistantService {
  ShoppingAssistantService({required SupabaseClient supabase})
      : _supabase = supabase;

  final SupabaseClient _supabase;

  static const _timeout = Duration(seconds: 30);

  // Envía la conversación y, cuando hay ubicación actual, las coordenadas del
  // usuario para que la Edge Function calcule distancias a cada sucursal.
  Future<String> sendMessage(
    List<Map<String, String>> history, {
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{'messages': history};
    if (latitude != null && longitude != null) {
      body['latitude'] = latitude;
      body['longitude'] = longitude;
    }

    final res = await _supabase.functions
        .invoke('gemini-chat', body: body)
        .timeout(_timeout);

    final data = res.data as Map<String, dynamic>;
    return data['response'] as String? ?? 'Sin respuesta.';
  }
}
