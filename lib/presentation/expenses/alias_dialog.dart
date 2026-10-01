import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/aliases.dart';
import '../providers.dart';

/// Pide el nombre con el que el usuario quiere ver a [merchant] y lo guarda.
/// Se aplica a todos los movimientos de ese nombre, y con uno vacío se quita.
Future<void> showAliasDialog(BuildContext context, WidgetRef ref, String merchant) async {
  final current = ref.read(aliasesProvider)[aliasKey(merchant)];
  final result = await showDialog<String>(
    context: context,
    builder: (_) => _AliasDialog(merchant: merchant, current: current),
  );
  if (result == null) return;
  await ref.read(aliasesProvider.notifier).set(merchant, result);
}

class _AliasDialog extends StatefulWidget {
  const _AliasDialog({required this.merchant, required this.current});

  final String merchant;
  final String? current;

  @override
  State<_AliasDialog> createState() => _AliasDialogState();
}

class _AliasDialogState extends State<_AliasDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.current ?? _suggestion(widget.merchant));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Propuesta inicial: las dos primeras palabras, con solo la primera letra en mayúscula.
  static String _suggestion(String name) {
    final words = name.trim().split(RegExp(r'\s+')).take(2);
    return words
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Cambiar nombre'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Así verás a "${widget.merchant}" en toda la app. Es solo cómo se ve: el pago no cambia.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nombre'),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
        ],
      ),
      actions: [
        if (widget.current != null)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Quitar nombre'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
