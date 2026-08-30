import 'package:flutter_test/flutter_test.dart';

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
}
