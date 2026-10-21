import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geoprag_modules/geoprag_modules.dart';
import 'package:geoprag_modules/aplicador_app/bootstrap.dart';
import 'package:geoprag_modules/aplicador_app/tenant/tenant.dart';
import 'package:go_router/go_router.dart';

import 'navigation/aplicador_go_router_navigator.dart';
import 'navigation/go_router_refresh_stream.dart';

/// A URL da API entra na compilação: `--dart-define=API_BASE_URL=http://10.0.2.2:8080`
/// no emulador Android (GEOPRAG-187).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Refresh token recusado ou ausente: os tokens já foram apagados, só falta
  // voltar ao login.
  _bootstrap.configurarApi(aoPerderSessao: _sessaoCubit.sessaoPerdida);
  // Reabre a sessão guardada no aparelho, sem rede, antes de o app aparecer.
  await _sessaoCubit.restaurar();
  runApp(const AppAplicador());
}

const AplicadorBootstrap _bootstrap = AplicadorBootstrap();

final TenantCubit _tenantCubit = _bootstrap.buildTenantCubit();

// Sessão do aplicador logado (GEOPRAG-187) — provida na raiz pelo mesmo
// motivo do _tenantCubit: o `redirect` do GoRouter precisa dela antes de
// qualquer tela existir. O tenant vem dela, nunca de valor fixo.
final AplicadorSessaoCubit _sessaoCubit = _bootstrap
    .buildAplicadorSessaoCubit();

/// Cubit de sessão do app, para os testes autenticarem sem passar pela API.
@visibleForTesting
AplicadorSessaoCubit get sessaoDoApp => _sessaoCubit;

/// Carrega a configuração do tenant do usuário logado.
void _carregarTenantDaSessao(AplicadorSessaoState sessao) {
  if (sessao is AplicadorSessaoAutenticada) {
    _tenantCubit.load(sessao.usuario.tenantId);
  }
}

/// `id` do aplicador logado — só chamado a partir de rotas protegidas, onde o
/// `redirect` abaixo já garante [AplicadorSessaoAutenticada].
String _aplicadorLogadoId() {
  final sessao = _sessaoCubit.state;
  if (sessao is AplicadorSessaoAutenticada) return sessao.usuario.id;
  throw StateError('Rota autenticada acessada sem sessão ativa.');
}

const _publicPaths = {
  '/',
  '/login',
  '/senha/esqueci',
  '/senha/codigo',
  '/senha/recriar',
  '/tenant/carregando',
};

