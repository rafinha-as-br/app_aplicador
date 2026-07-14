import 'package:flutter/material.dart';
import 'package:geoprag_modules/geoprag_modules.dart';

void main() {
  runApp(const AppAplicador());
}

class AppAplicador extends StatelessWidget {
  const AppAplicador({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoPrag - Aplicador',
      theme: GeopragTheme.light(),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/senha/esqueci': (context) => const EsqueciSenhaScreen(),
        '/senha/codigo': (context) => const VerificarCodigoScreen(),
        '/senha/recriar': (context) => const RecriarSenhaScreen(),
        '/ponto': (context) => const VisualizacaoDoPontoScreen(),
        '/ponto/marcar': (context) => const MarcacaoDoPontoScreen(),
        '/aplicacao/info': (context) => const TelaInformativaScreen(),
        '/aplicacao/geo': (context) => const GeolocalizacaoScreen(),
        '/aplicacao/registrar': (context) => const TelaDeAplicacaoScreen(),
        '/inventario': (context) => const ListaDeInsumosScreen(),
        '/denuncias': (context) => const DashboardDeFocosScreen(),
        '/denuncias/info': (context) => const TelaEducativaScreen(),
        '/denuncias/nova': (context) => const CadastroDoFocoScreen(),
      },
    );
  }
}
