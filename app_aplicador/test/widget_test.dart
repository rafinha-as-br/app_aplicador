import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app_aplicador/main.dart';

void main() {
  testWidgets('app sobe sem erro e mostra a landing screen', (tester) async {
    // '/' está em `_publicPaths` — a landing screen renderiza sem depender
    // do TenantCubit, mas o binding do teste roda tudo dentro de uma zona
    // fake-async: os 10 passos de 50ms do download simulado de mbtiles
    // (MbtilesDownloader, TODO GEOPRAG-24) viram FakeTimers presos ao
    // teste. `pumpAndSettle` não os drena sozinho — avança o relógio manual
    // o bastante para esgotá-los antes do teardown.
    await tester.pumpWidget(const AppAplicador());
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets(
    'navega para /recebimento/confirmar sem erro de Provider ausente',
    (tester) async {
      // GEOPRAG-94 (subtask 106): mesma regressão de GEOPRAG-91 — a rota
      // renderizava ReceberProdutoScreen sem envolvê-la num BlocProvider,
      // e a tela faz BlocBuilder<RecebimentoConfirmacaoCubit, ...> por
      // dentro. Reproduzia "Could not find the correct Provider<...>" ao
      // navegar até lá.
      await tester.pumpWidget(const AppAplicador());
      await tester.pump(const Duration(milliseconds: 600));

      final context = tester.element(find.text('Entrar'));
      GoRouter.of(context).go('/recebimento/confirmar');
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    },
  );
}
