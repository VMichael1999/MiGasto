// Íconos de línea del rediseño v0.2, generados desde las <symbol> de la propuesta HTML.
// Trazo 1.8, extremos y uniones redondeados, viewBox 24x24.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppIcons {
  food,
  bag,
  film,
  box,
  home,
  list,
  chart,
  gear,
  plus,
  search,
  check,
  checkCircle,
  close,
  info,
  back,
  chevron,
  expand,
  arrowUp,
  arrowDown,
  trash,
  pin,
  card,
  nfc,
  bell,
  img,
  hand,
  salary,
  swap,
  tag,
  file,
  lock,
  wallet,
  share,
  backspace,
  // No están en la propuesta HTML; mismo trazo, para las categorías Transporte y Servicios
  // y para los estados de presupuesto con alerta.
  car,
  bolt,
  alert,
  filter,
  more,
  eye,
  eyeOff;

  String get _body {
    switch (this) {
      case AppIcons.food:
        return '<path d="M7 3v8a2 2 0 0 0 2 2v8M7 3v5M11 3v5a2 2 0 0 1-2 2M17 21V3c-2 1.5-3 4-3 7h3"/>';
      case AppIcons.bag:
        return '<path d="M5 8h14l-1 13H6z"/><path d="M9 8V6a3 3 0 0 1 6 0v2"/>';
      case AppIcons.film:
        return '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M7 4v16M17 4v16M3 9h4M3 15h4M17 9h4M17 15h4"/>';
      case AppIcons.box:
        return '<path d="M3 7l9-4 9 4v10l-9 4-9-4z"/><path d="M3 7l9 4 9-4M12 11v10"/>';
      case AppIcons.home:
        return '<path d="M4 11l8-7 8 7v9a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1z"/>';
      case AppIcons.list:
        return '<path d="M8 6h13M8 12h13M8 18h13M3.5 6h.01M3.5 12h.01M3.5 18h.01"/>';
      case AppIcons.chart:
        return '<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>';
      case AppIcons.gear:
        // Tuerca de 8 dientes (antes era un sol).
        return '<path d="M10.40 5.60 L10.53 2.72 L13.47 2.72 L13.60 5.60 L15.40 6.34 L17.53 4.40 L19.60 6.47 L17.66 8.60 L18.40 10.40 L21.28 10.53 L21.28 13.47 L18.40 13.60 L17.66 15.40 L19.60 17.53 L17.53 19.60 L15.40 17.66 L13.60 18.40 L13.47 21.28 L10.53 21.28 L10.40 18.40 L8.60 17.66 L6.47 19.60 L4.40 17.53 L6.34 15.40 L5.60 13.60 L2.72 13.47 L2.72 10.53 L5.60 10.40 L6.34 8.60 L4.40 6.47 L6.47 4.40 L8.60 6.34z"/><circle cx="12" cy="12" r="2.8"/>';
      case AppIcons.plus:
        return '<path d="M12 5v14M5 12h14"/>';
      case AppIcons.search:
        return '<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>';
      case AppIcons.check:
        return '<path d="M5 12.5l4.5 4.5L19 7"/>';
      case AppIcons.checkCircle:
        return '<circle cx="12" cy="12" r="9"/><path d="M8 12.5l3 3 5-6"/>';
      case AppIcons.close:
        return '<path d="M6 6l12 12M18 6L6 18"/>';
      case AppIcons.info:
        return '<circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8v.01"/>';
      case AppIcons.back:
        return '<path d="M19 12H5M11 6l-6 6 6 6"/>';
      case AppIcons.chevron:
        return '<path d="M9 6l6 6-6 6"/>';
      case AppIcons.expand:
        return '<path d="M6 9l6 6 6-6"/>';
      case AppIcons.arrowUp:
        return '<path d="M12 19V5M6 11l6-6 6 6"/>';
      case AppIcons.arrowDown:
        return '<path d="M12 5v14M6 13l6 6 6-6"/>';
      case AppIcons.trash:
        return '<path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13"/>';
      case AppIcons.pin:
        return '<path d="M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/>';
      case AppIcons.card:
        return '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 10h18M7 15h4"/>';
      case AppIcons.nfc:
        return '<path d="M6 8.5a5 5 0 0 1 0 7M9.5 6a9 9 0 0 1 0 12M13 3.5a13 13 0 0 1 0 17"/>';
      case AppIcons.bell:
        return '<path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z"/><path d="M10 20.5a2 2 0 0 0 4 0"/>';
      case AppIcons.img:
        return '<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="M21 16l-5-5-9 9"/>';
      case AppIcons.hand:
        return '<path d="M4 20h4l3-3h5a2 2 0 0 0 0-4h-4"/><path d="M8 17l-3-3 2-2 3 1"/><path d="M14 9V4M11 7h6"/>';
      case AppIcons.salary:
        return '<rect x="3" y="6" width="18" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/>';
      case AppIcons.swap:
        return '<path d="M4 8h14l-3-3M20 16H6l3 3"/>';
      case AppIcons.tag:
        return '<path d="M3 12V4h8l10 10-8 8z"/><circle cx="7.5" cy="8.5" r="1.5"/>';
      case AppIcons.file:
        return '<path d="M14 3H6a1 1 0 0 0-1 1v16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V8z"/><path d="M14 3v5h5M12 11v6M9 14l3 3 3-3"/>';
      case AppIcons.lock:
        return '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>';
      case AppIcons.wallet:
        return '<path d="M4 7a2 2 0 0 1 2-2h12v4"/><path d="M4 7v10a2 2 0 0 0 2 2h14V9H6a2 2 0 0 1-2-2z"/><path d="M16 14h.01"/>';
      case AppIcons.share:
        return '<path d="M12 15V3M8 7l4-4 4 4"/><path d="M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7"/>';
      case AppIcons.backspace:
        return '<path d="M21 5H8l-5 7 5 7h13z"/><path d="M16 9.5l-5 5M11 9.5l5 5"/>';
      case AppIcons.car:
        return '<path d="M5 17v-5l2-5h10l2 5v5M3 17h18M7 20v-3M17 20v-3M8 13h.01M16 13h.01"/>';
      case AppIcons.bolt:
        return '<path d="M13 3L5 14h6l-1 7 8-11h-6z"/>';
      case AppIcons.filter:
        return '<path d="M3 5h18l-7 8v6l-4 2v-8z"/>';
      case AppIcons.more:
        return '<path d="M12 5h.01M12 12h.01M12 19h.01"/>';
      case AppIcons.alert:
        return '<path d="M12 4l9 16H3z"/><path d="M12 10v4M12 17v.01"/>';
      case AppIcons.eye:
        return '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>';
      case AppIcons.eyeOff:
        return '<path d="M3 3l18 18"/><path d="M10.6 5.1A9.6 9.6 0 0 1 12 5c6.5 0 10 7 10 7a17 17 0 0 1-3.2 4.1M6.6 6.6C3.9 8.4 2 12 2 12s3.5 7 10 7c1.7 0 3.2-.4 4.5-1M9.9 9.9a3 3 0 0 0 4.2 4.2"/>';
    }
  }

  String get svg =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#000000" stroke-width="1.8" stroke-linecap="round" '
      'stroke-linejoin="round">$_body</svg>';
}

/// Tamaños del set: pequeño 16, normal 20, grande 24.
class AppIconSize {
  static const double small = 16;
  static const double normal = 20;
  static const double large = 24;
}

class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = AppIconSize.normal,
    this.color,
    this.semanticLabel,
  });

  final AppIcons icon;
  final double size;

  /// Si es null usa el color de texto del tema (`IconTheme`).
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? Colors.white;
    return SvgPicture.string(
      icon.svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}
