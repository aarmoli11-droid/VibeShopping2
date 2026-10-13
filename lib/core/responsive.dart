// Utilidades responsive compartidas: puntos de corte, tamaño de pantalla y
// anchuras máximas de contenido.
//
// Las decisiones se basan siempre en el ancho real disponible (no en la
// plataforma), de modo que la interfaz responde también cuando se redimensiona
// la ventana en escritorio.

import 'package:flutter/widgets.dart';

// Rangos de ancho de ventana.
enum VibeScreenSize { mobile, tablet, desktop }

abstract final class VibeResponsive {
  // Puntos de corte en píxeles lógicos de ancho.
  // - mobile:  ancho < 600
  // - tablet:  600 <= ancho < 1024
  // - desktop: ancho >= 1024
  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1024;

  // Ancho máximo recomendado para bloques de contenido largos en escritorio.
  static const double maxContentWidth = 1200;

  static VibeScreenSize fromWidth(double width) {
    if (width < tabletBreakpoint) return VibeScreenSize.mobile;
    if (width < desktopBreakpoint) return VibeScreenSize.tablet;
    return VibeScreenSize.desktop;
  }

  static VibeScreenSize sizeOf(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static bool isMobile(double width) => width < tabletBreakpoint;

  static bool isTablet(double width) =>
      width >= tabletBreakpoint && width < desktopBreakpoint;

  static bool isDesktop(double width) => width >= desktopBreakpoint;

  // Margen lateral que centra el contenido hasta maxContentWidth. Nunca baja
  // del mínimo indicado (por defecto 16), así en móvil/tablet coincide con el
  // margen habitual y en escritorio evita que el contenido se estire.
  static double horizontalPadding(double width, {double min = 16}) {
    final side = (width - maxContentWidth) / 2;
    return side < min ? min : side;
  }
}
