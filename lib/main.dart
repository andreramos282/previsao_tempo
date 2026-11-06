import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'data/previsao_repository.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');
  runApp(PrevisaoTempoApp(repository: PrevisaoRepository()));
}

/// Disponibiliza o repositório para as telas.
class RepositorioScope extends InheritedWidget {
  const RepositorioScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final PrevisaoRepository repository;

  static PrevisaoRepository of(BuildContext context) => context
      .getInheritedWidgetOfExactType<RepositorioScope>()!
      .repository;

  @override
  bool updateShouldNotify(RepositorioScope oldWidget) =>
      repository != oldWidget.repository;
}

class PrevisaoTempoApp extends StatelessWidget {
  const PrevisaoTempoApp({super.key, required this.repository});

  final PrevisaoRepository repository;

  @override
  Widget build(BuildContext context) {
    const semente = Color(0xFF1565C0);
    ThemeData tema(Brightness b) => ThemeData(
          colorSchemeSeed: semente,
          brightness: b,
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
          ),
        );

    return RepositorioScope(
      repository: repository,
      child: MaterialApp(
        title: 'Previsão do Tempo',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: tema(Brightness.light),
        darkTheme: tema(Brightness.dark),
        home: const HomeScreen(),
      ),
    );
  }
}
