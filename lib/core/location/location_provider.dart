// Fuente única de la ubicación del usuario (GPS).
// Independiente del mapa y del asistente: solo expone el estado del permiso y
// la posición actual. Las features lo consumen vía Provider.

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

// Estado del acceso a la ubicación, con los casos que deben distinguirse.
enum LocationStatus {
  initial, // Aún no se ha consultado.
  serviceDisabled, // Los servicios de ubicación están apagados.
  permissionDenied, // El usuario denegó el permiso (se puede volver a pedir).
  permissionDeniedForever, // Denegado permanentemente (solo Ajustes).
  granted, // Permiso concedido.
  error, // Error inesperado al consultar u obtener la ubicación.
}

class LocationProvider extends ChangeNotifier {
  LocationStatus _status = LocationStatus.initial;
  Position? _position;

  LocationStatus get status => _status;
  bool get hasPosition => _position != null;
  bool get isGranted => _status == LocationStatus.granted;

  // Coordenadas listas para compartir con el mapa (latlong2) y el asistente.
  double? get latitude => _position?.latitude;
  double? get longitude => _position?.longitude;

  // Consulta el estado actual sin pedir permiso (por ejemplo al abrir).
  Future<void> initialize() => _resolvePermission(askIfNeeded: false);

  // Solicita permiso cuando corresponde y, si se concede, obtiene la posición.
  Future<bool> requestPermissionAndLocate() async {
    final granted = await _resolvePermission(askIfNeeded: true);
    if (granted) await refreshPosition();
    return granted;
  }

  // Obtiene la posición actual mediante GPS (pide permiso si aún no lo tiene).
  Future<Position?> refreshPosition() async {
    if (_status != LocationStatus.granted) {
      final granted = await _resolvePermission(askIfNeeded: true);
      if (!granted) return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _position = position;
      _status = LocationStatus.granted;
      notifyListeners();
      return position;
    } catch (_) {
      _status = LocationStatus.error;
      notifyListeners();
      return null;
    }
  }

  // Abre los Ajustes del sistema (útil con permiso denegado permanentemente).
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  // Comprueba servicios + permiso, pidiéndolo solo si askIfNeeded.
  Future<bool> _resolvePermission({required bool askIfNeeded}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _status = LocationStatus.serviceDisabled;
        notifyListeners();
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && askIfNeeded) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _status = LocationStatus.permissionDenied;
        notifyListeners();
        return false;
      }
      if (permission == LocationPermission.deniedForever) {
        _status = LocationStatus.permissionDeniedForever;
        notifyListeners();
        return false;
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _status = LocationStatus.granted;
        notifyListeners();
        return true;
      }

      // unableToDetermine u otro estado inesperado.
      _status = LocationStatus.error;
      notifyListeners();
      return false;
    } catch (_) {
      _status = LocationStatus.error;
      notifyListeners();
      return false;
    }
  }
}