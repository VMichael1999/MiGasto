import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/mg_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/services/gemini_ai_service.dart';
import '../providers.dart';
import '../plan/plan_providers.dart';
import '../../shared/widgets/profile_avatar_button.dart';
import 'ai_chat_provider.dart';
import 'widgets/migasto_avatar.dart';
import '../../core/layout/adaptive.dart';
import '../../core/layout/landscape_pane.dart';

/// Pantalla 6: MiGastoIA (#s-ai / R.ai en migasto-prototipo.html)
/// - Cabecera (.nav): Squircle con destello, título «MiGastoIA» y botón papelera (.rnd) con ConfirmSheet.
/// - Chat (.chat): Burbujas del usuario en violeta (#7C5CFF) a la derecha; respuestas de IA a la izquierda en tarjeta oscura (#15151B) con cifras destacadas en violeta claro (#9B82FF).
/// - Sugerencias (.sug): Scroll horizontal de preguntas frecuentes.
/// - Entrada (.ai-in): Campo con destello, placeholder «Pregúntale a MiGastoIA» y botón circular de enviar.
class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> with WidgetsBindingObserver {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _remainingQueries = GeminiAiService.dailyLimit;

  bool get _isTyping => ref.read(aiChatProvider).typing;

  /// El saludo no se guarda: se muestra siempre al comienzo de la conversación.
  late final ChatMessage _greetingMessage = ChatMessage(text: _greeting(), isUser: false);

  List<ChatMessage> get _messages => [_greetingMessage, ...ref.read(aiChatProvider).messages];

  String _greeting() {
    final name = ref.read(profileNameProvider).trim().split(' ').first;
    return '${name.isEmpty ? 'Hola' : 'Hola $name'}. Soy MiGastoIA, tu asistente financiero. Puedo ayudarte con tus gastos, ingresos, presupuestos y límites de este mes.';
  }

