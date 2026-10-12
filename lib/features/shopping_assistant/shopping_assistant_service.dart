import 'package:supabase_flutter/supabase_flutter.dart';

class ShoppingAssistantService {
  ShoppingAssistantService({required SupabaseClient supabase})
      : _supabase = supabase;

  final SupabaseClient _supabase;

  static const _timeout = Duration(seconds: 30);

  Future<String> sendMessage(List<Map<String, String>> history) async {
    final res = await _supabase.functions
        .invoke('gemini-chat', body: {'messages': history})
        .timeout(_timeout);

    final data = res.data as Map<String, dynamic>;
    return data['response'] as String? ?? 'Sin respuesta.';
  }
}
