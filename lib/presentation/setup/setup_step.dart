import 'package:flutter/material.dart';

import '../../shared/widgets/app_icons.dart';

/// Un paso numerado de una guía de Atajos. Cuando ya se cumplió, muestra un
/// visto y «Listo» en lugar de la explicación.
class SetupStep extends StatelessWidget {
  const SetupStep({
    super.key,
    required this.number,
    required this.title,
    required this.hint,
    required this.done,
  });

  final int number;
  final String title;
  final String hint;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: 'Paso $number: $title. ${done ? 'Listo' : hint}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done ? scheme.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: done ? scheme.primary : scheme.outline, width: 1.5),
            ),
            alignment: Alignment.center,
            child: done
                ? AppIcon(AppIcons.check, size: AppIconSize.small, color: scheme.onPrimary)
                : Text('$number',
                    style: theme.textTheme.bodyMedium!
                        .copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall!.copyWith(fontSize: 14)),
                Text(done ? 'Listo' : hint,
                    style: theme.textTheme.bodySmall!.copyWith(fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
