import 'package:flutter/material.dart';
import 'mg_colors.dart';

export 'mg_colors.dart';

/// Colores semánticos adaptados a los tokens de migasto-flutter-prompt.md.
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

  /// Violeta de marca MiGasto (MgColors.acc)
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

  // Fuentes de pago.
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

  /// Tema oscuro oficial MiGasto
  static const AppColors dark = AppColors(
    brandInk: MgColors.acc,
    brandSoft: MgColors.accSoft,
    raised: MgColors.card2,
    budgetOk: MgColors.up,
    budgetOkSoft: Color(0xFF16291E),
    budgetWarning: MgColors.warn,
    budgetWarningSoft: Color(0xFF2E2412),
    budgetOver: MgColors.down,
    budgetOverSoft: Color(0xFF321A1C),
    income: MgColors.up,
    incomeSoft: Color(0xFF16291E),
    pendingReview: MgColors.acc2,
    pendingReviewSoft: MgColors.accSoft,
    bar: MgColors.line,
    expenseBar: MgColors.down,
    yape: Color(0xFF8B3FD6),
    plin: Color(0xFF00C7B1),
    card: Color(0xFFE8B04A),
    googlePay: Color(0xFF5B9BF8),
    manual: MgColors.ink3,
    mapBackground: MgColors.bg,
    mapBlock: MgColors.card,
    mapRoad: MgColors.soft,
    mapPark: Color(0xFF19291D),
    mapSea: Color(0xFF111A23),
    mapLabel: MgColors.ink2,
  );

  /// Versión clara (mapeada consistentemente con el acento violeta)
  static const AppColors light = AppColors(
    brandInk: MgColors.acc,
    brandSoft: Color(0xFFF1EDFF),
    raised: Color(0xFFFFFFFF),
    budgetOk: Color(0xFF1E9E64),
    budgetOkSoft: Color(0xFFE5F8EE),
    budgetWarning: Color(0xFFD98204),
    budgetWarningSoft: Color(0xFFFFF6E5),
    budgetOver: Color(0xFFE5394E),
    budgetOverSoft: Color(0xFFFFECEF),
    income: Color(0xFF1E9E64),
    incomeSoft: Color(0xFFE5F8EE),
    pendingReview: MgColors.acc,
    pendingReviewSoft: Color(0xFFF1EDFF),
    bar: Color(0xFFE4E3E8),
    expenseBar: Color(0xFFE5394E),
    yape: Color(0xFF742284),
    plin: Color(0xFF00857A),
    card: Color(0xFFA56A00),
    googlePay: Color(0xFF1A73E8),
    manual: Color(0xFF6B6876),
    mapBackground: Color(0xFFF4F3F7),
    mapBlock: Color(0xFFE8E7ED),
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
    return AppColors(
      brandInk: Color.lerp(brandInk, other.brandInk, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      budgetOk: Color.lerp(budgetOk, other.budgetOk, t)!,
      budgetOkSoft: Color.lerp(budgetOkSoft, other.budgetOkSoft, t)!,
      budgetWarning: Color.lerp(budgetWarning, other.budgetWarning, t)!,
      budgetWarningSoft: Color.lerp(budgetWarningSoft, other.budgetWarningSoft, t)!,
      budgetOver: Color.lerp(budgetOver, other.budgetOver, t)!,
      budgetOverSoft: Color.lerp(budgetOverSoft, other.budgetOverSoft, t)!,
      income: Color.lerp(income, other.income, t)!,
      incomeSoft: Color.lerp(incomeSoft, other.incomeSoft, t)!,
      pendingReview: Color.lerp(pendingReview, other.pendingReview, t)!,
      pendingReviewSoft: Color.lerp(pendingReviewSoft, other.pendingReviewSoft, t)!,
      bar: Color.lerp(bar, other.bar, t)!,
      expenseBar: Color.lerp(expenseBar, other.expenseBar, t)!,
      yape: Color.lerp(yape, other.yape, t)!,
      plin: Color.lerp(plin, other.plin, t)!,
      card: Color.lerp(card, other.card, t)!,
      googlePay: Color.lerp(googlePay, other.googlePay, t)!,
      manual: Color.lerp(manual, other.manual, t)!,
      mapBackground: Color.lerp(mapBackground, other.mapBackground, t)!,
      mapBlock: Color.lerp(mapBlock, other.mapBlock, t)!,
      mapRoad: Color.lerp(mapRoad, other.mapRoad, t)!,
      mapPark: Color.lerp(mapPark, other.mapPark, t)!,
      mapSea: Color.lerp(mapSea, other.mapSea, t)!,
      mapLabel: Color.lerp(mapLabel, other.mapLabel, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors {
    final theme = Theme.of(this);
    return theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark ? AppColors.dark : AppColors.light);
  }
}
