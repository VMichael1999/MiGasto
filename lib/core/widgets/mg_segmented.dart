import 'package:flutter/material.dart';
import '../theme/mg_colors.dart';
import '../theme/app_tokens.dart';

/// Control segmentado con fondo `soft`, radio 16 y pestaña activa resaltada.
class MgSegmented<T> extends StatelessWidget {
  const MgSegmented({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> items;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MgColors.soft,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: MgColors.line, width: 1),
      ),
      child: Row(
        children: [
          for (final entry in items.entries) ...[
            Expanded(
              child: _buildSegment(entry.key, entry.value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegment(T key, String label) {
    final isSelected = key == selected;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? MgColors.card2 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? MgColors.ink : MgColors.ink2,
          ),
        ),
      ),
    );
  }
}

/// Interruptor con estética oscura y acento violeta MiGasto.
class MgToggle extends StatelessWidget {
  const MgToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.subtitle,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final switchWidget = GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? MgColors.acc : MgColors.soft,
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: const Cubic(0.3, 1.3, 0.5, 1.0),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (label == null) {
      return switchWidget;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: MgColors.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: MgColors.ink2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            switchWidget,
          ],
        ),
      ),
    );
  }
}
