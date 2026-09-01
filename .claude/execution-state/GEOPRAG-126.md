Estado: EM_EXECUÇÃO

Issue: GEOPRAG-126 — Corrigir erro de provider não inicializado no fluxo de
registro de aplicação química
Repo: app_aplicador
Branch: fix/GEOPRAG-126-claude (nova, a partir de develop)

Causa raiz encontrada: as rotas `/aplicacao/geo` (GeolocalizacaoScreen) e
`/aplicacao/registrar` (TelaDeAplicacaoScreen) em lib/main.dart não envolvem
a tela num BlocProvider — mas cada uma faz
BlocBuilder<GeolocalizacaoCubit,...> / BlocBuilder<AplicacaoAtualCubit,...>
por dentro. Mesma regressão já documentada e corrigida em GEOPRAG-91/94 para
outras rotas (ver comentário em test/widget_test.dart).

`AplicacaoAtualCubit`/`GeolocalizacaoCubit` exigem `aplicadorId` (String) no
construtor. O próprio doc comment de AplicacaoAtualCubit
(geoprag_modules: aplicador_app/applications/presentation/aplicacao_atual_cubit.dart)
documenta que isso é TODO(GEOPRAG-24) — o roteamento real ainda não repassa
o aplicador autenticado. Até lá, o app já usa mock hardcoded em outros
pontos (ex.: TenantCubit carregando 'gaspar-sc' hardcoded em main.dart) —
seguir o mesmo padrão: aplicadorId mockado ('1', existe em mock_aplicacoes.dart)
com o mesmo TODO(GEOPRAG-24).

Fix: envolver as duas rotas em BlocProvider usando
_bootstrap.buildGeolocalizacaoCubit('1') / buildAplicacaoAtualCubit('1').

Próxima ação: aplicar o fix, testar navegação /aplicacao/info → /geo →
/registrar, rodar flutter analyze + testes, autorevisão/code review, commit.
