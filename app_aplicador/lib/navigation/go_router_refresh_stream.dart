import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapta um `Stream` (ex.: `Cubit.stream`) para `Listenable`, permitindo
/// usá-lo como `refreshListenable` do `GoRouter` — assim o `redirect`
/// reavalia automaticamente quando o tenant termina de carregar.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
