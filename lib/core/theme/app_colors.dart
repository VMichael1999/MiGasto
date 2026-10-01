import 'package:flutter/material.dart';

/// Colores semánticos del rediseño v0.2 (oscuro y claro).
/// Acceso: `Theme.of(context).extension<AppColors>()!` o `context.appColors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brandInk,
    required this.brandSoft,
    required this.raised,
    required this.budgetOk,
    required this.budgetOkSoft,
    required this.budgetWarning,
    required this.budgetWarningSoft,
    required this.budgetOver,
    required this.budgetOverSoft,
    required this.income,
    required this.incomeSoft,
    required this.pendingReview,
    required this.pendingReviewSoft,
    required this.bar,
    required this.expenseBar,
    required this.yape,
    required this.plin,
    required this.card,
    required this.googlePay,
    required this.manual,
    required this.mapBackground,
    required this.mapBlock,
    required this.mapRoad,
    required this.mapPark,
    required this.mapSea,
    required this.mapLabel,
  });

  /// Verde de marca usado como texto o ícono (en claro es más oscuro).
  final Color brandInk;
  final Color brandSoft;
  final Color raised;

  final Color budgetOk;
  final Color budgetOkSoft;
  final Color budgetWarning;
  final Color budgetWarningSoft;
  final Color budgetOver;
  final Color budgetOverSoft;

  final Color income;
  final Color incomeSoft;
  final Color pendingReview;
  final Color pendingReviewSoft;

  final Color bar;
  final Color expenseBar;

  // Fuentes de pago. Mismos valores en OverlayService.kt.
  final Color yape;
  final Color plin;
  final Color card;
  final Color googlePay;
  final Color manual;

  final Color mapBackground;
  final Color mapBlock;
  final Color mapRoad;
  final Color mapPark;
  final Color mapSea;
  final Color mapLabel;

  static const AppColors dark = AppColors(
    brandInk: Color(0xFF8CE885),
    brandSoft: Color(0xFF1D2A1E),
    raised: Color(0xFF23212B),
    budgetOk: Color(0xFF3FCB5B),
    budgetOkSoft: Color(0xFF16261A),
    budgetWarning: Color(0xFFFAB219),
    budgetWarningSoft: Color(0xFF2E2412),
    budgetOver: Color(0xFFF07070),
    budgetOverSoft: Color(0xFF321A1C),
    income: Color(0xFF7FB6FF),
    incomeSoft: Color(0xFF18233A),
    pendingReview: Color(0xFF7FB6FF),
    pendingReviewSoft: Color(0xFF18233A),
    bar: Color(0xFF4A4656),
    expenseBar: Color(0xFF9A96A6),
    yape: Color(0xFF9B4FD6),
    plin: Color(0xFF10BFAF),
    card: Color(0xFFE8B04A),
    googlePay: Color(0xFF5B9BF8),
    manual: Color(0xFF8A8794),
    mapBackground: Color(0xFF16141D),
    mapBlock: Color(0xFF1F1D28),
    mapRoad: Color(0xFF2E2B38),
    mapPark: Color(0xFF19291D),
    mapSea: Color(0xFF111A23),
    mapLabel: Color(0xFF7C7888),
  );

  static const AppColors light = AppColors(
    brandInk: Color(0xFF1E7A36),
    brandSoft: Color(0xFFE4F6E1),
    raised: Color(0xFFFFFFFF),
    budgetOk: Color(0xFF1C8A34),
    budgetOkSoft: Color(0xFFE4F6E1),
    budgetWarning: Color(0xFF9A6400),
    budgetWarningSoft: Color(0xFFFCEFD2),
    budgetOver: Color(0xFFC23434),
    budgetOverSoft: Color(0xFFFBE4E4),
    income: Color(0xFF2458C6),
    incomeSoft: Color(0xFFE3EBFA),
    pendingReview: Color(0xFF2458C6),
    pendingReviewSoft: Color(0xFFE3EBFA),
    bar: Color(0xFFCFCCD7),
    expenseBar: Color(0xFF8B8896),
    yape: Color(0xFF742284),
    plin: Color(0xFF00857A),
    card: Color(0xFFA56A00),
    googlePay: Color(0xFF1A73E8),
    manual: Color(0xFF6B6876),
    mapBackground: Color(0xFFE9E8EE),
    mapBlock: Color(0xFFDCDAE3),
    mapRoad: Color(0xFFFFFFFF),
    mapPark: Color(0xFFD3E8D2),
    mapSea: Color(0xFFD6E3EC),
    mapLabel: Color(0xFF6B6876),
  );

  /// Color del punto de la fuente de pago (Yape, Plin, tarjeta, Google Pay, manual).
  Color sourceColor(String sourceName) {
    switch (sourceName.toLowerCase()) {
      case 'yape':
        return yape;
      case 'plin':
        return plin;
      case 'card':
      case 'tarjeta':
      case 'applepay':
      case 'apple_pay':
        return card;
      case 'googlepay':
      case 'google_pay':
        return googlePay;
      default:
        return manual;
    }
  }

  @override
  AppColors copyWith({
    Color? brandInk,
    Color? brandSoft,
    Color? raised,
    Color? budgetOk,
    Color? budgetOkSoft,
    Color? budgetWarning,
    Color? budgetWarningSoft,
    Color? budgetOver,
    Color? budgetOverSoft,
    Color? income,
    Color? incomeSoft,
    Color? pendingReview,
    Color? pendingReviewSoft,
    Color? bar,
    Color? expenseBar,
    Color? yape,
    Color? plin,
    Color? card,
    Color? googlePay,
    Color? manual,
    Color? mapBackground,
    Color? mapBlock,
    Color? mapRoad,
    Color? mapPark,
    Color? mapSea,
    Color? mapLabel,
  }) {
    return AppColors(
      brandInk: brandInk ?? this.brandInk,
      brandSoft: brandSoft ?? this.brandSoft,
      raised: raised ?? this.raised,
      budgetOk: budgetOk ?? this.budgetOk,
      budgetOkSoft: budgetOkSoft ?? this.budgetOkSoft,
      budgetWarning: budgetWarning ?? this.budgetWarning,
      budgetWarningSoft: budgetWarningSoft ?? this.budgetWarningSoft,
      budgetOver: budgetOver ?? this.budgetOver,
      budgetOverSoft: budgetOverSoft ?? this.budgetOverSoft,
      income: income ?? this.income,
      incomeSoft: incomeSoft ?? this.incomeSoft,
      pendingReview: pendingReview ?? this.pendingReview,
      pendingReviewSoft: pendingReviewSoft ?? this.pendingReviewSoft,
      bar: bar ?? this.bar,
      expenseBar: expenseBar ?? this.expenseBar,
      yape: yape ?? this.yape,
      plin: plin ?? this.plin,
      card: card ?? this.card,
      googlePay: googlePay ?? this.googlePay,
      manual: manual ?? this.manual,
      mapBackground: mapBackground ?? this.mapBackground,
      mapBlock: mapBlock ?? this.mapBlock,
      mapRoad: mapRoad ?? this.mapRoad,
      mapPark: mapPark ?? this.mapPark,
      mapSea: mapSea ?? this.mapSea,
      mapLabel: mapLabel ?? this.mapLabel,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      brandInk: l(brandInk, other.brandInk),
      brandSoft: l(brandSoft, other.brandSoft),
      raised: l(raised, other.raised),
      budgetOk: l(budgetOk, other.budgetOk),
      budgetOkSoft: l(budgetOkSoft, other.budgetOkSoft),
      budgetWarning: l(budgetWarning, other.budgetWarning),
      budgetWarningSoft: l(budgetWarningSoft, other.budgetWarningSoft),
      budgetOver: l(budgetOver, other.budgetOver),
      budgetOverSoft: l(budgetOverSoft, other.budgetOverSoft),
      income: l(income, other.income),
      incomeSoft: l(incomeSoft, other.incomeSoft),
      pendingReview: l(pendingReview, other.pendingReview),
      pendingReviewSoft: l(pendingReviewSoft, other.pendingReviewSoft),
      bar: l(bar, other.bar),
      expenseBar: l(expenseBar, other.expenseBar),
      yape: l(yape, other.yape),
      plin: l(plin, other.plin),
      card: l(card, other.card),
      googlePay: l(googlePay, other.googlePay),
      manual: l(manual, other.manual),
      mapBackground: l(mapBackground, other.mapBackground),
      mapBlock: l(mapBlock, other.mapBlock),
      mapRoad: l(mapRoad, other.mapRoad),
      mapPark: l(mapPark, other.mapPark),
      mapSea: l(mapSea, other.mapSea),
      mapLabel: l(mapLabel, other.mapLabel),
    );
  }
}

extension AppColorsContext on BuildContext {
  /// Si el tema no incluye la extensión (p. ej. un `ThemeData` de prueba),
  /// usa la paleta que corresponde al brillo.
  AppColors get appColors {
    final theme = Theme.of(this);
    return theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark ? AppColors.dark : AppColors.light);
  }
}
