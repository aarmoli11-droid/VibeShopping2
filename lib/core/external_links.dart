// Enlaces externos de la app (sin API de mapas ni scraping): ubicación de una
// sucursal en Google Maps a partir de sus coordenadas, y llamada telefónica.
// Usa url_launcher (dependencia declarada). No integra proveedores externos.

import 'package:url_launcher/url_launcher.dart';

abstract final class ExternalLinks {
  // URL universal de Google Maps con las coordenadas exactas de la sucursal.
  static Uri googleMapsUri({required double latitude, required double longitude}) {
    return Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
  }

  // Abre la ubicación concreta en Google Maps (o en la app de mapas del SO).
  static Future<bool> openGoogleMaps({
    required double latitude,
    required double longitude,
  }) {
    return _launch(googleMapsUri(latitude: latitude, longitude: longitude));
  }

  // Abre el marcador de llamadas con el teléfono de la sucursal.
  static Future<bool> openPhone(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return Future.value(false);
    return _launch(Uri(scheme: 'tel', path: digits));
  }

  static Future<bool> _launch(Uri uri) async {
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}