import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app_aplicador/main.dart';

// `_router` é singleton top-level em main.dart, compartilhado entre os
// testes deste arquivo — a rota atual pode não ser mais a landing screen,
// dependendo de qual teste rodou antes. `find.byType(MaterialApp)` fica
// acima do Router e não enxerga o GoRouter; este helper varre a árvore
// inteira em busca de um elemento que já esteja dentro do escopo do Router,
// não importa qual seja a tela renderizada no momento.
BuildContext _routerContext(WidgetTester tester) {
  return tester.allElements.firstWhere((e) => GoRouter.maybeOf(e) != null);
}

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

    final context = _routerContext(tester);
    for (final rota in ['/ponto', '/inventario', '/recebimentos', '/denuncias']) {
      GoRouter.of(context).go(rota);
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull, reason: 'rota $rota');
    }
  });

  testWidgets(
    'navega pelo fluxo de registro de aplicação sem erro de Provider ausente',
    (tester) async {
      // GEOPRAG-126: mesma regressão de GEOPRAG-91/94 — /aplicacao/geo e
      // /aplicacao/registrar renderizavam GeolocalizacaoScreen/
      // TelaDeAplicacaoScreen sem envolvê-las num BlocProvider, e as duas
      // telas fazem BlocBuilder<XCubit, ...> por dentro. Reproduzia "Could
      // not find the correct Provider<XCubit>" ao clicar em "continuar" na
      // tela informativa.
      await tester.pumpWidget(const AppAplicador());
      await tester.pump(const Duration(milliseconds: 600));

      final context = _routerContext(tester);
      for (final rota in ['/aplicacao/geo', '/aplicacao/registrar']) {
        GoRouter.of(context).go(rota);
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull, reason: 'rota $rota');
      }
    },
  );

  testWidgets(
    'toPonto (pós-login) reseta a pilha — sem botão de voltar em /ponto',
    (tester) async {
      // GEOPRAG-125: toPonto() usava pushReplacement, que só troca o topo da
      // pilha — a landing screen ('/') ficava embaixo de '/ponto' e o
      // GoRouter/AppBar mostravam um botão de voltar indevido. Reproduz o
      // mesmo encadeamento da tela de login (push '/login' a partir da
      // landing, depois vai para '/ponto') e confirma que a pilha fica com
      // uma única rota.
      await tester.pumpWidget(const AppAplicador());
      await tester.pump(const Duration(milliseconds: 600));

      final router = GoRouter.of(_routerContext(tester));
      router.push('/login');
      await tester.pump(const Duration(milliseconds: 300));

      router.go('/ponto');
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(Navigator.canPop(_routerContext(tester)), isFalse);
    },
  );

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

      final context = _routerContext(tester);
      GoRouter.of(context).go('/recebimento/confirmar');
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    },
  );
}
