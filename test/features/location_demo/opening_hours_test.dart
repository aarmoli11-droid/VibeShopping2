// Pruebas de la lógica pura de horarios (OpeningHours): parseo del JSONB de
// Supabase, distinción entre día cerrado y desconocido, estado actual a una
// hora dada y formato de hora en español. Usa fechas simuladas (sin GPS).

import 'package:test/test.dart';

import 'package:vibeshopping/core/opening_hours.dart';

void main() {
  group('OpeningHours.tryParse', () {
    test('parsea un día con varios intervalos', () {
      final hours = OpeningHours.tryParse({
        'monday': [
          {'open': '06:00', 'close': '10:00'},
          {'open': '14:00', 'close': '22:00'},
        ],
      });
      expect(hours, isNotNull);
      final monday = hours!.forDay('monday');
      expect(monday, hasLength(2));
      expect(monday!.first.open, '06:00');
      expect(monday.last.close, '22:00');
    });

    test('valor nulo o no-objeto devuelve horario desconocido', () {
      expect(OpeningHours.tryParse(null), isNull);
      expect(OpeningHours.tryParse('no-es-un-mapa'), isNull);
      expect(OpeningHours.tryParse(<String, dynamic>{}), isNull);
      expect(OpeningHours.tryParse({'monday': 'texto'}), isNull);
    });

    test('distingue día cerrado (lista vacía) de día desconocido (ausente)',
        () {
      final hours = OpeningHours.tryParse({
        'tuesday': <dynamic>[],
        // 'monday' no está y 'wednesday' es null.
        'wednesday': null,
      });
      expect(hours, isNotNull);
      // Día confirmado como cerrado.
      expect(hours!.forDay('tuesday'), isEmpty);
      // Días sin clave: desconocidos, nunca 'cerrado'.
      expect(hours.forDay('monday'), isNull);
      // Clave con null: desconocida.
      expect(hours.forDay('wednesday'), isNull);
    });

    test('ignora intervalos malformados sin marcar el día como cerrado', () {
      final hours = OpeningHours.tryParse({
        'monday': [
          {'open': '06:00', 'close': '25:00'}, // hora inválida
          {'open': '06:00'}, // falta close
          'basura', // no es mapa
        ],
      });
      expect(hours, isNull); // sin un solo intervalo válido: desconocido.
    });

    test('lista no vacía con al menos un intervalo válido conserva los válidos',
        () {
      final hours = OpeningHours.tryParse({
        'friday': [
          {'open': '08:00', 'close': '17:00'},
          {'open': '99:00', 'close': '17:00'}, // inválido, se descarta
        ],
      });
      final friday = hours!.forDay('friday');
      expect(friday, hasLength(1));
      expect(friday!.single.open, '08:00');
    });
  });

  group('OpeningHours.statusLabel', () {
    // 2026-01-05 (lunes), 2026-01-06 (martes) como fechas simuladas.
    DateTime mondayAt(int hour, [int minute = 0]) =>
        DateTime(2026, 1, 5, hour, minute);
    DateTime tuesdayAt(int hour, [int minute = 0]) =>
        DateTime(2026, 1, 6, hour, minute);

    test('abierto muestra la próxima hora de cierre', () {
      final hours = OpeningHours.tryParse({
        'monday': [
          {'open': '08:00', 'close': '17:00'},
        ],
      });
      expect(hours!.statusLabel(mondayAt(12)), 'Abierto · Cierra a las 5:00 p. m.');
    });

    test('cerrado antes de abrir muestra la próxima apertura', () {
      final hours = OpeningHours.tryParse({
        'monday': [
          {'open': '08:00', 'close': '17:00'},
        ],
      });
      expect(
          hours!.statusLabel(mondayAt(7)), 'Cerrado · Abre a las 8:00 a. m.');
    });

    test('cerrado después de cerrar', () {
      final hours = OpeningHours.tryParse({
        'monday': [
          {'open': '08:00', 'close': '17:00'},
        ],
      });
      expect(hours!.statusLabel(mondayAt(18)), 'Cerrado');
    });

    test('dos intervalos: abierto por la mañana y cerrado en la tarde', () {
      final hours = OpeningHours.tryParse({
        'monday': [
          {'open': '06:00', 'close': '10:00'},
          {'open': '14:00', 'close': '22:00'},
        ],
      });
      expect(
          hours!.statusLabel(mondayAt(8)), 'Abierto · Cierra a las 10:00 a. m.');
      expect(
          hours.statusLabel(mondayAt(13)), 'Cerrado · Abre a las 2:00 p. m.');
      expect(
          hours.statusLabel(mondayAt(16)), 'Abierto · Cierra a las 10:00 p. m.');
    });

    test('día confirmado como cerrado', () {
      final hours = OpeningHours.tryParse({
        'tuesday': <dynamic>[],
      });
      expect(hours!.statusLabel(tuesdayAt(12)), 'Cerrado');
    });

    test('horario desconocido devuelve null (no inventa estado)', () {
      final hours = OpeningHours.tryParse({
        'monday': [
          {'open': '08:00', 'close': '17:00'},
        ],
      });
      // El lunes está definido, el martes no.
      expect(hours!.statusLabel(tuesdayAt(12)), isNull);
    });
  });

  group('OpeningHours.formatTime12', () {
    test('convierte a formato 12 horas en español', () {
      expect(OpeningHours.formatTime12('09:00'), '9:00 a. m.');
      expect(OpeningHours.formatTime12('21:00'), '9:00 p. m.');
      expect(OpeningHours.formatTime12('00:00'), '12:00 a. m.');
      expect(OpeningHours.formatTime12('12:30'), '12:30 p. m.');
      expect(OpeningHours.formatTime12('13:05'), '1:05 p. m.');
    });
  });
}