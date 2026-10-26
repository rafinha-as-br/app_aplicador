import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// GEOPRAG-180: guarda a configuração de rede do Android. `flutter test` roda
// com a raiz do projeto como diretório de trabalho.
String _ler(String caminho) => File('android/app/src/$caminho').readAsStringSync();

void main() {
  const refConfig = 'android:networkSecurityConfig="@xml/network_security_config_dev"';

  test('manifest principal declara INTERNET e localização', () {
    final main = _ler('main/AndroidManifest.xml');
    expect(main, contains('android.permission.INTERNET'));
    expect(main, contains('android.permission.ACCESS_FINE_LOCATION'));
    expect(main, contains('android.permission.ACCESS_COARSE_LOCATION'));
  });

  test('HTTP puro só é liberado em debug e profile, nunca no release', () {
    expect(_ler('main/AndroidManifest.xml'), isNot(contains('networkSecurityConfig')));
    expect(_ler('debug/AndroidManifest.xml'), contains(refConfig));
    expect(_ler('profile/AndroidManifest.xml'), contains(refConfig));
  });

  test('config de rede libera HTTP somente para localhost', () {
    final xml = _ler('main/res/xml/network_security_config_dev.xml');
    expect(xml, contains('<base-config cleartextTrafficPermitted="false"'));
    expect(RegExp('<domain[ >]').allMatches(xml), hasLength(1));
    expect(xml, contains('>localhost</domain>'));
  });
}
