import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Ubicación tomada al tocar "Agregar ubicación".
class CapturedLocation {
  const CapturedLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.place,
  });

  final double latitude;
  final double longitude;

  /// Metros.
  final double accuracy;

  /// Dirección legible, obtenida en el teléfono a partir de las coordenadas.
  final String? place;
}

enum LocationFailure { servicesOff, denied, deniedForever, unavailable }

class LocationResult {
  const LocationResult.ok(CapturedLocation this.location) : failure = null;
  const LocationResult.failed(LocationFailure this.failure) : location = null;

  final CapturedLocation? location;
  final LocationFailure? failure;

  String get message {
    switch (failure) {
      case LocationFailure.servicesOff:
        return 'Activa la ubicación de tu teléfono para agregarla.';
      case LocationFailure.denied:
        return 'Sin el permiso de ubicación no podemos guardar dónde pagaste.';
      case LocationFailure.deniedForever:
        return 'El permiso de ubicación está bloqueado. Actívalo en los ajustes del teléfono.';
      case LocationFailure.unavailable:
        return 'No pudimos obtener tu ubicación. Prueba de nuevo al aire libre.';
      case null:
        return '';
    }
  }
}

/// La ubicación se pide solo mientras la app está en uso y solo cuando el usuario
/// toca "Agregar ubicación": nunca en segundo plano.
abstract class LocationService {
  Future<LocationResult> captureCurrent();
  Future<void> openAppSettings();
}

class DeviceLocationService implements LocationService {
  @override
  Future<LocationResult> captureCurrent() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult.failed(LocationFailure.servicesOff);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.failed(LocationFailure.deniedForever);
    }
    if (permission == LocationPermission.denied) {
      return const LocationResult.failed(LocationFailure.denied);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationResult.ok(CapturedLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        place: await _address(position.latitude, position.longitude),
      ));
    } catch (_) {
      return const LocationResult.failed(LocationFailure.unavailable);
    }
  }

  /// "Av. Arequipa 3120, San Isidro". Se resuelve en el teléfono.
  Future<String?> _address(double lat, double lng) async {
    try {
      final marks = await Geocoding().placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) return null;
      final m = marks.first;
      final street = [m.thoroughfare, m.subThoroughfare]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .join(' ')
          .trim();
      final zone = (m.subLocality?.trim().isNotEmpty ?? false) ? m.subLocality! : m.locality;
      final parts = [
        if (street.isNotEmpty) street,
        if (zone != null && zone.trim().isNotEmpty) zone.trim(),
      ];
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();
}