  static const List<String> _suggestions = [
    '¿En qué gasté más este mes?',
    '¿Cuánto me queda de presupuesto?',
    '¿Cómo va mi meta de ahorro?',
    'Dame un resumen de mis finanzas',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prefs = ref.read(sharedPreferencesProvider);
      setState(() {
        _remainingQueries = GeminiAiService.getRemainingQueries(prefs);
      });
      _scrollToBottom(animated: false);
    });
  }

  double _lastInset = 0;

  /// Al abrirse el teclado, la conversación baja hasta el último mensaje para que no quede cortado.
  @override
  void didChangeMetrics() {
    final inset = View.of(context).viewInsets.bottom;
    if (inset > _lastInset) {
      _scrollToBottom(animated: false);
      Future.delayed(const Duration(milliseconds: 320), () {
        if (mounted) _scrollToBottom();
      });
    }
    _lastInset = inset;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(max);
      }
    });
  }

  Future<void> _sendMessage(String query) async {
    final clean = query.trim();
    if (clean.isEmpty || _isTyping) return;

    final prefs = ref.read(sharedPreferencesProvider);
    // La conversación vive en el provider: si el usuario cambia de pestaña mientras
    // la IA responde, la respuesta se sigue guardando.
    final chat = ref.read(aiChatProvider.notifier);
    final remaining = GeminiAiService.getRemainingQueries(prefs);

    if (remaining <= 0) {
      chat.add(ChatMessage(text: clean, isUser: true));
      _inputController.clear();
      chat.add(ChatMessage(
        text: 'Has alcanzado tu límite diario de 10 consultas financieras con MiGastoIA. Tu cuota se renovará automáticamente mañana a medianoche.',
        isUser: false,
      ));
      _scrollToBottom();
      return;
    }

    chat.add(ChatMessage(text: clean, isUser: true));
    _inputController.clear();
    chat.setTyping(true);
    _scrollToBottom();

    try {
      final expenses = ref.read(expensesStateProvider);
      final budget = ref.read(budgetProvider);
      final limits = ref.read(categoryLimitsProvider);
      final goal = ref.read(savingsGoalProvider);

      final financialContext = GeminiAiService.buildFinancialContext(
        movements: expenses,
        budget: budget,
        categoryLimits: limits,
        savingsCurrent: goal?.current,
        savingsTarget: goal?.target,
      );

      // Streaming: el mensaje de la IA aparece al primer fragmento y crece.
      var index = -1; // posición del mensaje de la IA en la lista
      try {
        await for (final text in GeminiAiService.streamGemini(
          userQuery: clean,
          financialContext: financialContext,
          prefs: prefs,
        )) {
          if (index == -1) {
            chat.setTyping(false);
            index = chat.add(ChatMessage(text: text, isUser: false));
          } else {
            chat.replaceAt(index, ChatMessage(text: text, isUser: false));
          }
          if (mounted) _scrollToBottom(animated: false);
        }
      } on GeminiException catch (e) {
        chat.setTyping(false);
        // Si ya se mostró parte de la respuesta, se conserva.
        if (index == -1) chat.add(ChatMessage(text: e.message, isUser: false));
      }

      chat.setTyping(false);
      if (mounted) {
        setState(() => _remainingQueries = GeminiAiService.getRemainingQueries(prefs));
        _scrollToBottom();
      }
    } catch (e) {
      chat.setTyping(false);
      chat.add(ChatMessage(
        text: 'Ocurrió un inconveniente al consultar a MiGastoIA. Por favor intenta nuevamente.',
        isUser: false,
      ));
      if (mounted) _scrollToBottom();
    }
  }

  Future<void> _clearChat() async {
    final ok = await ConfirmSheet.show(
      context,
      title: '¿Borrar conversación?',
      message: 'Se limpiará el historial de mensajes con MiGastoIA.',
      confirmLabel: 'Borrar',
      isDestructive: true,
      icon: Icons.delete_outline,
    );
    if (ok && mounted) {
      ref.read(aiChatProvider.notifier).clear();
      MgToast.show(context, message: 'Conversación borrada.');
    }
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      // Se puede desplazar la conversación con el teclado abierto: el teclado se baja
      // tocando un espacio vacío o con el botón de ocultar.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Se reconstruye cada vez que cambia la conversación o el estado «escribiendo».
    ref.watch(aiChatProvider);
    final landscape = context.isLandscapePhone;
    return Scaffold(
      backgroundColor: MgColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Cabecera (.nav)
            _buildNav(context),
            if (landscape)
              // Horizontal: preguntas sugeridas a la izquierda; chat y entrada a la derecha.
              Expanded(
                child: Row(
                  children: [
                    SizedBox(width: 270, child: BleedClip(child: _buildSuggestionsColumn())),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: BleedClip(child: _buildMessages())),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                                12, 0, 18, _bottomGap(context)),
                            child: _buildInput(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Expanded(child: _buildMessages()),
              // 3. Dock inferior de sugerencias y campo de entrada (arriba del tab bar)
              _buildDock(context),
            ],
          ],
        ),
      ),
    );
  }

  // 1. Cabecera (.nav)
  Widget _buildNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: [
          // Avatar oficial de MiGastoIA (con estado thinking sincronizado)
          MigastoAvatar(
            size: 36,
            state: _isTyping ? MigastoAvatarState.thinking : MigastoAvatarState.idle,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'MiGastoIA',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: MgColors.ink,
              ),
            ),
          ),
          // Indicador de cuota diaria (10 / día)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _remainingQueries > 0
                  ? const Color(0x227C5CFF)
                  : const Color(0x22FF5C6E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _remainingQueries > 0
                    ? const Color(0x557C5CFF)
                    : const Color(0x55FF5C6E),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 13,
                  color: _remainingQueries > 0 ? MgColors.acc2 : MgColors.down,
                ),
                const SizedBox(width: 3),
                Text(
                  '$_remainingQueries/10 hoy',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _remainingQueries > 0 ? MgColors.acc2 : MgColors.down,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Botón limpiar conversación (.rnd)
          Material(
            color: MgColors.soft,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _clearChat,
              child: const SizedBox(
                width: 34,
                height: 34,
                child: Center(
                  child: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: MgColors.ink2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const ProfileAvatarButton(size: 34),
        ],
      ),
    );
  }

  // 2. Burbuja de mensaje (.msg / .msg.me)
  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isUser;

    if (isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: MgColors.acc,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: MgColors.acc.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildFormattedText(msg.text, true),
        ),
      );
    }

    // Mensaje de la IA con mini avatar acompañante
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: MigastoAvatar(
                size: 28,
                state: MigastoAvatarState.idle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: MgColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: MgColors.line),
                ),
                child: _buildFormattedText(msg.text, false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Indicador de procesamiento: avatar pensando en vivo sin texto "Pensando"
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar de MiGastoIA en estado reflexivo (inclinación de cabeza + mirada hacia arriba)
            const MigastoAvatar(
              size: 38,
              state: MigastoAvatarState.thinking,
            ),
            const SizedBox(width: 10),
            // Burbuja con ondas dinámicas de pensamiento en neón (sin texto rígido)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: MgColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: MgColors.line),
                boxShadow: [
                  BoxShadow(
                    color: MgColors.acc.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const ThinkingWaveDots(),
            ),
          ],
        ),
      ),
    );
  }

  // Interpreta negritas (**texto**) con color violeta claro en respuestas de IA
  Widget _buildFormattedText(String text, bool isMe) {
    final spans = <TextSpan>[];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isMe
                ? Colors.white
                : (isBold ? MgColors.acc2 : MgColors.ink),
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  /// Espacio bajo la caja de texto: el de la barra de navegación, o poco si el teclado está abierto.
  double _bottomGap(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom > 80 ? 12 : context.tabBarClearance(92, landscape: 70);

  // 3. Dock inferior de sugerencias y campo (.ai-dock)
  Widget _buildDock(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18, 0, 18, _bottomGap(context)), // Espacio para MgTabBar (oculta con el teclado)
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSuggestionsRow(),
          const SizedBox(height: 10),
          _buildInput(),
        ],
      ),
    );
  }

  // Sugerencias horizontales (.sug)
  Widget _buildSuggestionsRow() {
    return SizedBox(
    height: 34,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: _suggestions.length,
      separatorBuilder: (_, _) => const SizedBox(width: 7),
      itemBuilder: (context, index) {
        final s = _suggestions[index];
        return Material(
          color: MgColors.bg,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => _sendMessage(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: MgColors.line),
              ),
              alignment: Alignment.center,
              child: Text(
                s,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: MgColors.ink2,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
  }

  // Sugerencias en lista vertical (panel izquierdo en horizontal)
  Widget _buildSuggestionsColumn() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 4, 12, 70),
      itemCount: _suggestions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final s = _suggestions[index];
        return Material(
          color: MgColors.card,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _isTyping ? null : () => _sendMessage(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MgColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 14, color: MgColors.acc2),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: MgColors.ink2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Campo de texto con botón enviar (.ai-in)
  Widget _buildInput() {
    return Container(
    height: 50,
    padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
    decoration: BoxDecoration(
      color: MgColors.soft,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: MgColors.line),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.auto_awesome_rounded,
          size: 17,
          color: MgColors.acc2,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: TextField(
            controller: _inputController,
            // Al entrar a MiGastoIA el cursor ya está listo para escribir.
            autofocus: true,
            cursorColor: MgColors.acc,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: MgColors.ink,
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: _sendMessage,
            decoration: const InputDecoration(
              hintText: 'Pregúntale a MiGastoIA',
              hintStyle: TextStyle(
                fontSize: 13.5,
                color: MgColors.ink3,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        // Botón circular de enviar (.rnd.on)
        Material(
          color: _isTyping ? MgColors.line : MgColors.acc,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _isTyping ? null : () => _sendMessage(_inputController.text),
            child: SizedBox(
              width: 38,
              height: 38,
              child: Center(
                child: _isTyping
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  }
}
