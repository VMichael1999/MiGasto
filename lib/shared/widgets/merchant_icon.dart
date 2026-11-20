import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/category_icon.dart';
import '../../domain/entities/movimiento.dart';
import '../../presentation/providers.dart';
import '../merchant_domains.dart';

/// Ícono de un movimiento: el logo del comercio si es conocido y el usuario lo permite;
/// si no, el ícono de su categoría. El logo se pide por internet una sola vez y queda en caché.
class MerchantIcon extends ConsumerWidget {
  const MerchantIcon({
    super.key,
    required this.merchant,
    required this.category,
    this.size = 38,
    this.radius = 12,
    this.iconSize = 19,
  });

  final String merchant;
  final Categoria? category;
  final double size;
  final double radius;
  final double iconSize;

  /// Servicio de íconos de sitios. Solo recibe el dominio del comercio.
  static String logoUrl(String domain) =>
      'https://www.google.com/s2/favicons?domain=$domain&sz=128';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = CategoryIcon(category: category, size: size, radius: radius, iconSize: iconSize);
    final domain = merchantDomain(merchant);
    if (domain == null || !ref.watch(merchantLogosProvider)) return fallback;

    return CachedNetworkImage(
      imageUrl: logoUrl(domain),
      fadeInDuration: const Duration(milliseconds: 160),
      // Mientras carga, o si falla, se ve el ícono de la categoría.
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
      imageBuilder: (_, image) => Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Image(image: image, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
      ),
    );
  }
}
