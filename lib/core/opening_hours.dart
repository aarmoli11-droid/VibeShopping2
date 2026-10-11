// Horarios de apertura de una sucursal (columna `opening_hours` jsonb).
// Lógica pura y testeable, sin Flutter ni Supabase.
//
// Formato de la columna (ver supabase/manual_sql):
//   - Claves estables en inglés: monday..sunday.
//   - Cada clave es una lista de intervalos {open, close} en formato "HH:mm"
//     (hora de 24 horas).
//   - Clave ausente o nula  = horario desconocido.
//   - Lista vacía           = día confirmado como cerrado.
//   - Lista con intervalos  = horarios conocidos para ese día.

// Intervalo de apertura dentro de un mismo día natural.
class OpeningInterval {
  const OpeningInterval({required this.open, required this.close});

  // Hora de apertura en "HH:mm" (24 h).
  final String open;

  // Hora de cierre en "HH:mm" (24 h).
  final String close;
}

// Horarios por día de una sucursal. Solo incluye los días con información
// explícita (con intervalos o confirmados como cerrados); un día ausente se
// interpreta como horario desconocido, nunca como cerrado.
class OpeningHours {
  OpeningHours._(this._byDay);

  // Claves estables de los días (inglés), en orden Lunes..Domingo.
  static const List<String> dayKeys = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final Map<String, List<OpeningInterval>> _byDay;

  // Intervalos de un día, o null si el horario de ese día es desconocido.
  // Una lista vacía significa que el día está confirmado como cerrado.
  List<OpeningInterval>? forDay(String dayKey) =>
      _byDay.containsKey(dayKey) ? _byDay[dayKey] : null;

  // Parsea el valor jsonb de Supabase. Devuelve null si el valor es nulo o no
  // contiene días con información válida (horario desconocido).
  static OpeningHours? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final byDay = <String, List<OpeningInterval>>{};
    for (final dayKey in dayKeys) {
      final value = raw[dayKey];
      if (value is! List) continue; // Nulo o malformado: desconocido.

      if (value.isEmpty) {
        // Lista vacía: día confirmado como cerrado.
        byDay[dayKey] = const [];
        continue;
      }

      final intervals = <OpeningInterval>[];
      for (final item in value) {
        if (item is! Map) continue;
        final open = item['open'];
        final close = item['close'];
        if (open is String &&
            close is String &&
            _isValidTime(open) &&
            _isValidTime(close)) {
          intervals.add(OpeningInterval(open: open, close: close));
        }
      }
      // Lista no vacía pero sin intervalos válidos: se omite (desconocido)
      // para no reportar por error un día como cerrado.
      if (intervals.isNotEmpty) byDay[dayKey] = intervals;
    }
    if (byDay.isEmpty) return null;
    return OpeningHours._(byDay);
  }

  // Estado textual de la sucursal para la fecha/hora dadas. Devuelve null
  // cuando el horario de hoy es desconocido (la interfaz muestra
  // "Horario no disponible").
  String? statusLabel(DateTime now) {
    final today = forDay(dayKeyFor(now.weekday));
    if (today == null) return null;
    if (today.isEmpty) return 'Cerrado';

    final currentMinutes = now.hour * 60 + now.minute;

    // Abierto en este momento: se muestra la próxima hora de cierre.
    for (final interval in today) {
      final open = _toMinutes(interval.open);
      final close = _toMinutes(interval.close);
      if (currentMinutes >= open && currentMinutes < close) {
        return 'Abierto · Cierra a las ${formatTime12(interval.close)}';
      }
    }

    // Cerrado pero aún abre hoy: se muestra la próxima apertura.
    for (final interval in today) {
      if (_toMinutes(interval.open) > currentMinutes) {
        return 'Cerrado · Abre a las ${formatTime12(interval.open)}';
      }
    }

    return 'Cerrado';
  }

  // Clave del día a partir de DateTime.weekday (1 = lunes .. 7 = domingo).
  static String dayKeyFor(int weekday) => dayKeys[weekday - 1];

  // "HH:mm" (24 h) -> hora legible en español ("9:00 p. m.").
  static String formatTime12(String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour < 12 ? 'a. m.' : 'p. m.';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  static bool _isValidTime(String value) =>
      RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').hasMatch(value);

  static int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}