final GoRouter _router = GoRouter(
  initialLocation: '/',
  refreshListenable: Listenable.merge([
    GoRouterRefreshStream(_tenantCubit.stream),
    GoRouterRefreshStream(_sessaoCubit.stream),
  ]),
  redirect: (context, state) {
    final local = state.matchedLocation;
    final autenticado = _sessaoCubit.state is AplicadorSessaoAutenticada;
    final tenantPronto = _tenantCubit.state is TenantReady;
    // Sessão reaberta (ou recém-iniciada): quem já está logado não volta à
    // landing nem ao login, e sai da tela de carregamento quando o tenant fica
    // pronto.
    if (autenticado &&
        (local == '/' ||
            local == '/login' ||
            (local == '/tenant/carregando' && tenantPronto))) {
      return '/ponto';
    }
    if (_publicPaths.contains(local)) return null;
    if (!autenticado) return '/login';
    if (!tenantPronto) return '/tenant/carregando';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
    GoRoute(
      path: '/login',
      builder: (context, state) => BlocProvider(
        create: (_) => _bootstrap.buildLoginCubit(),
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/senha/esqueci',
      builder: (context, state) => BlocProvider(
        create: (_) => _bootstrap.buildEsqueciSenhaCubit(),
        child: const EsqueciSenhaScreen(),
      ),
    ),
    GoRoute(
      path: '/senha/codigo',
      builder: (context, state) => BlocProvider(
        create: (_) => _bootstrap.buildVerificarCodigoCubit(),
        child: const VerificarCodigoScreen(),
      ),
    ),
    GoRoute(
      path: '/senha/recriar',
      builder: (context, state) => BlocProvider(
        create: (_) => _bootstrap.buildRecriarSenhaCubit(),
        child: const RecriarSenhaScreen(),
      ),
    ),
    GoRoute(
      path: '/tenant/carregando',
      builder: (context, state) => const TenantLoadingScreen(),
    ),
    GoRoute(
      path: '/ponto',
      builder: (context, state) => BlocProvider(
        create: (_) => _bootstrap.buildMeusPontosCubit(_aplicadorLogadoId()),
        child: const MeusPontosScreen(),
      ),
    ),
    GoRoute(
      path: '/ponto/detalhe',
      builder: (context, state) {
        final pontoId = state.uri.queryParameters['id']!;
        return BlocProvider(
          create: (_) => _bootstrap.buildDetalheDoPontoDesignadoCubit(pontoId),
          child: const DetalheDoPontoDesignadoScreen(),
        );
      },
    ),
    GoRoute(
      path: '/aplicacao/info',
      builder: (context, state) =>
          TelaInformativaScreen(pontoId: state.uri.queryParameters['id']!),
    ),
    GoRoute(
      path: '/aplicacao/geo',
      builder: (context, state) {
        final pontoId = state.uri.queryParameters['id']!;
        return BlocProvider(
          create: (_) => _bootstrap.buildGeolocalizacaoCubit(pontoId),
          child: const GeolocalizacaoScreen(),
        );
      },
    ),
    GoRoute(
      path: '/aplicacao/registrar',
      builder: (context, state) {
        final pontoId = state.uri.queryParameters['id']!;
        return BlocProvider(
          create: (_) => _bootstrap.buildTelaDeAplicacaoCubit(pontoId),
          child: const TelaDeAplicacaoScreen(),
        );
      },
    ),
    GoRoute(
      path: '/inventario',
      builder: (context, state) => BlocProvider(
        create: (_) => _bootstrap.buildInventarioCubit(),
        child: const ListaDeInsumosScreen(),
      ),
    ),
    GoRoute(
      path: '/recebimentos',
      builder: (context, state) => BlocProvider(
        create: (_) => _bootstrap.buildRecebimentosCubit(),
        child: const RecebimentosScreen(),
      ),
    ),
    GoRoute(
      path: '/recebimento/confirmar',
      builder: (context, state) => BlocProvider(
        create: (_) => _bootstrap.buildRecebimentoConfirmacaoCubit(),
        child: const ReceberProdutoScreen(),
      ),
    ),
    GoRoute(
      path: '/denuncias',
      builder: (context, state) => BlocProvider(
        create: (_) => _bootstrap.buildDenunciasDeFocoCubit(),
        child: const DashboardDeFocosScreen(),
      ),
    ),
    GoRoute(
      path: '/denuncias/info',
      builder: (context, state) => const TelaEducativaScreen(),
    ),
    GoRoute(
      path: '/denuncias/nova',
      builder: (context, state) => BlocProvider(
        create: (_) => _bootstrap.buildCriarDenunciaDeFocoCubit(),
        child: const CadastroDoFocoScreen(),
      ),
    ),
  ],
);

class AppAplicador extends StatefulWidget {
  const AppAplicador({super.key});

  @override
  State<AppAplicador> createState() => _AppAplicadorState();
}

class _AppAplicadorState extends State<AppAplicador> {
  @override
  void initState() {
    super.initState();
    // Sessão reaberta ao iniciar o app: o tenant dela precisa carregar mesmo
    // sem nenhuma mudança de estado a ouvir.
    _carregarTenantDaSessao(_sessaoCubit.state);
  }

  @override
  Widget build(BuildContext context) {
    // TenantCubit e AplicadorSessaoCubit são providos na raiz (exceção
    // deliberada à regra de "BlocProvider escopado por rota" da Fase 3): ambos
    // guiam o `redirect` do GoRouter antes de qualquer tela existir, então
    // precisam estar acima do router. Os demais Blocs (auth, etc.) ficam
    // escopados por rota, dentro de cada `GoRoute.builder` acima.
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _tenantCubit),
        BlocProvider.value(value: _sessaoCubit),
      ],
      // Login feito agora: carrega o tenant que o servidor devolveu.
      child: BlocListener<AplicadorSessaoCubit, AplicadorSessaoState>(
        listener: (_, sessao) => _carregarTenantDaSessao(sessao),
        child: MaterialApp.router(
          title: 'GeoPrag - Aplicador',
          theme: GeopragTheme.light(),
          routerConfig: _router,
          builder: (context, child) => AplicadorNavigatorScope(
            navigator: AplicadorGoRouterNavigator(_router),
            child: child!,
          ),
        ),
      ),
    );
  }
}
