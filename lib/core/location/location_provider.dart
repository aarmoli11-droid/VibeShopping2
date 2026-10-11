// Fuente única de la ubicación del usuario (GPS).
// Independiente del mapa y del asistente: solo expone el estado del permiso,
// la posición actual y los errores. Las features lo consumen vía Provider.
// Fase 1: no integra el GPS en el mapa ni modifica el asistente.

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
  String? _errorMessage;
  bool _isLoading = false;

  LocationStatus get status => _status;
  Position? get position => _position;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
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

    _setLoading(true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _position = position;
      _status = LocationStatus.granted;
      _errorMessage = null;
      notifyListeners();
      return position;
    } catch (_) {
      _apply(LocationStatus.error, 'No se pudo obtener la ubicación actual.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Abre los Ajustes del sistema (útil con permiso denegado permanentemente).
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  // Comprueba servicios + permiso, pidiéndolo solo si askIfNeeded.
  Future<bool> _resolvePermission({required bool askIfNeeded}) async {
    _setLoading(true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _apply(LocationStatus.serviceDisabled,
            'Los servicios de ubicación están desactivados.');
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && askIfNeeded) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _apply(LocationStatus.permissionDenied,
            'Permiso de ubicación denegado.');
        return false;
      }
      if (permission == LocationPermission.deniedForever) {
        _apply(LocationStatus.permissionDeniedForever,
            'Permiso de ubicación denegado permanentemente. Actívalo en Ajustes.');
        return false;
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _apply(LocationStatus.granted, null);
        return true;
      }

      // unableToDetermine u otro estado inesperado.
      _apply(LocationStatus.error, 'No se pudo determinar el permiso de ubicación.');
      return false;
    } catch (_) {
      _apply(LocationStatus.error,
          'No se pudo verificar el permiso de ubicación.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _apply(LocationStatus status, String? error) {
    _status = status;
    _errorMessage = error;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}