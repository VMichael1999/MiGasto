import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/presentation/ai/ai_chat_provider.dart';
import 'package:mi_gasto/presentation/ai/ai_screen.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  testWidgets('al abrirse el teclado la conversación baja al último mensaje', (tester) async {
    tester.view.physicalSize = const Size(420, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.view.resetViewInsets);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    final chat = container.read(aiChatProvider.notifier);
    for (var i = 0; i < 30; i++) {
      chat.add(ChatMessage(text: 'Mensaje número $i con bastante texto para ocupar varias líneas en pantalla', isUser: i.isEven));
    }
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.darkTheme, home: const AiScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 600));

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
    // Se sube al principio de la conversación y luego se abre el teclado.
    scrollable.position.jumpTo(0);
    await tester.pump();
    expect(scrollable.position.pixels, 0);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump(const Duration(milliseconds: 700));
    expect(scrollable.position.pixels, scrollable.position.maxScrollExtent);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  });
}
