import 'package:geoprag_modules/geoprag_modules.dart';
import 'package:go_router/go_router.dart';

/// Implementação de [AplicadorNavigator] usando `go_router`. Reproduz a
/// semântica (push vs. replace vs. limpar pilha) das chamadas
/// `Navigator.push*`/`pop` que existiam hardcoded nas telas antes da
/// extração para a interface de navegação (GEOPRAG-24 Fase 1).
class AplicadorGoRouterNavigator implements AplicadorNavigator {
  AplicadorGoRouterNavigator(this._router);

  final GoRouter _router;

  @override
  void toLogin() => _router.push('/login');
  @override
  void toEsqueciSenha() => _router.push('/senha/esqueci');
  @override
  void toVerificarCodigo() => _router.push('/senha/codigo');
  @override
  void toRecriarSenha() => _router.pushReplacement('/senha/recriar');
  @override
  void toLoginResetStack() => _router.go('/login');

  @override
  void toPonto() => _router.go('/ponto');
  @override
  void toPontoDetalhe(String id) => _router.push(
    Uri(path: '/ponto/detalhe', queryParameters: {'id': id}).toString(),
  );

  @override
  void toAplicacaoInfo(String pontoId) => _router.push(
    Uri(path: '/aplicacao/info', queryParameters: {'id': pontoId}).toString(),
  );
  // GEOPRAG-152: `push`, não `pushReplacement` — são etapas de um fluxo
  // (info → geo → registrar), não destinos de topo. Com `pushReplacement` a
  // pilha nunca crescia, então o voltar do Android não tinha o que popar e
  // fechava o app em vez de cancelar a etapa.
  @override
  void toAplicacaoGeo(String pontoId) => _router.push(
    Uri(path: '/aplicacao/geo', queryParameters: {'id': pontoId}).toString(),
  );
  @override
  void toAplicacaoRegistrar(String pontoId) => _router.push(
    Uri(
      path: '/aplicacao/registrar',
      queryParameters: {'id': pontoId},
    ).toString(),
  );

  @override
  void toInventario() => _router.pushReplacement('/inventario');
  @override
  void toRecebimentos() => _router.push('/recebimentos');
  @override
  void toRecebimentoConfirmar() => _router.push('/recebimento/confirmar');

  @override
  void toDenuncias() => _router.pushReplacement('/denuncias');
  @override
  void toDenunciaEducativa() => _router.push('/denuncias/info');
  // GEOPRAG-152: idem — é o passo de preenchimento de uma nova denúncia,
  // não um destino de topo.
  @override
  void toDenunciaNova() => _router.push('/denuncias/nova');

  @override
  void back() => _router.pop();
}
