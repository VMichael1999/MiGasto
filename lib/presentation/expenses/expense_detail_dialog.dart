import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers.dart';
import '../../core/theme/theme.dart';
import '../../domain/entities/movimiento.dart';

/// Shows a premium bottom sheet to view/edit an existing expense.
void showExpenseDetailSheet(BuildContext context, WidgetRef ref, Movimiento expense) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _ExpenseDetailSheet(expense: expense);
    },
  );
}

class _ExpenseDetailSheet extends ConsumerStatefulWidget {
  final Movimiento expense;
  const _ExpenseDetailSheet({required this.expense});

  @override
  ConsumerState<_ExpenseDetailSheet> createState() => _ExpenseDetailSheetState();
}

class _ExpenseDetailSheetState extends ConsumerState<_ExpenseDetailSheet> {
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  late TextEditingController _notesController;
  late Categoria _selectedCategory;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.expense.amount.toStringAsFixed(2));
    _merchantController = TextEditingController(text: widget.expense.merchant);
    _notesController = TextEditingController(text: widget.expense.notes);
    _selectedCategory = widget.expense.category;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _getSourceLabel(PaymentSource source) {
    switch (source) {
      case PaymentSource.yape: return 'Yape';
      case PaymentSource.plin: return 'Plin';
      case PaymentSource.googlePay: return 'Google Wallet';
      case PaymentSource.tarjeta: return 'Tarjeta';
      case PaymentSource.efectivo: return 'Efectivo';
      case PaymentSource.manual:
      case PaymentSource.otro: return 'Manual';
    }
  }

  Color _getSourceColor(PaymentSource source) {
    switch (source) {
      case PaymentSource.yape: return AppTheme.yapePurple;
      case PaymentSource.plin: return AppTheme.plinTeal;
      case PaymentSource.googlePay: return AppTheme.googlePayBlue;
      case PaymentSource.tarjeta: return const Color(0xFFE8B04A);
      case PaymentSource.efectivo:
      case PaymentSource.manual:
      case PaymentSource.otro: return AppTheme.manualGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exp = widget.expense;
    final dateStr = DateFormat("EEEE d 'de' MMMM, h:mm a", 'es').format(exp.date);
    final sourceColor = _getSourceColor(exp.source);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1826),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header row
              Row(
                children: [
                  // Source badge
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: sourceColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _getSourceLabel(exp.source)[0],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getSourceLabel(exp.source),
                          style: TextStyle(color: sourceColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Edit / View toggle
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.visibility_outlined : Icons.edit_outlined,
                      color: AppTheme.neonGreen,
                    ),
                    onPressed: () {
                      setState(() { _isEditing = !_isEditing; });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount
              if (_isEditing) ...[
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto (S/)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixText: 'S/ ',
                    prefixStyle: const TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2E2B3B)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTheme.neonGreen),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ] else ...[
                Center(
                  child: Text(
                    'S/ ${exp.amount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Merchant
              if (_isEditing) ...[
                TextField(
                  controller: _merchantController,
                  decoration: InputDecoration(
                    labelText: 'Establecimiento',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2E2B3B)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTheme.neonGreen),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                // Category selector
                DropdownButtonFormField<Categoria>(
                  initialValue: _selectedCategory,
                  dropdownColor: AppTheme.cardBg,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2E2B3B)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTheme.neonGreen),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: Categoria.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(
                        AppTheme.getCategoryNameEs(cat),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (cat) {
                    if (cat != null) {
                      setState(() { _selectedCategory = cat; });
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Notes
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notas',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF2E2B3B)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTheme.neonGreen),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ] else ...[
                // Read-only detail rows
                _buildDetailRow('Establecimiento', exp.merchant),
                _buildDetailRow('Categoría', '${AppTheme.getCategoryEmoji(exp.category)} ${AppTheme.getCategoryNameEs(exp.category)}'),
                if (exp.notes.isNotEmpty)
                  _buildDetailRow('Notas', exp.notes),
              ],
              const SizedBox(height: 24),

              // Action buttons
              if (_isEditing) ...[
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Eliminar gasto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    final newAmount = double.tryParse(_amountController.text) ?? widget.expense.amount;
    final newMerchant = _merchantController.text.trim();
    final newNotes = _notesController.text.trim();

    if (newAmount <= 0 || newMerchant.isEmpty) return;

    final updated = widget.expense.copyWith(
      amount: newAmount,
      merchant: newMerchant,
      category: _selectedCategory,
      notes: newNotes,
    );

    ref.read(expensesStateProvider.notifier).updateExpense(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gasto actualizado')),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Eliminar gasto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '¿Eliminar "${widget.expense.merchant}" por S/ ${widget.expense.amount.toStringAsFixed(2)}?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(expensesStateProvider.notifier).deleteExpense(widget.expense.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gasto "${widget.expense.merchant}" eliminado')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
