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
  void toPontoMarcar() => _router.push('/ponto/marcar');

  @override
  void toAplicacaoInfo() => _router.push('/aplicacao/info');
  @override
  void toAplicacaoGeo() => _router.pushReplacement('/aplicacao/geo');
  @override
  void toAplicacaoRegistrar() =>
      _router.pushReplacement('/aplicacao/registrar');

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
  @override
  void toDenunciaNova() => _router.pushReplacement('/denuncias/nova');

  @override
  void back() => _router.pop();
}
