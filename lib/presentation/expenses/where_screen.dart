import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/config/env.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/aliases.dart';
import '../../domain/entities/movimiento.dart';
import '../../shared/format.dart';
import '../../shared/widgets/app_icons.dart';
import '../providers.dart';

enum _Period { week, month, all }

class _Zone {
  _Zone(this.name);
  final String name;
  final List<Movimiento> items = [];

  double get total => items.where((m) => m.esGasto).fold(0.0, (s, m) => s + m.amount);

  LatLng get center {
    final lat = items.fold(0.0, (s, m) => s + m.latitud!) / items.length;
    final lng = items.fold(0.0, (s, m) => s + m.longitud!) / items.length;
    return LatLng(lat, lng);
  }

  /// "Wong y 2 más": el comercio de mayor monto y cuántos hay además.
  String subtitleFor(Map<String, String> aliases) {
    final sorted = [...items]..sort((a, b) => b.amount.compareTo(a.amount));
    final extra = items.length - 1;
    final name = displayName(sorted.first.merchant, aliases);
    return extra <= 0 ? name : '$name y $extra más';
  }
}

/// Los pagos con ubicación, agrupados por zona.
class WhereScreen extends ConsumerStatefulWidget {
  const WhereScreen({super.key});

  @override
  ConsumerState<WhereScreen> createState() => _WhereScreenState();
}

class _WhereScreenState extends ConsumerState<WhereScreen> {
  _Period _period = _Period.week;
  GoogleMapController? _map;

  bool _inPeriod(DateTime d) {
    final now = DateTime.now();
    switch (_period) {
      case _Period.week:
        return d.isAfter(now.subtract(const Duration(days: 7)));
      case _Period.month:
        return d.year == now.year && d.month == now.month;
      case _Period.all:
        return true;
    }
  }

  List<_Zone> _zones(List<Movimiento> all) {
    final zones = <String, _Zone>{};
    for (final m in all.where((m) => m.tieneUbicacion && _inPeriod(m.date))) {
      final name = (m.lugar != null && m.lugar!.contains(','))
          ? m.lugar!.split(',').last.trim()
          : (m.lugar ?? 'Sin dirección');
      zones.putIfAbsent(name, () => _Zone(name)).items.add(m);
    }
    final list = zones.values.toList()..sort((a, b) => b.items.length.compareTo(a.items.length));
    return list;
  }

  void _fit(List<_Zone> zones) {
    final controller = _map;
    if (controller == null || zones.isEmpty) return;
    final points = zones.expand((z) => z.items).map((m) => LatLng(m.latitud!, m.longitud!)).toList();
    if (points.length == 1) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      return;
    }
    final south = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final north = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final west = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final east = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    controller.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east)),
      48,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final zones = _zones(ref.watch(expensesStateProvider));
    final first = zones.isEmpty ? const LatLng(-12.0464, -77.0428) : zones.first.center;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Env.hasMapsKey
                      ? GoogleMap(
                          initialCameraPosition: CameraPosition(target: first, zoom: 13),
                          onMapCreated: (c) {
                            _map = c;
                            _fit(zones);
                          },
                          markers: {
                            for (final z in zones)
                              Marker(
                                markerId: MarkerId(z.name),
                                position: z.center,
                                infoWindow: InfoWindow(
                                  title: z.name,
                                  snippet: '${z.items.length} pagos · ${formatSoles(z.total)}',
                                ),
                              ),
                          },
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          myLocationButtonEnabled: false,
                        )
                      : Container(
                          color: scheme.surface,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'El mapa necesita la clave de Google Maps en el archivo .env.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Tooltip(
                      message: 'Volver',
                      child: Material(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.field),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.field),
                          onTap: () => context.pop(),
                          child: SizedBox(
                            width: AppSizes.iconButton,
                            height: AppSizes.iconButton,
                            child: Center(child: AppIcon(AppIcons.back, color: scheme.onSurface)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Dónde pagaste', style: theme.textTheme.headlineSmall),
                      SegmentedButton<_Period>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(visualDensity: VisualDensity.compact),
                        segments: const [
                          ButtonSegment(value: _Period.week, label: Text('Semana')),
                          ButtonSegment(value: _Period.month, label: Text('Mes')),
                          ButtonSegment(value: _Period.all, label: Text('Todo')),
                        ],
                        selected: {_period},
                        onSelectionChanged: (s) {
                          setState(() => _period = s.first);
                          WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _fit(_zones(ref.read(expensesStateProvider))));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: zones.isEmpty
                        ? Center(
                            child: Text(
                              'Todavía no hay pagos con ubicación en este período. Agrégala desde el detalle de un movimiento.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                          )
                        : ListView(
                            children: [
                              for (var i = 0; i < zones.length; i++) ...[
                                if (i > 0) Divider(color: scheme.outline, height: 1),
                                _zoneRow(context, zones[i]),
                              ],
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  'Solo aparecen los pagos con ubicación. Los que no la tienen no se muestran.',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoneRow(BuildContext context, _Zone zone) {
    final aliases = ref.watch(aliasesProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: '${zone.name}, ${zone.items.length} pagos, ${formatSoles(zone.total)}. ${zone.subtitleFor(aliases)}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: scheme.onSurface, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                '${zone.items.length}',
                style: theme.textTheme.titleSmall!.copyWith(color: scheme.surface),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone.name, style: theme.textTheme.titleSmall),
                  Text(zone.subtitleFor(aliases), style: theme.textTheme.bodySmall!.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Text(
              formatSoles(zone.total),
              style: AppText.amount(theme.textTheme.titleSmall!),
            ),
          ],
        ),
      ),
    );
  }
}
