import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geoprag_modules/geoprag_modules.dart';
import 'package:geoprag_modules/aplicador_app/bootstrap.dart';
import 'package:geoprag_modules/aplicador_app/tenant/tenant.dart';
import 'package:go_router/go_router.dart';

import 'navigation/aplicador_go_router_navigator.dart';
import 'navigation/go_router_refresh_stream.dart';

void main() {
  runApp(const AppAplicador());
}

const AplicadorBootstrap _bootstrap = AplicadorBootstrap();

// TODO(GEOPRAG-24): tenant_id real vem do login (Fase 4/contrato de
// endpoints); mockado aqui até o contrato ser fechado com o backend.
final TenantCubit _tenantCubit = _bootstrap.buildTenantCubit()
  ..load('gaspar-sc');

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
  refreshListenable: GoRouterRefreshStream(_tenantCubit.stream),
  // TODO(GEOPRAG-24): guard de auth real vem da Fase 3/4 (AuthBloc); por ora
  // considera sempre autenticado. Guard de tenant abaixo já é real (Fase 2).
  redirect: (context, state) {
    if (_publicPaths.contains(state.matchedLocation)) return null;
    if (_tenantCubit.state is! TenantReady) return '/tenant/carregando';
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
      builder: (context, state) => const VisualizacaoDoPontoScreen(),
    ),
    GoRoute(
      path: '/ponto/marcar',
      builder: (context, state) => BlocProvider(
        create: (_) => _bootstrap.buildMarcacaoDoPontoCubit(),
        child: const MarcacaoDoPontoScreen(),
      ),
    ),
    GoRoute(
      path: '/aplicacao/info',
      builder: (context, state) => const TelaInformativaScreen(),
    ),
    GoRoute(
      path: '/aplicacao/geo',
      builder: (context, state) => const GeolocalizacaoScreen(),
    ),
    GoRoute(
      path: '/aplicacao/registrar',
      builder: (context, state) => const TelaDeAplicacaoScreen(),
    ),
    GoRoute(
      path: '/inventario',
      builder: (context, state) => const ListaDeInsumosScreen(),
    ),
    GoRoute(
      path: '/recebimentos',
      builder: (context, state) => const RecebimentosScreen(),
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
      builder: (context, state) => const DashboardDeFocosScreen(),
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

class AppAplicador extends StatelessWidget {
  const AppAplicador({super.key});

  @override
  Widget build(BuildContext context) {
    // TenantCubit é provido na raiz (exceção deliberada à regra de
    // "BlocProvider escopado por rota" da Fase 3): ele guia o `redirect` do
    // GoRouter antes de qualquer tela existir, então precisa estar acima do
    // router. Os demais Blocs (auth, etc.) ficam escopados por rota, dentro
    // de cada `GoRoute.builder` acima.
    return BlocProvider.value(
      value: _tenantCubit,
      child: MaterialApp.router(
        title: 'GeoPrag - Aplicador',
        theme: GeopragTheme.light(),
        routerConfig: _router,
        builder: (context, child) => AplicadorNavigatorScope(
          navigator: AplicadorGoRouterNavigator(_router),
          child: child!,
        ),
      ),
    );
  }
}
