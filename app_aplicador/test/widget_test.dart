import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoprag_modules/aplicador_app/nucleo_offline.dart';
import 'package:geoprag_modules/aplicador_app/sincronizacao/core/monitor_de_conexao.dart';
import 'package:geoprag_modules/geoprag_modules.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common/utils/utils.dart' as sqflite_utils;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

/// Quantidade de rotas empilhadas no momento — cresce a cada `push`, fica
/// igual a cada `pushReplacement` (GEOPRAG-152).
int _pilha(WidgetTester tester) => GoRouter.of(
  _routerContext(tester),
).routerDelegate.currentConfiguration.matches.length;

const _aplicadorDeTeste = Usuario(
  id: 'aplicador-teste',
  nome: 'Aplicador de Teste',
  tenantId: 'gaspar-sc',
);

/// Entra como aplicador sem passar pela API (GEOPRAG-187): as rotas pós-login
/// só abrem com sessão. O app carrega o tenant dessa sessão sozinho.
void _autenticar() => sessaoDoApp.iniciarSessao(_aplicadorDeTeste);

/// Armazenamento seguro em memória (o real usa plugin nativo).
class _ArmazenamentoEmMemoria implements ArmazenamentoSeguro {
  final Map<String, String> _dados = {};

  @override
  Future<String?> ler(String chave) async => _dados[chave];

  @override
  Future<void> gravar(String chave, String valor) async =>
      _dados[chave] = valor;

  @override
  Future<void> apagar(String chave) async => _dados.remove(chave);
}

/// Sem aviso de rede: nenhum gatilho de conexão dispara nos testes.
class _SemMonitor implements MonitorDeConexao {
  @override
  Stream<void> get aoConectar => const Stream<void>.empty();
}

