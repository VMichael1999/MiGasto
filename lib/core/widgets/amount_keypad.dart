import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/mg_colors.dart';
import '../theme/app_tokens.dart';

/// Teclado numérico de 12 teclas ('1'-'9', '.', '0', '<') con respuesta háptica,
/// fondo suave #1F1F27 por tecla, radio 13 y altura 48px (idéntico al prototipo HTML).
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.onKeyPress,
    required this.onDelete,
    this.decimalSeparator = '.',
  });

  final ValueChanged<String> onKeyPress;
  final VoidCallback onDelete;
  final String decimalSeparator;

  List<String> get _keys => [
        '1', '2', '3',
        '4', '5', '6',
        '7', '8', '9',
        decimalSeparator, '0', '<',
      ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _keys.length,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 2.2, // ~48px de alto para ~110px de ancho
      ),
      itemBuilder: (context, index) {
        final key = _keys[index];
        final isDelete = key == '<';

        return Material(
          color: MgColors.soft,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            splashColor: MgColors.card2,
            highlightColor: MgColors.card2.withValues(alpha: 0.6),
            onTap: () {
              HapticFeedback.lightImpact();
              if (isDelete) {
                onDelete();
              } else {
                onKeyPress(key);
              }
            },
            child: Center(
              child: isDelete
                  ? const Icon(
                      Icons.backspace_outlined,
                      size: 22,
                      color: MgColors.ink,
                    )
                  : Text(
                      key,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: MgColors.ink,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// Muestra el monto grande con micro-rebote al teclear.
/// Cuando está vacío, muestra '0' en tono fantasma (ghost #6F6F82).
class AmountDisplay extends StatefulWidget {
  const AmountDisplay({
    super.key,
    required this.rawAmount,
    this.currency = 'S/',
    this.color,
    this.fontSize = 44,
    this.align = TextAlign.right,
    this.showCurrency = false,
  });

  final String rawAmount;
  final String currency;
  final Color? color;
  final double fontSize;
  final TextAlign align;
  final bool showCurrency;

  @override
  State<AmountDisplay> createState() => _AmountDisplayState();
}

class _AmountDisplayState extends State<AmountDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    lowerBound: 0.95,
    upperBound: 1.05,
    value: 1.0,
  );

  @override
  void didUpdateWidget(covariant AmountDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawAmount != widget.rawAmount) {
      _bounce.forward(from: 1.05).then((_) {
        if (mounted) _bounce.animateTo(1.0, curve: Curves.easeOut);
      });
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  String get _formatted {
    if (widget.rawAmount.isEmpty) return '0';
    final normalized = widget.rawAmount.replaceAll(',', '.');
    final parts = normalized.split('.');
    final intPart = int.tryParse(parts[0]) ?? 0;
    final formattedInt = NumberFormat('#,##0', 'en').format(intPart);
    if (parts.length > 1) {
      return '$formattedInt.${parts[1]}';
    } else if (widget.rawAmount.contains(',') || widget.rawAmount.contains('.')) {
      return '$formattedInt.';
    }
    return formattedInt;
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.rawAmount.isEmpty || widget.rawAmount == '0';
    final effectiveColor = isEmpty
        ? MgColors.ink3
        : (widget.color ?? MgColors.ink);

    return ScaleTransition(
      scale: _bounce,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: widget.align == TextAlign.right
            ? MainAxisAlignment.end
            : (widget.align == TextAlign.center
                ? MainAxisAlignment.center
                : MainAxisAlignment.start),
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          if (widget.showCurrency) ...[
            Text(
              widget.currency,
              style: TextStyle(
                fontSize: widget.fontSize * 0.44,
                fontWeight: FontWeight.w700,
                color: effectiveColor.withValues(alpha: 0.75),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _formatted,
            textAlign: widget.align,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.8,
              color: effectiveColor,
              fontFeatures: AppText.tabular,
            ),
          ),
        ],
      ),
    );
  }
}
