import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/category_icon.dart';
import '../../domain/entities/movimiento.dart';
import '../../presentation/providers.dart';
import '../labels.dart';
import '../merchant_domains.dart';

/// Ícono de un movimiento: el logo del comercio si es conocido y el usuario lo permite;
/// si no, el ícono de su categoría. El logo se pide por internet una sola vez y queda en caché.
///
/// Cuando la categoría tiene un ícono genérico (las flechas de una transferencia recibida,
/// «Otros») y el pago vino por Yape, Plin o Lemon, en su lugar se ve el ícono de la billetera,
/// que va dentro de la app.
class MerchantIcon extends ConsumerWidget {
  const MerchantIcon({
    super.key,
    required this.merchant,
    required this.category,
    this.source,
    this.size = 38,
    this.radius = 12,
    this.iconSize = 19,
  });

  final String merchant;
  final Categoria? category;
  final PaymentSource? source;
  final double size;
  final double radius;
  final double iconSize;

  /// Categorías cuyo ícono no dice nada del pago: ahí dice más la billetera.
  static const _genericCategories = {
    Categoria.transferenciaRecibida,
    Categoria.otrosIngresos,
    Categoria.otros,
  };

  static const _walletByDomain = {
    'yape.com.pe': PaymentSource.yape,
    'plin.pe': PaymentSource.plin,
  };

  Widget _wallet(PaymentSource wallet) => _WalletIcon(
        asset: walletAsset(wallet)!,
        label: sourceLabel(wallet),
        size: size,
        radius: radius,
        // El de Plin es una burbuja sobre fondo transparente; Yape y Lemon llenan el cuadro.
        padded: wallet == PaymentSource.plin,
      );

  /// Ícono de la billetera, o `null` si la fuente no tiene uno.
  static String? walletAsset(PaymentSource? source) => switch (source) {
        PaymentSource.yape => 'assets/wallets/yape.png',
        PaymentSource.plin => 'assets/wallets/plin.png',
        PaymentSource.lemon => 'assets/wallets/lemon.png',
        _ => null,
      };

  /// Servicio de íconos de sitios. Solo recibe el dominio del comercio.
  static String logoUrl(String domain) =>
      'https://www.google.com/s2/favicons?domain=$domain&sz=128';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domain = merchantDomain(merchant);
    // «Yape a Juan Pérez»: el nombre ya es la billetera, y su ícono va dentro de la app.
    final named = _walletByDomain[domain];
    if (named != null) return _wallet(named);
    final byCategory = _genericCategories.contains(category) && walletAsset(source) != null;
    final fallback = byCategory
        ? _wallet(source!)
        : CategoryIcon(category: category, size: size, radius: radius, iconSize: iconSize);
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

class _WalletIcon extends StatelessWidget {
  const _WalletIcon({
    required this.asset,
    required this.label,
    required this.size,
    required this.radius,
    required this.padded,
  });

  final String asset;
  final String label;
  final double size;
  final double radius;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(asset, fit: padded ? BoxFit.contain : BoxFit.cover,
        filterQuality: FilterQuality.medium, semanticLabel: label);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: padded ? Colors.white : null,
        padding: padded ? EdgeInsets.all(size * 0.1) : null,
        child: image,
      ),
    );
  }
}
