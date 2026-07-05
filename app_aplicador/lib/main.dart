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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
        '/cadastro': (context) => const CadastroDeIdentificacaoScreen(),
        '/aguarde': (context) => const TelaDeAguardeScreen(),
        '/login': (context) => const LoginScreen(),
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
