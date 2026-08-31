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

  testWidgets('navega pelas rotas pós-login sem erro de Provider ausente', (
    tester,
  ) async {
    // GEOPRAG-91/94: regressão de QA — essas rotas renderizavam a tela sem
    // envolvê-la num BlocProvider, e cada tela faz BlocBuilder<XCubit, ...>
    // por dentro. Reproduzia "Could not find the correct Provider<XCubit>"
    // assim que o usuário navegava até elas. `_router`/`_tenantCubit` em
    // main.dart são singletons top-level (compartilhados entre testes),
    // então as 4 rotas são visitadas numa única árvore/teste em vez de um
    // `pumpWidget` por rota.
    await tester.pumpWidget(const AppAplicador());
    await tester.pump(const Duration(milliseconds: 600));

    final context = tester.element(find.text('Entrar'));
    for (final rota in ['/ponto', '/inventario', '/recebimentos', '/denuncias']) {
      GoRouter.of(context).go(rota);
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull, reason: 'rota $rota');
    }
  });
}
