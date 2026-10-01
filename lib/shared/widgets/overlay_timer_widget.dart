import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/movimiento.dart';
import '../../presentation/providers.dart';
import '../../core/theme/theme.dart';

class OverlayTimerWidget extends ConsumerStatefulWidget {
  final Widget child;

  const OverlayTimerWidget({super.key, required this.child});

  @override
  ConsumerState<OverlayTimerWidget> createState() => _OverlayTimerWidgetState();
}

class _OverlayTimerWidgetState extends ConsumerState<OverlayTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  Timer? _countdownTimer;
  double _progress = 1.0;
  bool _isTimerRunning = false;
  Categoria? _selectedCategory;
  final _notesController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _slideAnimation = Tween<double>(begin: 1.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.elasticOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutBack,
      ),
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _stopTimer();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _countdownTimer?.cancel();
    _notesController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer(Movimiento pending) {
    if (_isTimerRunning) return;

    // Un ingreso nunca se guarda solo: espera la confirmación del usuario.
    if (pending.esIngreso) {
      setState(() {
        _progress = 0.0;
        _selectedCategory = pending.category;
        _notesController.clear();
      });
      return;
    }

    setState(() {
      _progress = 1.0;
      _isTimerRunning = true;
      _selectedCategory = pending.category;
      _notesController.clear();
    });

    _countdownTimer?.cancel();
    const duration = Duration(milliseconds: 100);
    int ticks = 0;
    const maxTicks = 50; // 5 seconds total (50 * 100ms)

    _countdownTimer = Timer.periodic(duration, (timer) {
      ticks++;
      if (mounted) {
        setState(() {
          _progress = (maxTicks - ticks) / maxTicks;
        });
      }

      if (ticks >= maxTicks) {
        timer.cancel();
        _autoConfirm(pending);
      }
    });
  }

  void _stopTimer() {
    if (_isTimerRunning) {
      _countdownTimer?.cancel();
      if (mounted) {
        setState(() {
          _isTimerRunning = false;
          _progress = 0.0;
        });
      }
    }
  }

  void _autoConfirm(Movimiento pending) {
    if (!_isTimerRunning) return;
    _isTimerRunning = false;
    
    // Auto confirm with default predicted category
    final category = _selectedCategory ?? pending.category;
    ref.read(expensesStateProvider.notifier).confirmPendingExpense(
          category,
          _notesController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingExpenseProvider);

    // Compute formatted date/time for pending expense
    String formattedSourceTime = '';
    if (pending != null) {
      final now = DateTime.now();
      final pendingDate = pending.date;
      final isToday = now.year == pendingDate.year &&
          now.month == pendingDate.month &&
          now.day == pendingDate.day;
      final yesterday = now.subtract(const Duration(days: 1));
      final isYesterday = yesterday.year == pendingDate.year &&
          yesterday.month == pendingDate.month &&
          yesterday.day == pendingDate.day;
      final dayText = isToday
          ? 'Hoy'
          : isYesterday
              ? 'Ayer'
              : DateFormat('dd/MM').format(pendingDate);
      final timeStr = DateFormat('h:mm a').format(pendingDate);
      formattedSourceTime =
          '${pending.source.name.toUpperCase()} \u2022 $dayText, $timeStr';
    }

    if (pending != null) {
      if (!_slideController.isCompleted && !_slideController.isAnimating) {
        _slideController.forward();
        _startTimer(pending);
      }
    } else {
      if (_slideController.isCompleted && !_slideController.isAnimating) {
        _slideController.reverse();
        _countdownTimer?.cancel();
        _isTimerRunning = false;
      }
    }

    return Stack(
      children: [
        widget.child,
        if (pending != null) ...[
          // Dimmed backdrop with blur
          AnimatedBuilder(
            animation: _slideController,
            builder: (context, child) {
              return Opacity(
                opacity: _slideController.value * 0.45,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _slideController.value * 6,
                    sigmaY: _slideController.value * 6,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              );
            },
          ),
          
          // Sliding Overlay bottom sheet card matching Mockup Screen 3
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: _slideController,
                builder: (context, child) {
                  final slideY = MediaQuery.of(context).size.height * _slideAnimation.value;
                  return Transform.translate(
                    offset: Offset(0, slideY),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: GestureDetector(
                        onTap: _stopTimer, // Tapping card stops auto countdown
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Material(
                            elevation: 16,
                            borderRadius: BorderRadius.circular(28),
                            color: AppTheme.cardBg,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(0xFF2E2B3B),
                                  width: 1.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Timer Countdown Progress Bar
                                    if (_isTimerRunning)
                                      LinearProgressIndicator(
                                        value: _progress,
                                        minHeight: 4,
                                        backgroundColor: Colors.transparent,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                                      ),
                                    
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Top row: Title and close
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const SizedBox(width: 32),
                                              Text(
                                                'Gasto detectado',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close, color: Colors.grey),
                                                onPressed: () {
                                                  _countdownTimer?.cancel();
                                                  ref.read(expensesStateProvider.notifier).discardPendingExpense();
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          
                                          // Large monetary amount
                                          Center(
                                            child: Text(
                                              'S/ ${pending.amount.toStringAsFixed(2)}',
                                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: -1.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          
                                          // Source badge and time details
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              _buildProviderBadge(pending.source),
                                              const SizedBox(width: 8),
                                              Text(
                                                formattedSourceTime,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[400],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          
                                          // Detalle detectado Card
                                          Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF131219),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Detalle detectado',
                                                        style: TextStyle(
                                                          color: Colors.grey[500],
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Has realizado un pago de S/ ${pending.amount.toStringAsFixed(2)} a ${pending.merchant}',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          
                                          // Suggested Category dropdown trigger
                                          Text(
                                            'Categoría sugerida',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          _buildCategoryDropdownButton(context),
                                          const SizedBox(height: 16),
                                          
                                          // Notes field
                                          Text(
                                            'Notas (opcional)',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          TextField(
                                            controller: _notesController,
                                            focusNode: _focusNode,
                                            decoration: InputDecoration(
                                              hintText: 'Agregar nota...',
                                              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: Color(0xFF2E2B3B)),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: Colors.greenAccent),
                                              ),
                                              fillColor: const Color(0xFF131219),
                                              filled: true,
                                            ),
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                          ),
                                          const SizedBox(height: 20),
                                          
                                          // Action Buttons
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextButton(
                                                  onPressed: () {
                                                    _stopTimer();
                                                    _focusNode.requestFocus();
                                                  },
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    backgroundColor: const Color(0xFF131219),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Editar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    _stopTimer();
                                                    ref.read(expensesStateProvider.notifier).confirmPendingExpense(
                                                          _selectedCategory ?? pending.category,
                                                          _notesController.text.trim(),
                                                        );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF8CE885),
                                                    foregroundColor: Colors.black,
                                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    elevation: 0,
                                                  ),
                                                  child: Text(
                                                    _isTimerRunning ? 'Confirmar' : 'Guardar',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          
                                          // Safety footer note
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.security, color: Colors.greenAccent, size: 14),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Tus datos están seguros. No almacenamos información de tus cuentas.',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        ]
      ],
    );
  }

  Widget _buildCategoryDropdownButton(BuildContext context) {
    final category = _selectedCategory ?? Categoria.otros;
    final catColor = AppTheme.getCategoryColor(category);

    return InkWell(
      onTap: () {
        _stopTimer();
        _showCategorySelectorSheet(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: catColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: catColor.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Text(
              AppTheme.getCategoryEmoji(category),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppTheme.getCategoryNameEs(category),
                style: TextStyle(
                  color: catColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: catColor),
          ],
        ),
      ),
    );
  }

  void _showCategorySelectorSheet(BuildContext context) {
    final pending = ref.read(pendingExpenseProvider);
    final categorias = Categoria.paraTipo(pending?.tipo ?? TipoMovimiento.gasto);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Seleccionar Categoría',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.8,
                    ),
                    itemCount: categorias.length,
                    itemBuilder: (context, index) {
                      final cat = categorias[index];
                      final catColor = AppTheme.getCategoryColor(cat);
                      final isSelected = _selectedCategory == cat;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? catColor.withOpacity(0.2)
                                : const Color(0xFF131219),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? catColor : const Color(0xFF2E2B3B),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(AppTheme.getCategoryEmoji(cat)),
                              const SizedBox(width: 8),
                              Text(
                                AppTheme.getCategoryNameEs(cat),
                                style: TextStyle(
                                  color: isSelected ? catColor : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProviderBadge(PaymentSource source) {
    Color bg;
    String name;
    switch (source) {
      case PaymentSource.yape:
        bg = AppTheme.yapePurple;
        name = 'Y';
        break;
      case PaymentSource.plin:
        bg = AppTheme.plinTeal;
        name = 'P';
        break;
      case PaymentSource.googlePay:
        bg = AppTheme.googlePayBlue;
        name = 'G';
        break;
      default:
        bg = AppTheme.manualGray;
        name = 'M';
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
