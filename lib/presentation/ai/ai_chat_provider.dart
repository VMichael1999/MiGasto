import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        't': text,
        'u': isUser,
        'd': timestamp.toIso8601String(),
      };

  static ChatMessage? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final text = raw['t'];
    if (text is! String) return null;
    return ChatMessage(
      text: text,
      isUser: raw['u'] == true,
      timestamp: DateTime.tryParse('${raw['d']}'),
    );
  }
}

class AiChatState {
  const AiChatState({this.messages = const [], this.typing = false});
  final List<ChatMessage> messages;

  /// La IA está respondiendo (se conserva aunque el usuario cambie de pestaña).
  final bool typing;
}

/// Conversación con MiGastoIA. Vive fuera de la pantalla para que no se pierda
/// al cambiar de pestaña, y se guarda en el teléfono para retomarla después.
class AiChatNotifier extends StateNotifier<AiChatState> {
  AiChatNotifier(this._prefs) : super(AiChatState(messages: _load(_prefs)));

  final SharedPreferences _prefs;
  static const _key = 'migasto_ai_chat';
  static const _maxMessages = 100;

  static List<ChatMessage> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return [for (final m in list) ?ChatMessage.fromJson(m)];
    } catch (_) {
      return const [];
    }
  }

  void _save() {
    _prefs.setString(_key, jsonEncode([for (final m in state.messages) m.toJson()]));
  }

  void _set(List<ChatMessage> messages, {bool? typing}) {
    final trimmed = messages.length > _maxMessages
        ? messages.sublist(messages.length - _maxMessages)
        : messages;
    state = AiChatState(messages: trimmed, typing: typing ?? state.typing);
    _save();
  }

  /// Agrega un mensaje y devuelve su posición.
  int add(ChatMessage message) {
    _set([...state.messages, message]);
    return state.messages.length - 1;
  }

  void replaceAt(int index, ChatMessage message) {
    if (index < 0 || index >= state.messages.length) return;
    final list = [...state.messages];
    list[index] = message;
    _set(list);
  }

  void setTyping(bool value) {
    if (state.typing == value) return;
    state = AiChatState(messages: state.messages, typing: value);
  }

  void clear() {
    state = const AiChatState();
    _prefs.remove(_key);
  }
}

final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>(
  (ref) => AiChatNotifier(ref.read(sharedPreferencesProvider)),
);
