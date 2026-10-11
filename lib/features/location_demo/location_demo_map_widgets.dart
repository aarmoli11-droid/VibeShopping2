// Marcadores del mapa y controles de zoom (flutter_map).

import 'package:flutter/material.dart';

import 'location_demo_store.dart';

const Color _storeRed = Color(0xFFE53935);
const Color _userBlue = Color(0xFF2196F3);
const Color _labelText = Color(0xFF2C3E50);

// Marcador de un supermercado: punto rojo pequeño + etiqueta con su nombre.
class StoreMarker extends StatelessWidget {
  const StoreMarker({
    super.key,
    required this.store,
    required this.onTap,
  });

  final DemoStore store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _MarkerColumn(
        dot: _MarkerDot(color: _storeRed),
        label: _MarkerLabel(text: store.name, background: Colors.white),
      ),
    );
  }
}

// Marcador diferenciado de la posición real del usuario.
class UserMarker extends StatelessWidget {
  const UserMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MarkerColumn(
      dot: _MarkerDot(color: _userBlue),
      label: _MarkerLabel(
        text: 'Tú',
        background: _userBlue,
        textColor: Colors.white,
      ),
    );
  }
}

// Punto y etiqueta apilados con un espacio pequeño entre ambos.
class _MarkerColumn extends StatelessWidget {
  const _MarkerColumn({required this.dot, required this.label});

  final Widget dot;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(height: 2),
        label,
      ],
    );
  }
}

// Punto pequeño que señala la ubicación exacta.
class _MarkerDot extends StatelessWidget {
  const _MarkerDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}

// Etiqueta pequeña de texto junto al marcador.
class _MarkerLabel extends StatelessWidget {
  const _MarkerLabel({
    required this.text,
    required this.background,
    this.textColor = _labelText,
  });

  final String text;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          height: 1.0,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// Controles +/− sobrepuestos en la esquina superior derecha del mapa.
class ZoomControls extends StatelessWidget {
  const ZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      top: 12,
      child: Column(
        children: [
          _ZoomButton(icon: Icons.add, tooltip: 'Acercar', onPressed: onZoomIn),
          const SizedBox(height: 8),
          _ZoomButton(
              icon: Icons.remove, tooltip: 'Alejar', onPressed: onZoomOut),
        ],
      ),
    );
  }
}

// Botón circular de zoom.
class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: _labelText),
          ),
        ),
      ),
    );
  }
}
