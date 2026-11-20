import 'package:flutter/material.dart';

import '../theme/mg_colors.dart';

class BucketBarItem {
  const BucketBarItem({required this.label, required this.value});

  final String label;
  final double value;
}

/// Barras simples de la evolución de un período (una por tramo), sin ejes: la
/// más alta lleva su monto encima. Un tramo en cero queda como una marca fina.
class BucketBars extends StatelessWidget {
  const BucketBars({
    super.key,
    required this.items,
    required this.color,
    this.height = 110,
    this.valueLabel,
  });

  final List<BucketBarItem> items;
  final Color color;
  final double height;

  /// Cómo se escribe el monto de la barra más alta (p. ej. ocultarlo en modo privado).
  final String Function(double value)? valueLabel;

  @override
  Widget build(BuildContext context) {
    final maxV = items.fold<double>(0, (s, e) => e.value > s ? e.value : s);
    const labelH = 18.0;
    const valueH = 16.0;
    final barArea = height - labelH - valueH;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final item in items)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: valueH,
                    child: item.value > 0 && item.value == maxV
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              valueLabel?.call(item.value) ?? item.value.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 10, color: MgColors.ink2),
                            ),
                          )
                        : null,
                  ),
                  Container(
                    width: 14,
                    height: maxV > 0 && item.value > 0
                        ? (item.value / maxV * barArea).clamp(3.0, barArea)
                        : 3,
                    decoration: BoxDecoration(
                      color: item.value > 0 ? color : MgColors.line,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  SizedBox(
                    height: labelH,
                    child: Center(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(fontSize: 10, color: MgColors.ink3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
