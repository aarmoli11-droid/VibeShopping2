// Pruebas unitarias de los puntos de corte y utilidades responsive.
//
// Cómo correr: flutter test

import 'package:test/test.dart';

import 'package:vibeshopping/core/responsive.dart';

void main() {
  group('VibeResponsive.fromWidth', () {
    test('es móvil por debajo de 600', () {
      expect(VibeResponsive.fromWidth(0), VibeScreenSize.mobile);
      expect(VibeResponsive.fromWidth(390), VibeScreenSize.mobile);
      expect(VibeResponsive.fromWidth(599), VibeScreenSize.mobile);
    });

    test('es tablet entre 600 y 1023', () {
      expect(VibeResponsive.fromWidth(600), VibeScreenSize.tablet);
      expect(VibeResponsive.fromWidth(800), VibeScreenSize.tablet);
      expect(VibeResponsive.fromWidth(1023), VibeScreenSize.tablet);
    });

    test('es escritorio desde 1024', () {
      expect(VibeResponsive.fromWidth(1024), VibeScreenSize.desktop);
      expect(VibeResponsive.fromWidth(1440), VibeScreenSize.desktop);
    });

    test('los límites exactos no se solapan', () {
      expect(VibeResponsive.fromWidth(599), VibeScreenSize.mobile);
      expect(VibeResponsive.fromWidth(600), VibeScreenSize.tablet);
      expect(VibeResponsive.fromWidth(1023), VibeScreenSize.tablet);
      expect(VibeResponsive.fromWidth(1024), VibeScreenSize.desktop);
    });
  });

  group('predicados por ancho', () {
    test('isMobile / isTablet / isDesktop son mutuamente excluyentes', () {
      for (final width in <double>[0, 390, 599, 600, 800, 1023, 1024, 1440]) {
        final flags = [
          VibeResponsive.isMobile(width),
          VibeResponsive.isTablet(width),
          VibeResponsive.isDesktop(width),
        ];
        expect(flags.where((f) => f).length, 1,
            reason: 'ancho $width debe pertenecer a un solo rango');
      }
    });
  });

  group('horizontalPadding', () {
    test('usa el mínimo en móvil y tablet', () {
      expect(VibeResponsive.horizontalPadding(390), 16);
      expect(VibeResponsive.horizontalPadding(800), 16);
      expect(VibeResponsive.horizontalPadding(1200), 16);
    });

    test('centra el contenido en pantallas muy anchas', () {
      expect(VibeResponsive.horizontalPadding(1440), 120);
    });

    test('respeta un mínimo personalizado', () {
      expect(VibeResponsive.horizontalPadding(390, min: 24), 24);
    });
  });
}
