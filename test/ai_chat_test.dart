import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/presentation/ai/ai_chat_provider.dart';
import 'package:mi_gasto/presentation/ai/ai_screen.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('la conversación se guarda y se recupera al abrir de nuevo', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = AiChatNotifier(prefs);
    first.add(ChatMessage(text: '¿En qué gasté más?', isUser: true));
    final i = first.add(ChatMessage(text: 'En', isUser: false));
    first.replaceAt(i, ChatMessage(text: 'En comida', isUser: false));

    final second = AiChatNotifier(prefs);
    expect(second.state.messages.map((m) => m.text), ['¿En qué gasté más?', 'En comida']);
    expect(second.state.messages.map((m) => m.isUser), [true, false]);

    second.clear();
    expect(AiChatNotifier(prefs).state.messages, isEmpty);
  });

  test('solo se conservan los últimos 100 mensajes', () async {
    SharedPreferences.setMockInitialValues({});
    final n = AiChatNotifier(await SharedPreferences.getInstance());
    for (var i = 0; i < 130; i++) {
      n.add(ChatMessage(text: 'm$i', isUser: true));
    }
    expect(n.state.messages.length, 100);
    expect(n.state.messages.first.text, 'm30');
  });

  testWidgets('al salir de la pestaña y volver, la conversación sigue ahí', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    container.read(aiChatProvider.notifier).add(ChatMessage(text: 'Pregunta guardada', isUser: true));

    Future<void> open() async {
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.darkTheme, home: const AiScreen()),
      ));
      await tester.pump(const Duration(milliseconds: 500));
    }

    await open();
    expect(find.text('Pregunta guardada', findRichText: true), findsOneWidget);
    // Se cambia de pantalla (la de la IA se destruye) y se vuelve.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
    await open();
    expect(find.text('Pregunta guardada', findRichText: true), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  });
}
