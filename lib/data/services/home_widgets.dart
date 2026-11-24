import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/movimiento.dart';
import '../../shared/widget_snapshot.dart';

/// Pasa a los widgets de la pantalla de inicio lo que deben mostrar.
///
/// iPhone lo guarda en el grupo de la app (`group.com.migasto.co`) y recarga los widgets;
/// Android lo guarda en `migasto_widgets` y avisa a cada widget. Solo se envía si cambió algo
/// que se ve (no la hora de actualización).
class HomeWidgets {
  HomeWidgets({MethodChannel? channel, bool? supported})
      : _channel = channel ?? const MethodChannel('com.example.mi_gasto/accessibility'),
        _supported = supported ?? (!kIsWeb && (Platform.isIOS || Platform.isAndroid));

  final MethodChannel _channel;
  final bool _supported;
  String? _lastShown;

  /// Devuelve si se envió (false si no cambió nada o la plataforma no tiene widgets).
  Future<bool> update(List<Movimiento> all, DateTime now) async {
    if (!_supported) return false;
    final snapshot = WidgetSnapshot.build(all, now);
    final shown = jsonEncode({...snapshot}..remove('updatedAt'));
    if (shown == _lastShown) return false;
    try {
      await _channel.invokeMethod<bool>('updateHomeWidgets', jsonEncode(snapshot));
      _lastShown = shown;
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('No se pudieron actualizar los widgets: ${e.message}');
      return false;
    }
  }
}