void main() {
  setUpAll(() async {
    // Cliente sem rede: estes testes de navegação nunca chamam a API.
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'http://localhost:8080'),
      sessao: SessaoDeTokensEmMemoria(),
    );
    ApiClientProvider.configurar(api);
    // O núcleo offline (banco local) abre em `main`; aqui, em memória.
    sqfliteFfiInit();
    // O aviso de banco travado é um Timer de 10 s: dentro do relógio falso do
    // testWidgets ele ficaria pendente ao fim de cada teste.
    // ignore: deprecated_member_use
    sqflite_utils.lockWarningDuration = null;
    await NucleoOffline.iniciar(
      api: api,
      armazenamento: _ArmazenamentoEmMemoria(),
      monitor: _SemMonitor(),
      fabrica: databaseFactoryFfi,
      caminho: inMemoryDatabasePath,
    );
  });

  // Sem `tearDownAll(NucleoOffline.redefinir)`: o núcleo vive só neste isolate
  // (um por arquivo de teste) e o banco é em memória. As sincronizações que os
  // gatilhos disparam durante os `testWidgets` (ciclo de vida `resumed`) nascem
  // na zona de relógio falso, que morre com o teste: o que ficou em voo nunca
  // completa, e `redefinir` esperaria por isso (fechar o banco) para sempre.

  // `sessaoDoApp` é singleton de main.dart, compartilhado entre os testes:
  // cada teste começa sem sessão.
  setUp(() => sessaoDoApp.sessaoPerdida());

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
    _autenticar();
    await tester.pumpWidget(const AppAplicador());
    await tester.pump(const Duration(milliseconds: 600));

    final context = _routerContext(tester);
    for (final rota in [
      '/ponto',
      '/ponto/detalhe?id=pa1',
      '/inventario',
      '/recebimentos',
      '/denuncias',
    ]) {
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
      _autenticar();
      await tester.pumpWidget(const AppAplicador());
      await tester.pump(const Duration(milliseconds: 600));

      final context = _routerContext(tester);
      for (final rota in [
        '/aplicacao/geo?id=pa1',
        '/aplicacao/registrar?id=pa1',
      ]) {
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
      // uma única rota. Com o guard de sessão (GEOPRAG-187), o login precisa
      // concluir antes de '/ponto': a sessão inicia e então o app navega.
      await tester.pumpWidget(const AppAplicador());
      await tester.pump(const Duration(milliseconds: 600));

      final router = GoRouter.of(_routerContext(tester));
      router.push('/login');
      await tester.pump(const Duration(milliseconds: 300));

      _autenticar();
      await tester.pump(const Duration(milliseconds: 600));
      router.go('/ponto');
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(Navigator.canPop(_routerContext(tester)), isFalse);
    },
  );

  group('guard de sessão (GEOPRAG-187)', () {
    String rotaAtual(WidgetTester tester) => GoRouter.of(
      _routerContext(tester),
    ).routerDelegate.currentConfiguration.uri.path;

    testWidgets('rota protegida sem sessão volta ao login', (tester) async {
      await tester.pumpWidget(const AppAplicador());
      await tester.pump(const Duration(milliseconds: 600));

      GoRouter.of(_routerContext(tester)).go('/ponto');
      await tester.pump(const Duration(milliseconds: 300));

      expect(rotaAtual(tester), '/login');
    });

    testWidgets('sessão reaberta pula a landing e o login', (tester) async {
      _autenticar();
      await tester.pumpWidget(const AppAplicador());
      await tester.pump(const Duration(milliseconds: 600));

      expect(rotaAtual(tester), '/ponto');
      GoRouter.of(_routerContext(tester)).go('/login');
      await tester.pump(const Duration(milliseconds: 300));
      expect(rotaAtual(tester), '/ponto');
    });

    testWidgets('perder a sessão (refresh recusado) volta ao login', (
      tester,
    ) async {
      _autenticar();
      await tester.pumpWidget(const AppAplicador());
      await tester.pump(const Duration(milliseconds: 600));
      expect(rotaAtual(tester), '/ponto');

      sessaoDoApp.sessaoPerdida();
      await tester.pump(const Duration(milliseconds: 300));

      expect(rotaAtual(tester), '/login');
    });
  });

  testWidgets(
    'toAplicacaoGeo/toAplicacaoRegistrar empilham — voltar do Android '
    'cancela a etapa em vez de fechar o app',
    (tester) async {
      // GEOPRAG-152: as duas rotas usavam pushReplacement, uma etapa de
      // fluxo (não um destino de topo) — cada uma delas substituía o frame
      // anterior em vez de empilhar, então uma restauração do Android que
      // reabre o app só na tela atual (processo morto em segundo plano)
      // ficava sem nenhum frame anterior para o voltar popar. Reproduz a
      // cadeia real (`meus_pontos` → `detalhe_do_ponto` → `tela_informativa`
      // → `geolocalizacao`) e confere que cada etapa soma +1 à pilha, nunca
      // fica no mesmo tamanho.
      _autenticar();
      await tester.pumpWidget(const AppAplicador());
      await tester.pump(const Duration(milliseconds: 600));

      final context = _routerContext(tester);
      final router = GoRouter.of(context);
      final navigator = AplicadorNavigatorScope.of(context);

      router.go('/ponto');
      await tester.pump(const Duration(milliseconds: 300));
      final antesDoDetalhe = _pilha(tester);

      navigator.toPontoDetalhe('pa1');
      await tester.pump(const Duration(milliseconds: 300));
      expect(_pilha(tester), antesDoDetalhe + 1);

      navigator.toAplicacaoInfo('pa1');
      await tester.pump(const Duration(milliseconds: 300));
      expect(_pilha(tester), antesDoDetalhe + 2);

      navigator.toAplicacaoGeo('pa1');
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(_pilha(tester), antesDoDetalhe + 3);

      navigator.toAplicacaoRegistrar('pa1');
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(_pilha(tester), antesDoDetalhe + 4);
    },
  );

  testWidgets(
    'toDenunciaNova empilha — voltar do Android cancela em vez de fechar o app',
    (tester) async {
      // GEOPRAG-152: mesma correção para o fluxo de nova denúncia — reproduz
      // a cadeia real (`dashboard_de_focos` → `tela_educativa`).
      _autenticar();
      await tester.pumpWidget(const AppAplicador());
      await tester.pump(const Duration(milliseconds: 600));

      final context = _routerContext(tester);
      final router = GoRouter.of(context);
      final navigator = AplicadorNavigatorScope.of(context);

      router.go('/denuncias');
      await tester.pump(const Duration(milliseconds: 300));
      final antesDaEducativa = _pilha(tester);

      navigator.toDenunciaEducativa();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_pilha(tester), antesDaEducativa + 1);

      navigator.toDenunciaNova();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(_pilha(tester), antesDaEducativa + 2);
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
      _autenticar();
      await tester.pumpWidget(const AppAplicador());
      await tester.pump(const Duration(milliseconds: 600));

      final context = _routerContext(tester);
      GoRouter.of(context).go('/recebimento/confirmar');
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    },
  );
}
